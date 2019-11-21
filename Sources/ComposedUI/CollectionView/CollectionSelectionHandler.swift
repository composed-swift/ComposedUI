import UIKit
import Composed

public protocol CollectionSelectionHandler: SelectionHandler {
    func didSelect(at index: Int, cell: UICollectionViewCell)
    func didDeselect(at index: Int, cell: UICollectionViewCell)
}

public extension CollectionSelectionHandler {
    func didSelect(at index: Int, cell: UICollectionViewCell) {
        didSelect(at: index)
    }
    
    func didDeselect(at index: Int, cell: UICollectionViewCell) {
        didSelect(at: index)
    }
}
