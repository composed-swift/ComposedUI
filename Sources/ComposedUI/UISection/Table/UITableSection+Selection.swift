import UIKit
import Composed

extension UITableSection {

    public struct SelectionHandlers {
        public var allowsSelection: Bool = true
        public var allowsMultipleSelection: Bool = false

        internal private(set) var _shouldHighlight: ((Int) -> Bool)?
        public var shouldHighlight: ((Int) -> Bool)? {
            get { nil }
            set { _shouldHighlight = newValue }
        }

        internal private(set) var _shouldSelect: ((Int) -> Bool)?
        public var shouldSelect: ((Int) -> Bool)? {
            get { nil }
            set { _shouldSelect = newValue }
        }

        internal private(set) var _didSelect: ((Int) -> Bool)?
        public var didSelect: ((Int) -> Bool)? {
            get { nil }
            set { _didSelect = newValue }
        }

        internal private(set) var _didDeselect: ((Int) -> Bool)?
        public var didDeselect: ((Int) -> Bool)? {
            get { nil }
            set { _didDeselect = newValue }
        }
    }

}
