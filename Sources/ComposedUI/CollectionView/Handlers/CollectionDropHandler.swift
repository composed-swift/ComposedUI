import UIKit

/// Provides drag and drop handling for `UICollectionView`'s
public protocol CollectionDropHandler: CollectionSectionProvider {

    /// Called when the position of the dragged data over the view has changed. While the user is dragging content, the view calls this method repeatedly to determine how you would handle the drop if it occurred at the specified location. The view provides visual feedback to the user based on your proposal.
    /// - Parameters:
    ///   - session: The drop session object containing information about the type of data being dragged.
    ///   - destinationIndex: The index at which the content would be dropped.
    func dropSessionDidUpdate(_ session: UIDropSession, destinationIndex: Int?) -> UICollectionViewDropProposal

    /// Return custom information about how to display the item at the specified location during the drop.
    /// - Parameter index: The index where the element should be inserted
    func dropSesion(previewParametersForElementAt index: Int) -> UIDragPreviewParameters?

}

extension CollectionDropHandler {
    func dropSesion(_ session: UIDropSession, previewParametersForItemAt index: Int) -> UIDragPreviewParameters? { return nil }
}
