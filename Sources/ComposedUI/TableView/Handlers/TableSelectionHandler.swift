import UIKit
import Composed

/// Provides selection handling for `UITableView`'s
public protocol TableSelectionHandler: SelectionHandler {

    /// When a selection occurs, this method will be called to notify the section
    /// - Parameters:
    ///   - index: The element index
    ///   - cell: The cell that was selected
    func didSelect(at index: Int, cell: UITableViewCell)

    /// When a deselection occurs, this method will be called to notify the section
    /// - Parameters:
    ///   - index: The element index
    ///   - cell: The cell that was deselected
    func didDeselect(at index: Int, cell: UITableViewCell)

}

public extension TableSelectionHandler {
    func didSelect(at index: Int, cell: UITableViewCell) {
        didSelect(at: index)
    }

    func didDeselect(at index: Int, cell: UITableViewCell) {
        didSelect(at: index)
    }
}
