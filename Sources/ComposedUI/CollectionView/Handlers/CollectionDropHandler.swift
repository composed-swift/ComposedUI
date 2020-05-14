import UIKit
import CoreData
import Composed

/// Provides drag and drop handling for `UICollectionView`'s
public protocol CollectionDropHandler: CollectionSectionProvider {

    func dropSessionWillBegin(_ session: UIDropSession)
    func dropSessionDidEnd(_ session: UIDropSession)

    /// Called when the position of the dragged data over the view has changed. While the user is dragging content, the view calls this method repeatedly to determine how you would handle the drop if it occurred at the specified location. The view provides visual feedback to the user based on your proposal.
    /// - Parameters:
    ///   - session: The drop session object containing information about the type of data being dragged.
    ///   - destinationIndex: The index at which the content would be dropped.
    func dropSessionDidUpdate(_ session: UIDropSession, destinationIndex: Int?) -> UICollectionViewDropProposal

    /// Return custom information about how to display the item at the specified location during the drop.
    /// - Parameter
    ///   - index: The index where the element should be inserted
    ///   - cell: The cell associated with this drop
    func dropSesion(previewParametersForElementAt index: Int, cell: UICollectionViewCell) -> UIDragPreviewParameters?

}

public extension CollectionDropHandler {
    func dropSessionWillBegin(_ session: UIDropSession) { }
    func dropSessionDidEnd(_ session: UIDropSession) { }
    func dropSessionDidUpdate(_ session: UIDropSession, destinationIndex: Int?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .copy)
    }
    func dropSesion(previewParametersForElementAt index: Int, cell: UICollectionViewCell) -> UIDragPreviewParameters? { return nil }
}
