struct genericErrorPage: UIManager{
    var errorString: String?
    var title: String = "Error"
    var buttons: [UIButton] = [.createGroup, .backToPlaza, .backToVoteadmin]
    static var template: String = "errorpage"
    
    init(error: Error){
        self.errorString = error.asString()
    }
}
