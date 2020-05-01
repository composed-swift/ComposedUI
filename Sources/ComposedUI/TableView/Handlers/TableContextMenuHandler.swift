import UIKit
import Composed

/// Provides context menu handling for `UITableView`'s
@available(iOS 13.0, *)
public protocol TableContextMenuHandler: TableSectionProvider {

    /// Return a `UIMenu` representing the actions that should be shown for the specified cell.
    /// - Parameters:
    ///   - index: The index of the element
    ///   - cell: The cell the context menu will be shown for
    ///   - suggestedActions: The suggested actions for this menu
    func contextMenu(forElementAt index: Int, cell: UITableViewCell, suggestedActions: [UIMenuElement]) -> UIMenu?

    /// Return a closure that takes no arguments and returns a `UIViewController` that will be used for the preview.
    /// - Parameters:
    ///   - index: The index of the element
    ///   - cell: Th cell the context menu will be shown for
    func contextMenu(previewForElementAt index: Int, cell: UITableViewCell) -> UIContextMenuContentPreviewProvider?

    /// Called when the interaction begins. Return a `UITargetedPreview` describing the desired highlight preview.
    /// - Parameters:
    ///   - index: The index of the element
    ///   - cell: The cell the context menu will be shown for
    func contextMenu(previewForHighlightingElementAt index: Int, cell: UITableViewCell) -> UITargetedPreview?

    /// Called when the interaction is about to dismiss. Return a `UITargetedPreview` describing the desired dismissal target. The interaction will animate the presented menu to the target. Use this to customize the dismissal animation.
    /// - Parameters:
    ///   - index: The index of the element
    ///   - cell: The cell the context menu was shown for
    func contextMenu(previewForDismissingElementAt index: Int, cell: UITableViewCell) -> UITargetedPreview?

    /// Called when the interaction is about to "commit" in response to the user tapping the preview.
    /// - Parameters:
    ///   - index: The index of the element
    ///   - cell: The cell the context menu is being shown for
    ///   - animator: Commit animator. Add animations to this object to run them alongside the commit transition.
    func contextMenu(willPerformPreviewActionForElementAt index: Int, cell: UITableViewCell, animator: UIContextMenuInteractionCommitAnimating)

}

@available(iOS 13.0, *)
public extension TableContextMenuHandler {
    func contextMenu(forElementAt index: Int, cell: UITableViewCell, suggestedActions: [UIMenuElement]) -> UIMenu? { return nil }
    func contextMenu(previewForElementAt index: Int, cell: UITableViewCell) -> UIContextMenuContentPreviewProvider? { return nil }
    func contextMenu(previewForHighlightingElementAt index: Int, cell: UITableViewCell) -> UITargetedPreview? { return nil }
    func contextMenu(previewForDismissingElementAt index: Int, cell: UITableViewCell) -> UITargetedPreview? { return nil }
    func contextMenu(willPerformPreviewActionForElementAt index: Int, cell: UITableViewCell, animator: UIContextMenuInteractionCommitAnimating) { }
}
