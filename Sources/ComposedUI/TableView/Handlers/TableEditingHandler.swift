import UIKit
import Composed

/// Provides edit handling for `UITableView`'s
public protocol TableEditingHandler: TableSectionProvider, EditingHandler {

    /// Return true if the cell should indent while editing
    /// - Parameter index: The element index
    func shouldIndentWhileEditing(at index: Int) -> Bool

    /// Return true if the cell should allow selection while editing
    /// - Parameter index: The element index
    func allowsSelectionDuringEditing(at index: Int) -> Bool

    /// Return the editing style for the cell
    /// - Parameter index: The element index
    func editingStyle(at index: Int) -> UITableViewCell.EditingStyle

    /// Called when the edit has been comitted
    /// - Parameters:
    ///   - index: The element index
    ///   - editingStyle: The cell's editing style
    func commitEditing(at index: Int, editingStyle: UITableViewCell.EditingStyle)

    /// When editing is toggled, this method will be called to notify the section
    /// - Parameters:
    ///   - editing: True if editing is being enabled, false otherwise
    ///   - index: The element index
    ///   - cell: The cell at the specified index
    ///   - animated: Specifies whether the change is being animated
    func didSetEditing(_ editing: Bool, at index: Int, cell: UITableViewCell, animated: Bool)

}

public extension TableEditingHandler {
    func shouldIndentWhileEditing(at index: Int) -> Bool { return true }
    func allowsSelectionDuringEditing(at index: Int) -> Bool { return false }

    func editingStyle(at index: Int) -> UITableViewCell.EditingStyle { return .none }
    func commitEditing(at index: Int, editingStyle: UITableViewCell.EditingStyle) { }

    func didSetEditing(_ editing: Bool) { }
    func didSetEditing(_ editing: Bool, at index: Int, cell: UITableViewCell, animated: Bool) {
        didSetEditing(editing, at: index)
    }
}
