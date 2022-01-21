protocol UITableManager: UIManager{
    associatedtype rowType: Codable
    var rows: [rowType] {get}
    var tableHeaders: [String] {get}
	var tableClass: String {get}
}

extension UITableManager{
	var tableClass: String {""} 
}
