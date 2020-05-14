import UIKit

public protocol CollectionDragHandler: CollectionSectionProvider {

    func dragSession(_ session: UIDragSession, dragItemForBeginning index: Int) -> [UIDragItem]
    func dragSession(_ session: UIDragSession, dragItemForAdding index: Int) -> [UIDragItem]

}

public extension CollectionDragHandler {

    func dragSession(_ session: UIDragSession, dragItemForAdding index: Int) -> [UIDragItem] {
        return dragSession(session, dragItemForBeginning: index)
    }
    
}
