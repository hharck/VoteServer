import Vapor
import AltVoteKit

func ResultRoutes(_ app: Application, voteManager: VoteManager) throws {
	app.get("results"){ req async -> Response in
		guard
			let sessionID = req.session.authenticated(Session.self),
			let vote = await voteManager.voteFor(session: sessionID)
		else {
			return req.redirect(to: "/create/")
		}
		return await getResults(req: req, vote: vote, excluding: [])
	}
	
	
	app.post("results"){ req async -> Response in
		guard
			let sessionID = req.session.authenticated(Session.self),
			let vote = await voteManager.voteFor(session: sessionID),
			let options = try? req.content.decode(SelectedOptions.self)
		else {
			return req.redirect(to: "/results/")
		}
		let enabled = options.enabledUUIDs()
		
		//Finds all options that were not selected by the user
		let toExclude = await vote.options.filter { option in
			!enabled.contains(option.id)
		}
		
		return await getResults(req: req, vote: vote, excluding: Set(toExclude))
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
	
	
	func getResults(req: Request, vote: Vote, excluding: Set<VoteOption>) async -> Response{

		await voteManager.setStatusFor(vote, to: false)
		
		let force = req.url.query?.split(separator: "&").contains("force=1") ?? false
		
		do{
			let winner = try await vote.findWinner(force: force, excluding: excluding)
			if winner == []{
				throw "An issue occured during counting"
			}
			await vote.votes.forEach{
				print($0.rankings)
			}

			let enabledOptions = Set(await vote.options).subtracting(excluding)
			let controller = ShowWinnerUI(title: await vote.name, winners: winner, numberOfVotes: await vote.votes.count, enabledOptions: enabledOptions, disabledOptions: excluding)
			return try await req.view.render("results", controller).encodeResponse(for: req)
		} catch {
			guard
				let er = error as? [VoteValidationResult],
				let encodedRender: Response = try? await req.view.render("validators failed", ValidationErrorView(title: await vote.name, validationResults: er)).encodeResponse(for: req)
			else {
				let er = error.asString()
				return try! await er.encodeResponse(for: req)
			}
			return encodedRender
		}
	}
	
	
	
	
	//MARK: Export CSV
	app.get("results", "downloadcsv"){ req async throws -> Response in
		guard
			let sessionID = req.session.authenticated(Session.self),
			let vote = await voteManager.voteFor(session: sessionID)
		else {
			return req.redirect(to: "/voteadmin/")
		}
		
		let csv = await vote.toCSV()
		var headers = HTTPHeaders()
		headers.add(name: .contentDisposition, value: "attachment; filename=\"votes.csv\"")
		return try await csv.encodeResponse(status: .ok, headers: headers, for: req)
		
	}
	
	app.get("results", "downloadconst"){ req async throws -> Response in
		guard
			let sessionID = req.session.authenticated(Session.self),
			let vote = await voteManager.voteFor(session: sessionID)
		else {
			return req.redirect(to: "/voteadmin")
		}

		let csv = await vote.constituentsToCSV()

		var headers = HTTPHeaders()
		headers.add(name: .contentDisposition, value: "attachment; filename=\"verified_voters.csv\"")
		return try await csv.encodeResponse(status: .ok, headers: headers, for: req)

	}
}
