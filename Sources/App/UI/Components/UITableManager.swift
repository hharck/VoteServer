protocol UITableManager: UIManager{
    associatedtype rowType: Codable
    var rows: [rowType] {get}
    var tableHeaders: [String] {get}
}
