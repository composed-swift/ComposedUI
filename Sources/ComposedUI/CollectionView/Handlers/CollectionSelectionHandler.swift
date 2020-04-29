import UIKit
import Composed

/// Provides selection handling for `UICollectionView`'s
public protocol CollectionSelectionHandler: SelectionHandler, CollectionSectionProvider {

    /// When a selection occurs, this method will be called to notify the section
    /// - Parameters:
    ///   - index: The element index
    ///   - cell: The cell that was selected
    func didSelect(at index: Int, cell: UICollectionViewCell)

    /// When a deselection occurs, this method will be called to notify the section
    /// - Parameters:
    ///   - index: The element index
    ///   - cell: The cell that was deselected
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
