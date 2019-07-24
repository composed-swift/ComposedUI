import UIKit

/// Defines a provider for a view, prototype and configuration handler. Cells, headers and footers can all be configured with this provider
public final class CollectionElement {

    public enum Context {
        case sizing
        case presentation
    }

    public typealias ViewType = UICollectionReusableView

    public let dequeueMethod: DequeueMethod
    public let configure: (UICollectionReusableView, IndexPath, Context) -> Void

    private let prototypeProvider: () -> UICollectionReusableView

    public private(set) lazy var prototype: UICollectionReusableView = {
        return prototypeProvider()
    }()

    public private(set) lazy var reuseIdentifier: String = {
        return prototype.reuseIdentifier ?? type(of: prototype).reuseIdentifier
    }()

    public init<View>(prototype: @escaping @autoclosure () -> View, dequeueMethod: DequeueMethod, reuseIdentifier: String? = nil, _ configure: @escaping (View, IndexPath, Context) -> Void) where View: UICollectionReusableView {

        self.prototypeProvider = prototype
        self.dequeueMethod = dequeueMethod
        self.configure = { view, indexPath, context in
            // swiftlint:disable force_cast
            configure(view as! View, indexPath, context)
        }

        if let reuseIdentifier = reuseIdentifier {
            self.reuseIdentifier = reuseIdentifier
        }
    }

}
