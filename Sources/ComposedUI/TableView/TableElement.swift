import UIKit

/// Defines a provider for a view, prototype and configuration handler. Cells, headers and footers can all be configured with this provider
public final class TableElement<View: UIView & ReusableView> {
    
    public enum Context {
        case sizing
        case presentation
    }

    public typealias ViewType = View

    public let dequeueMethod: DequeueMethod
    public let configure: (View, IndexPath, Context) -> Void

    private let prototypeProvider: () -> View
    private var _prototypeView: View?

    public var prototype: View {
        if let view = _prototypeView { return view }
        let view = prototypeProvider()
        _prototypeView = view
        return view
    }

    public private(set) lazy var reuseIdentifier: String = {
        return prototype.reuseIdentifier ?? type(of: prototype).reuseIdentifier
    }()

    public init(prototype: @escaping @autoclosure () -> View, dequeueMethod: DequeueMethod, reuseIdentifier: String? = nil, _ configure: @escaping (View, IndexPath, Context) -> Void) {

        self.prototypeProvider = prototype
        self.dequeueMethod = dequeueMethod
        self.configure = { view, indexPath, context in
            // swiftlint:disable force_cast
            configure(view, indexPath, context)
        }

        if let reuseIdentifier = reuseIdentifier {
            self.reuseIdentifier = reuseIdentifier
        }
    }

}
