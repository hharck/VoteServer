import Vapor

struct GroupsCommand: Command, Sendable{
    let groupsManager: GroupsManager
    
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
        if signature.value.isEmpty || signature.value == "list"{
            Task{
                let allGroups = await groupsManager.listAllGroups()
                context.console.print(allGroups)

            }
            return
        }
        
        
        guard signature.value.count == joinPhraseLength else {
            throw "Invalid joinphrase"
        }
        
        let joinPhrase = signature.value
        
        if signature.info && signature.delete {
            throw "Only one flag at a time"
        }
        
        if signature.delete{
            Task{
                if await groupsManager.deleteGroup(jf: joinPhrase){
                    context.console.print("Successfully deleted: \(joinPhrase)")
                } else {
                    context.console.error("Unable to delete: \(joinPhrase)")
                }
            }
            
            return
        } else{
            
            Task{
                guard
                    let group = await groupsManager.groupForJoinPhrase(joinPhrase),
                    let lastAccess = await groupsManager.getLastAccess(for: group)
                else {
                    context.console.error("Group not found")
                    return
                }
                
                let result = "Group:\"\(group.name)\"\nWith \(await group.constituentsSessionID.count) constituents in session\nGroup was last accessed at: " + lastAccess
                context.console.print(result)
                
            }
            return
        }
    }
}

