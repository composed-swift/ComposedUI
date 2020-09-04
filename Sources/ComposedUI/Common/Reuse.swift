import UIKit

public protocol ReusableCell: ReuseableView {
    static var reuseIdentifier: String { get }
}

public extension ReusableCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

public protocol ReuseableView: class {
    static var reuseIdentifier: String { get }
    static var kind: String { get }
    var reuseIdentifier: String? { get }
}

public extension ReuseableView {
    static var kind: String {
        return String(describing: self)
    }
}

extension UITableViewCell: ReusableCell { }
extension UICollectionReusableView: ReusableCell { }
extension UITableViewHeaderFooterView: ReusableCell { }
extension UICollectionReusableView: ReuseableView { }

public extension UICollectionView {

    // Editing

    var isEditing: Bool {
        get { owningViewController?.isEditing ?? false }
        set { setEditing(newValue, animated: false) }
    }

    func setEditing(_ editing: Bool, animated: Bool) {
        owningViewController?.setEditing(editing, animated: animated)
    }

}

private extension UIView {

    @objc var owningViewController: UIViewController? {
        var responder: UIResponder? = self

        while !(responder is UIViewController) && superview != nil {
            if let next = responder?.next {
                responder = next
            }
        }

        return responder as? UIViewController
    }

}
