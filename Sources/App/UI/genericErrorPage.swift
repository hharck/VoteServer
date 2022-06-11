struct genericErrorPage: UIManager{
    var errorString: String? = nil
	var generalInformation: HeaderInformation! = nil
    var title: String = "Error"
	var buttons: [UIButton] = []
    static var template: String = "errorpage"
    
    init(error: Error){
        self.errorString = error.asString()
    }
}
