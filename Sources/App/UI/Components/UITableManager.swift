protocol UITableManager: UIManager {
    associatedtype RowType: Codable
    var rows: [RowType] { get }
    var tableHeaders: [String] { get }

	var hideIfEmpty: Bool { get }

}

extension UITableManager {
	var hideIfEmpty: Bool { false }
}
