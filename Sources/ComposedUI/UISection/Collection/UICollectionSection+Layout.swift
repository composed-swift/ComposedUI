import UIKit
import Composed

extension UICollectionSection {

    public struct LayoutHandlers {
        @available(iOS 13, *)
        internal private(set) lazy var _compositional: ((NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection?)? = nil
        @available(iOS 13, *)
        public var compositional: ((NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection?)? {
            get { nil }
            set { _compositional = newValue }
        }
    }

}
