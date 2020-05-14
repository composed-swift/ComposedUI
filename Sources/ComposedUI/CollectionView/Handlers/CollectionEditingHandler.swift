import UIKit
import Composed

/// Provides edit handling for `UICollectionView`'s
public protocol CollectionEditingHandler: EditingHandler, CollectionSectionProvider {

    /// When editing is toggled, this method will be called to notify the section
    /// - Parameters:
    ///   - editing: True if editing is being enabled, false otherwise
    ///   - index: The element index
    ///   - cell: The cell at the specified index
    ///   - animated: Specifies whether the change is being animated
    func didSetEditing(_ editing: Bool, at index: Int, cell: UICollectionViewCell, animated: Bool)

}

public extension CollectionEditingHandler {
    func didSetEditing(_ editing: Bool) { }
    func didSetEditing(_ editing: Bool, at index: Int, cell: UICollectionViewCell, animated: Bool) {
        didSetEditing(editing, at: index)
    }
}
