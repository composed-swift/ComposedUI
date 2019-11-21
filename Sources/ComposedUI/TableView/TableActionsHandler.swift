import UIKit
import Composed

public protocol TableActionsHandler: TableSectionProvider {
    func leadingSwipeActions(at index: Int) -> UISwipeActionsConfiguration?
    func trailingSwipeActions(at index: Int) -> UISwipeActionsConfiguration?
}

public extension TableActionsHandler {
    func leadingSwipeActions(at index: Int) -> UISwipeActionsConfiguration? { return nil }
    func trailingSwipeActions(at index: Int) -> UISwipeActionsConfiguration? { return nil }
}
