import UIKit
import Composed

extension UITableSection {

    public struct EditingHandlers {
        public var allowsEditing: Bool = true

        internal private(set) var _canEdit: ((Int) -> Bool)?
        public var canEdit: ((Int) -> Bool)? {
            get { nil }
            set { _canEdit = newValue }
        }

        internal private(set) var _beginEditing: ((Int) -> Void)?
        public var beginEditing: ((Int) -> Void)? {
            get { nil }
            set { _beginEditing = newValue }
        }

        internal private(set) var _endEditing: ((Int) -> Void)?
        public var endEditing: ((Int) -> Void)? {
            get { nil }
            set { _endEditing = newValue }
        }
    }

}
