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
		await voteManager.setStatusFor(vote, to: false)
		
		let force = req.url.query?.split(separator: "&").contains("force=1") ?? false

		do{
			let winner = try await vote.findWinner(force: force)
			if winner == []{
				throw "An issue occured during counting"
			}
			await vote.votes.forEach{
				print($0.rankings)
			}
//			let debug1 = await vote.debugCount()
			let debug2 = await vote.debugCount2()
			let controller = ShowWinnerUI(title: await vote.name, winners: winner, numberOfVotes: await vote.votes.count, debug2: debug2)
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
