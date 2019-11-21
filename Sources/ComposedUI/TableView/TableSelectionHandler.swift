import UIKit
import Composed

public protocol TableSelectionHandler: SelectionHandler {
    func didSelect(at index: Int, cell: UITableViewCell)
    func didDeselect(at index: Int, cell: UITableViewCell)
}

public extension CollectionSelectionHandler {
    func didSelect(at index: Int, cell: UITableViewCell) {
        didSelect(at: index)
    }

    func didDeselect(at index: Int, cell: UITableViewCell) {
        didSelect(at: index)
    }
}
