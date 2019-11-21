import UIKit
import Composed

public enum CollectionElementKind {
    case automatic
    case custom(kind: String)

    internal var rawValue: String {
        switch self {
        case .automatic: return "automatic"
        case let .custom(kind): return kind
        }
    }
}

public protocol CollectionElement {
    associatedtype View: UICollectionReusableView
    var dequeueMethod: DequeueMethod<View> { get }
    var configure: (UICollectionReusableView, Int, Section) -> Void { get }
    var reuseIdentifier: String { get }
}

public final class CollectionCellElement<View>: CollectionElement where View: UICollectionViewCell {

    public let dequeueMethod: DequeueMethod<View>
    public let configure: (UICollectionReusableView, Int, Section) -> Void
    public let reuseIdentifier: String

    public init<Section>(section: Section, dequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, configure: @escaping (View, Int, Section) -> Void) where Section: Composed.Section {
        self.reuseIdentifier = reuseIdentifier ?? View.reuseIdentifier
        self.dequeueMethod = dequeueMethod

        self.configure = { view, index, section in
            // swiftlint:disable force_cast
            configure(view as! View, index, section as! Section)
        }
    }

}

public final class CollectionSupplementaryElement<View>: CollectionElement where View: UICollectionReusableView {

    public let dequeueMethod: DequeueMethod<View>
    public let configure: (UICollectionReusableView, Int, Section) -> Void
    public let reuseIdentifier: String
    public let kind: CollectionElementKind

    public init<Section>(section: Section, dequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, kind: CollectionElementKind = .automatic, configure: @escaping (View, Int, Section) -> Void) where Section: Composed.Section {
        self.kind = kind
        self.reuseIdentifier = reuseIdentifier ?? View.reuseIdentifier
        self.dequeueMethod = dequeueMethod

        self.configure = { view, index, section in
            // swiftlint:disable force_cast
            configure(view as! View, index, section as! Section)
        }
    }

}
