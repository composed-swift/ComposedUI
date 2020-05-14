import UIKit
import CoreData
import Composed

public protocol CollectionDragHandler: CollectionSectionProvider {

    func dragSessionWillBegin(_ session: UIDragSession)
    func dragSessionDidEnd(_ session: UIDragSession)

    func dragSession(_ session: UIDragSession, dragItemsForBeginning index: Int) -> [UIDragItem]
    func dragSession(_ session: UIDragSession, dragItemsForAdding index: Int) -> [UIDragItem]

    /// Return custom information about how to display the item at the specified location during the drag.
    /// - Parameter
    ///   - index: The index of the element being dragged
    ///   - cell: The cell associated with this drag
    func dragSession(previewParametersForElementAt index: Int, cell: UICollectionViewCell) -> UIDragPreviewParameters?

}

public extension CollectionDragHandler {

    func dragSessionWillBegin(_ session: UIDragSession) { }
    func dragSessionDidEnd(_ session: UIDragSession) { }
    func dragSession(_ session: UIDragSession, dragItemsForAdding index: Int) -> [UIDragItem] {
        return dragSession(session, dragItemsForBeginning: index)
    }
    
}
