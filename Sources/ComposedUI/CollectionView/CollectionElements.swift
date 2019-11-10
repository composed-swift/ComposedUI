import UIKit
import Composed

public protocol CollectionElementsProvider {
    var cell: CollectionElement<UICollectionViewCell> { get }
    var header: CollectionElement<UICollectionReusableView>? { get }
    var footer: CollectionElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
}

public extension CollectionElementsProvider {
    var isEmpty: Bool { return numberOfElements == 0 }
}

public enum CollectionElementKind {
    case header
    case footer
    case custom(kind: String)

    internal var rawValue: String {
        switch self {
        case .header: return UICollectionView.elementKindSectionHeader
        case .footer: return UICollectionView.elementKindSectionFooter
        case let .custom(kind): return kind
        }
    }
}

/// Defines a provider for a view, prototype and configuration handler. Cells, headers and footers can all be configured with this provider
public final class CollectionElement<View> where View: UICollectionReusableView {

    public typealias ViewType = UICollectionReusableView

    public let dequeueMethod: DequeueMethod<View>
    public let configure: (UICollectionReusableView, Int, Section) -> Void

    public let reuseIdentifier: String

    internal let supplementaryViewProvider: (UICollectionView, String, IndexPath) -> View
    internal let kind: CollectionElementKind?

    public init<Section>(section: Section, cellDequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, configure: @escaping (View, Int, Section) -> Void) where Section: Composed.Section {
        self.reuseIdentifier = reuseIdentifier ?? View.reuseIdentifier
        self.dequeueMethod = cellDequeueMethod

        self.configure = { view, index, section in
            // swiftlint:disable force_cast
            configure(view as! View, index, section as! Section)
        }

        self.supplementaryViewProvider = { _, _, _ in fatalError("Not currently supported for cells") }
        self.kind = nil
    }

    public init<Section>(section: Section, dequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, kind: CollectionElementKind, supplementaryViewProvider: ((UICollectionView, String, IndexPath) -> View)? = nil, configure: @escaping (View, Int, Section) -> Void) where Section: Composed.Section {
        let identifier = reuseIdentifier ?? View.reuseIdentifier
        self.reuseIdentifier = identifier
        self.dequeueMethod = dequeueMethod
        self.kind = kind

        if let provider = supplementaryViewProvider {
            self.supplementaryViewProvider = { collectionView, kind, indexPath in
                switch dequeueMethod {
                case let .nib(type):
                    let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                    collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
                case let .class(type):
                    collectionView.register(type, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
                case .storyboard:
                    break
                }

                return provider(collectionView, kind, indexPath)
            }
        } else {
            self.supplementaryViewProvider = { collectionView, kind, indexPath in
                switch dequeueMethod {
                case let .nib(type):
                    let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                    collectionView.register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
                case let .class(type):
                    collectionView.register(type, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
                case .storyboard:
                    break
                }

                return collectionView.dequeue(supplementary: View.self, ofKind: kind, for: indexPath)
            }
        }

        self.configure = { view, index, section in
            // swiftlint:disable force_cast
            configure(view as! View, index, section as! Section)
        }
    }

}
