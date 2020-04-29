import UIKit
import Composed

public protocol CollectionEditingHandler: EditingHandler {
    func setEditing(_ editing: Bool, at index: Int, cell: UICollectionViewCell, animated: Bool)
}

public extension CollectionEditingHandler {
    func didSetEditing(_ editing: Bool) { }
    func setEditing(_ editing: Bool, at index: Int, cell: UICollectionViewCell, animated: Bool) {
        didSetEditing(editing, at: index)
    }
}
