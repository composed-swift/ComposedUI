import UIKit
import Composed

public protocol TableEditingHandler: TableSectionProvider {
    func allowsEditing(at index: Int) -> Bool
    func shouldIndentWhileEditing(at index: Int) -> Bool
    func allowsSelectionDuringEditing(at index: Int) -> Bool

    func editingStyle(at index: Int) -> UITableViewCell.EditingStyle
    func commitEditing(at index: Int, editingStyle: UITableViewCell.EditingStyle)

    func willBeginEditing(at index: Int)
    func didEndEditing(at index: Int)
}

public extension TableEditingHandler {
    func allowsEditing(at index: Int) -> Bool { return true }
    func shouldIndentWhileEditing(at index: Int) -> Bool { return true }
    func allowsSelectionDuringEditing(at index: Int) -> Bool { return false }

    func editingStyle(at index: Int) -> UITableViewCell.EditingStyle { return .none }
    func commitEditing(at index: Int, editingStyle: UITableViewCell.EditingStyle) { }

    func willBeginEditing(at index: Int) { }
    func didEndEditing(at index: Int) { }
}
