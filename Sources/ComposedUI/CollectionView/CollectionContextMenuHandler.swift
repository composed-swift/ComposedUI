import UIKit
import Composed

@available(iOS 13.0, *)
public protocol CollectionContextMenuHandler: CollectionSectionProvider {
    func contextMenu(forItemAt index: Int, cell: UICollectionViewCell, suggestedActions: [UIMenuElement]) -> UIMenu?
    func contextMenu(previewForItemAt index: Int, cell: UICollectionViewCell) -> UIContextMenuContentPreviewProvider?
    func contextMenu(previewForHighlightingItemAt index: Int, cell: UICollectionViewCell) -> UITargetedPreview?
    func contextMenu(previewForDismissingItemAt index: Int, cell: UICollectionViewCell) -> UITargetedPreview?
    func contextMenu(willPerformPreviewActionForItemAt index: Int, cell: UICollectionViewCell, animator: UIContextMenuInteractionCommitAnimating)
}

@available(iOS 13.0, *)
public extension CollectionContextMenuHandler {
    func contextMenu(forItemAt index: Int, cell: UICollectionViewCell, suggestedActions: [UIMenuElement]) -> UIMenu? { return nil }
    func contextMenu(previewForItemAt index: Int, cell: UICollectionViewCell) -> UIContextMenuContentPreviewProvider? { return nil }
    func contextMenu(previewForHighlightingItemAt index: Int, cell: UICollectionViewCell) -> UITargetedPreview? { return nil }
    func contextMenu(previewForDismissingItemAt index: Int, cell: UICollectionViewCell) -> UITargetedPreview? { return nil }
    func contextMenu(willPerformPreviewActionForItemAt index: Int, cell: UICollectionViewCell, animator: UIContextMenuInteractionCommitAnimating) { }
}
