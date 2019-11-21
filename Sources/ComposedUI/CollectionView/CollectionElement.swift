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

/// Defines a provider for a view, prototype and configuration handler. Cells, headers and footers can all be configured with this provider
public class CollectionElement<View> where View: UICollectionReusableView {

    public typealias ViewType = UICollectionReusableView

    internal let dequeueMethod: DequeueMethod<View>
    internal let configure: (UICollectionReusableView, Int, Section) -> Void

    internal let reuseIdentifier: String

    public init<Section>(section: Section, cellDequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, configure: @escaping (View, Int, Section) -> Void) where Section: Composed.Section {
        self.reuseIdentifier = reuseIdentifier ?? View.reuseIdentifier
        self.dequeueMethod = cellDequeueMethod

        self.configure = { view, index, section in
            // swiftlint:disable force_cast
            configure(view as! View, index, section as! Section)
        }
    }

}

public final class CollectionCellElement<View> where View: UICollectionViewCell {


}

public final class CollectionSupplementaryElement<View>: CollectionElement<View> where View: UICollectionReusableView {

    internal let kind: CollectionElementKind

    public init<Section>(section: Section, dequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, kind: CollectionElementKind = .automatic, configure: @escaping (View, Int, Section) -> Void) where Section: Composed.Section {
        self.kind = kind
        super.init(section: section, cellDequeueMethod: dequeueMethod, reuseIdentifier: reuseIdentifier, configure: configure)
    }

}
