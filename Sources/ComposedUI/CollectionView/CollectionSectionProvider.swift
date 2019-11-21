import UIKit
import Composed

public protocol CollectionSectionElementsProvider {
    var cell: CollectionCellElement<UICollectionViewCell> { get }
    var header: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var footer: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
}

public extension CollectionSectionElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}

public protocol CollectionSectionProvider: Section {
    func section(with traitCollection: UITraitCollection) -> CollectionSection
}

@available(iOS 13.0, *)
public protocol CollectionSectionContextMenuProvider: Section {
    func contextMenu(forItemAt index: Int, suggestedActions: [UIMenuElement]) -> UIMenu?
    func contextMenu(previewForItemAt index: Int, cell: UICollectionViewCell) -> UIContextMenuContentPreviewProvider?
    func contextMenu(previewForHighlightingItemAt index: Int, cell: UICollectionViewCell) -> UITargetedPreview?
    func contextMenu(previewForDismissingItemAt index: Int, cell: UICollectionViewCell) -> UITargetedPreview?
    func contextMenu(willPerformPreviewActionForItemAt index: Int, animator: UIContextMenuInteractionCommitAnimating)
}

@available(iOS 13.0, *)
public extension CollectionSectionContextMenuProvider {
    func contextMenu(forItemAt index: Int, suggestedActions: [UIMenuElement]) -> UIMenu? { return nil }
    func contextMenu(previewForItemAt index: Int, cell: UICollectionViewCell) -> UIContextMenuContentPreviewProvider? { return nil }
    func contextMenu(previewForHighlightingItemAt index: Int, cell: UICollectionViewCell) -> UITargetedPreview? { return nil }
    func contextMenu(previewForDismissingItemAt index: Int, cell: UICollectionViewCell) -> UITargetedPreview? { return nil }
    func contextMenu(willPerformPreviewActionForItemAt index: Int, animator: UIContextMenuInteractionCommitAnimating) { }
}
