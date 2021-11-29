import Vapor
import AltVoteKit

func ResultRoutes(_ app: Application, groupsManager: GroupsManager) throws {
	app.get("results"){ req in
		req.redirect(to: .voteadmin)
	}

	app.get("results", ":voteID"){ req async -> Response in
		guard let voteIDStr = req.parameters.get("voteID") else {
			return req.redirect(to: .voteadmin)
		}


		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(sessionID),
			let vote = await group.voteForID(voteIDStr)
		else {
			return req.redirect(to: .create)
		}
		return await getResults(req: req, group: group, vote: vote, excluding: [])
	}


	app.post("results", ":voteID"){ req async -> Response in
		guard let voteIDStr = req.parameters.get("voteID") else {
			return req.redirect(to: .voteadmin)
		}

		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(sessionID),
			let vote = await  group.voteForID(voteIDStr),
			let options = try? req.content.decode(SelectedOptions.self)
		else {
			return req.redirect(to: .results(voteIDStr))
		}
		let enabled = options.enabledUUIDs()

		//Finds all options that were not selected by the user
		let toExclude = await vote.options.filter { option in
			!enabled.contains(option.id)
		}

		return await getResults(req: req, group: group, vote: vote, excluding: Set(toExclude))
	}

	struct SelectedOptions: Codable{
		var options: [String: String]

		func enabledUUIDs()->[UUID]{
			options.compactMap { (key, value) in
				if value == "on"{
					return UUID(key)
				} else {
					return nil
				}
			}
		}
	}


	func getResults(req: Request, group: Group, vote: AltVote, excluding: Set<VoteOption>) async -> Response{

		// Makes sure the vote is closed
		await group.setStatusFor(vote, to: .closed)

		let force = req.url.query?.split(separator: "&").contains("force=1") ?? false

		do{
			let winner = try await vote.findWinner(force: force, excluding: excluding)
			if winner == []{
				throw "An issue occured during counting"
			}
			
			let enabledOptions = Set(await vote.options).subtracting(excluding)
			let controller = ShowWinnerUI(title: "Your '\(await vote.name)' vote results", winners: winner, numberOfVotes: await vote.votes.count, enabledOptions: enabledOptions, disabledOptions: excluding)
			return try await controller.encodeResponse(for: req)
		} catch {
			guard
				let er = error as? [VoteValidationResult],
				let encodedRender: Response = try? await ValidationErrorUI(title: await vote.name, validationResults: er, voteID: vote.id).encodeResponse(for: req)
			else {
				let er = error.asString()
				return try! await er.encodeResponse(for: req)
			}
			return encodedRender
		}
	}




	//MARK: Export CSV
	app.get("results", ":voteID", "downloadcsv"){ req async throws -> Response in
		guard let voteIDStr = req.parameters.get("voteID") else {
			return req.redirect(to: .voteadmin)
		}


		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(sessionID),
			let vote = await group.voteForID(voteIDStr)
		else {
			return req.redirect(to: .results(voteIDStr))
		}
		
		let csv = await vote.toCSV()
		var headers = HTTPHeaders()
		headers.add(name: .contentDisposition, value: "attachment; filename=\"votes.csv\"")
		return try await csv.encodeResponse(status: .ok, headers: headers, for: req)
		
	}
	
	app.get("results", ":voteID", "downloadconst"){ req async throws -> Response in
		guard let voteIDStr = req.parameters.get("voteID") else {
			return req.redirect(to: .voteadmin)
		}
		
		guard
			let sessionID = req.session.authenticated(AdminSession.self),
			let group = await groupsManager.groupForSession(sessionID),
			let vote = await group.voteForID(voteIDStr)
		else {
			return req.redirect(to: .results(voteIDStr))
		}


		let csv = Vote.constituentsToCSV(await vote.constituents)


		var headers = HTTPHeaders()
		headers.add(name: .contentDisposition, value: "attachment; filename=\"constituents.csv\"")
		return try await csv.encodeResponse(status: .ok, headers: headers, for: req)

	}
}
