import UIKit
import Composed

public protocol CollectionElementsProvider {
    var cell: CollectionElement<UICollectionViewCell> { get }
    var header: CollectionElement<UICollectionReusableView>? { get }
    var footer: CollectionElement<UICollectionReusableView>? { get }
    var background: CollectionElement<UICollectionReusableView>? { get }
    var numberOfElements: Int { get }
}

public struct CollectionElementContext {
    public let isSizing: Bool

    internal init(isSizing: Bool) {
        self.isSizing = isSizing
    }
}

/// Defines a provider for a view, prototype and configuration handler. Cells, headers and footers can all be configured with this provider
public final class CollectionElement<View> where View: UICollectionReusableView {

    public typealias ViewType = UICollectionReusableView

    public let dequeueMethod: DequeueMethod<View>
    public let configure: (UICollectionReusableView, Int, Section, CollectionElementContext) -> Void

    internal let prototypeType: View.Type
    private let prototypeProvider: () -> UICollectionReusableView?

    public private(set) lazy var prototype: UICollectionReusableView? = {
        return prototypeProvider()
    }()

    public private(set) lazy var reuseIdentifier: String = {
        let identifier = prototype?.reuseIdentifier ?? prototypeType.reuseIdentifier
        return identifier.isEmpty ? prototypeType.reuseIdentifier : identifier
    }()

    public init<Section>(section: Section, dequeueMethod: DequeueMethod<View>, reuseIdentifier: String? = nil, _ configure: @escaping (View, Int, Section, CollectionElementContext) -> Void) where Section: Composed.Section {
        self.prototypeType = View.self
        self.dequeueMethod = dequeueMethod

        self.prototypeProvider = {
            switch dequeueMethod {
            case let .class(type):
                return type.init(frame: .zero)
            case let .nib(type):
                let nib = UINib(nibName: String(describing: type), bundle: Bundle(for: type))
                return nib.instantiate(withOwner: nil, options: nil).first as? View
            case .storyboard:
                return nil
            }
        }

        self.configure = { view, index, section, context in
            // swiftlint:disable force_cast
            configure(view as! View, index, section as! Section, context)
        }

        if let reuseIdentifier = reuseIdentifier {
            self.reuseIdentifier = reuseIdentifier
        }
    }

}
