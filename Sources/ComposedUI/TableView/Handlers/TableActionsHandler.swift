import UIKit
import Composed

/// Provides cell action handling for `UITableView`'s
public protocol TableActionsHandler: TableSectionProvider {

    /// Return leading actions for the cell at the specified index
    /// - Parameter index: The element index
    func leadingSwipeActions(at index: Int) -> UISwipeActionsConfiguration?

    /// Return trailing actions for the cell at the specified index
    /// - Parameter index: The element index
    func trailingSwipeActions(at index: Int) -> UISwipeActionsConfiguration?

}

public extension TableActionsHandler {
    func leadingSwipeActions(at index: Int) -> UISwipeActionsConfiguration? { return nil }
    func trailingSwipeActions(at index: Int) -> UISwipeActionsConfiguration? { return nil }
}
