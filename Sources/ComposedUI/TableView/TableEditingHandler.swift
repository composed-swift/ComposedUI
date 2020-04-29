import UIKit
import Composed

public protocol TableEditingHandler: TableSectionProvider, EditingHandler {
    func shouldIndentWhileEditing(at index: Int) -> Bool
    func allowsSelectionDuringEditing(at index: Int) -> Bool

    func editingStyle(at index: Int) -> UITableViewCell.EditingStyle
    func commitEditing(at index: Int, editingStyle: UITableViewCell.EditingStyle)

    func setEditing(_ editing: Bool, at index: Int, cell: UITableViewCell, animated: Bool)
}

public extension TableEditingHandler {
    func shouldIndentWhileEditing(at index: Int) -> Bool { return true }
    func allowsSelectionDuringEditing(at index: Int) -> Bool { return false }

    func editingStyle(at index: Int) -> UITableViewCell.EditingStyle { return .none }
    func commitEditing(at index: Int, editingStyle: UITableViewCell.EditingStyle) { }

    func didSetEditing(_ editing: Bool) { }
    func setEditing(_ editing: Bool, at index: Int, cell: UITableViewCell, animated: Bool) {
        didSetEditing(editing, at: index)
    }
}
