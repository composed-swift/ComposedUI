import UIKit

public struct Environment {
    public struct LayoutContainer {
        public let contentSize: CGSize
        public let effectiveContentSize: CGSize
    }

    public let container: LayoutContainer
    public let traitCollection: UITraitCollection
}
