import Vapor
import Fluent

struct GroupsCommand: Command{
    let groupsManager: GroupsManager
    weak var app: Application?
    
    struct Signature: CommandSignature {
        @Argument(name: "value")
        var value: String
        
        @Flag(name: "info", short: "i")
        var info: Bool
        
        @Flag(name: "delete", short: "d")
        var delete: Bool
    }
    
    var help: String {
        """
        Manage groups:
        list - shows a list of groups
        [join phrase] - The joinphrase to use
        -i - Get info for the for this join phrase
        -d - Delete the group linked to this join phrase
        """
    }
    
    func run(using context: CommandContext, signature: Signature) throws {
		guard let app = app else {return}
		let trimVal = signature.value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimVal.isEmpty || trimVal == "list"{
            Task{
                context.console.print("All groups:")
				let allGroups = await groupsManager.listAllGroups(db: app.db)
                context.console.print(allGroups)

            }
            return
        }
        
		guard trimVal.count == Config.joinPhraseLength else {
            throw "Invalid joinphrase"
        }
        let joinPhrase = trimVal
        if signature.info && signature.delete{
            throw "Only one flag at a time"
        }
        
		if signature.delete{
            Task{
				let filter = DBGroup.query(on: app.db).filter(\.$joinphrase == joinPhrase)
				guard try await filter.count() != 0 else {
					context.console.error("Not found", newLine: true)
					return
				}
				try await filter.delete()
				context.console.print("Successfully deleted: \(joinPhrase)")
            }
        } else {
            
            Task{
				guard
					let group = try await DBGroup
						.query(on: app.db)
						.filter(\.$joinphrase == joinPhrase)
						.first(),
					let lastAccess = group.lastAccess?.description
                else {
                    throw "Group not found"
                }
                
				let currIn = try await group.$constituents.query(on: app.db).filter(\.$isCurrentlyIn == true).count()
                let result = "Group:\"\(group.name)\"\nWith \(currIn) constituents in session\nGroup was last accessed at: " + lastAccess
                context.console.print(result)
                
            }
            return
        }
    }
}

