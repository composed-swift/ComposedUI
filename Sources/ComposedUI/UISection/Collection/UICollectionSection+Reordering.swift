import UIKit
import Composed

extension UICollectionSection {

    public struct ReorderingHandlers {
        public var allowsReordering: Bool = true

        internal private(set) var _canReorder: ((Int) -> Bool)?
        public var canReorder: ((Int) -> Bool)? {
            get { nil }
            set { _canReorder = newValue }
        }

        internal private(set) var _willReorder: ((Int) -> Void)?
        public var willReorder: ((Int) -> Void)? {
            get { nil }
            set { _willReorder = newValue }
        }

        internal private(set) var _didReorder: ((Int) -> Void)?
        public var didReorder: ((Int) -> Void)? {
            get { nil }
            set { _didReorder = newValue }
        }
    }

}
