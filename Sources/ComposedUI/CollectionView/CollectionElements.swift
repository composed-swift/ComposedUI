import UIKit
import Composed

public protocol CollectionElementsProvider {
    var cell: CollectionElement<UICollectionViewCell> { get }
    var header: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var footer: CollectionSupplementaryElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
}

public extension CollectionElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}

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

public final class CollectionSupplementaryElement<View>: CollectionElement<View> where View: UICollectionReusableView {

    internal let kind: CollectionElementKind

    public init<Section>(section: Section, dequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, kind: CollectionElementKind = .automatic, configure: @escaping (View, Int, Section) -> Void) where Section: Composed.Section {
        self.kind = kind
        super.init(section: section, cellDequeueMethod: dequeueMethod, reuseIdentifier: reuseIdentifier, configure: configure)
    }

}

/// Defines a provider for a view, prototype and configuration handler. Cells, headers and footers can all be configured with this provider
public class CollectionElement<View> where View: UICollectionReusableView {

    public typealias ViewType = UICollectionReusableView

    internal let viewType: UICollectionReusableView.Type

    internal let dequeueMethod: DequeueMethod<View>
    internal let configure: (UICollectionReusableView, Int, Section) -> Void

    internal let reuseIdentifier: String

    public init<Section>(section: Section, cellDequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, configure: @escaping (View, Int, Section) -> Void) where Section: Composed.Section {
        self.viewType = View.self
        self.reuseIdentifier = reuseIdentifier ?? View.reuseIdentifier
        self.dequeueMethod = cellDequeueMethod

        self.configure = { view, index, section in
            // swiftlint:disable force_cast
            configure(view as! View, index, section as! Section)
        }
    }

}
