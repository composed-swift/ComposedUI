import UIKit

public protocol CollectionDropHandler: CollectionSectionProvider {
    func dropSessionDidUpdate(_ session: UIDropSession, destinationIndex: Int?) -> UICollectionViewDropProposal
    func dropSesion(previewParametersForItemAt index: Int) -> UIDragPreviewParameters?
}

extension CollectionDropHandler {
    func dropSesion(_ session: UIDropSession, previewParametersForItemAt index: Int) -> UIDragPreviewParameters? { return nil }
}
