import UIKit

/// Defines a provider for a view, prototype and configuration handler. Cells, headers and footers can all be configured with this provider
public final class CollectionElement {

    /// The method to use when dequeuing a view from a UICollectionView
    ///
    /// - nib: Load from a XIB
    /// - `class`: Load from a class
    public enum DequeueMethod {
        /// Load from a nib
        case nib
        /// Load from a class
        case `class`
    }

    public enum Context {
        case sizing
        case presentation
    }

    public typealias ViewType = UICollectionReusableView

    public let dequeueMethod: DequeueMethod
    public let configure: (UICollectionReusableView, IndexPath, Context) -> Void

    private let prototypeProvider: () -> UICollectionReusableView
    private var _prototypeView: UICollectionReusableView?

    public var prototype: UICollectionReusableView {
        if let view = _prototypeView { return view }
        let view = prototypeProvider()
        _prototypeView = view
        return view
    }

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
