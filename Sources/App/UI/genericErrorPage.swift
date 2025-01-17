struct genericErrorPage: UIManager{
    var errorString: String?
    var title: String = "Error"
    var buttons: [UIButton] = [.createGroup, .backToPlaza, .backToAdmin]
    static let template: String = "errorpage"
    
    init(error: Error){
        self.errorString = error.asString()
    }
}
