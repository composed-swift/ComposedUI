import UIKit
import Composed

public protocol UISection {
    associatedtype S: Section
    var section: S { get }
}

public struct UISectionView<S, View> where S: Section, View: UIView {
    let dequeueMethod: DequeueMethod<View>
    let kind: CollectionElementKind
    let reuseIdentifier: String?
    let viewHandler: (View, Int, S) -> Void

    public init(dequeueMethod: DequeueMethod<View>, kind: CollectionElementKind = .automatic, reuseIdentifier: String? = nil, viewHandler: @escaping (View, Int, S) -> Void) {
        self.dequeueMethod = dequeueMethod
        self.viewHandler = viewHandler
        self.kind = kind
        self.reuseIdentifier = reuseIdentifier
    }
}
