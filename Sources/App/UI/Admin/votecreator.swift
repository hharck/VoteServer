struct VoteCreatorUI: UIManager{
    var version: String = App.version
    var title: String
	var errorString: String?
	static let template: String = "createvote"
	
    let validatorsGeneric: [ValidatorData]
    let validatorsCustom: [ValidatorData]
	let nameOfVote: String?
	let options: String?
	
    var buttons: [UIButton] = [.backToAdmin]
    
    init(typeName: String, errorString: String? = nil, validatorsGeneric: [ValidatorData], validatorsCustom: [ValidatorData], _ persistentData: VoteCreationReceivedData? = nil) {
        self.title = "Create \(typeName)"
        self.errorString = errorString
        self.nameOfVote = persistentData?.nameOfVote
        self.options = persistentData?.options.trimmingCharacters(in: .whitespacesAndNewlines)
		
		// Sets the validator as enabled if they appear in persistentData
		if let enabledValidatorIDs = persistentData?.getAllEnabledIDs(), !enabledValidatorIDs.isEmpty{
            self.validatorsGeneric = validatorsGeneric.map{val in
				var val = val
				val.isEnabled = enabledValidatorIDs.contains(val.id)
				return val
			}
            
            self.validatorsCustom = validatorsCustom.map { val in
                var val = val
                val.isEnabled = enabledValidatorIDs.contains(val.id)
                return val
            }
		} else {
            self.validatorsGeneric = validatorsGeneric
            self.validatorsCustom = validatorsCustom
		}
	}
	
}

