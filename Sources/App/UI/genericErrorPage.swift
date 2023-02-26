struct genericErrorPage: UIManager{
    var version: String = App.version
    var errorString: String?
    var title: String = "Error"
    var buttons: [UIButton] = [.createGroup, .backToPlaza, .backToAdmin]
    static var template: String = "errorpage"
    
    init(error: Error){
        self.errorString = error.asString()
    }
}
