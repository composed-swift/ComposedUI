import UIKit

public protocol TableDropHandler: TableSectionProvider {
    func dropSessionDidUpdate(_ session: UIDropSession, destinationIndex: Int?) -> UITableViewDropProposal
    func dropSesion(previewParametersForItemAt index: Int) -> UIDragPreviewParameters?
}

extension TableDropHandler {
    func dropSesion(_ session: UIDropSession, previewParametersForItemAt index: Int) -> UIDragPreviewParameters? { return nil }
}
