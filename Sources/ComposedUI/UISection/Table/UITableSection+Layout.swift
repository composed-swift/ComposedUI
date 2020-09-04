import UIKit
import Composed

extension UITableSection {

    public struct LayoutHandlers {
        internal private(set) var _estimatedHeightForHeader: ((CGFloat) -> CGFloat)?
        public var estimatedHeightForHeader: ((CGFloat) -> CGFloat)? {
            get { nil }
            set { _estimatedHeightForHeader = newValue }
        }

        internal private(set) var _estimatedHeightForFooter: ((CGFloat) -> CGFloat)?
        public var estimatedHeightForFooter: ((CGFloat) -> CGFloat)? {
            get { nil }
            set { _estimatedHeightForFooter = newValue }
        }

        internal private(set) var _estimatedHeightForItem: ((Int, CGFloat) -> CGFloat)?
        public var estimatedHeightForItem: ((Int, CGFloat) -> CGFloat)? {
            get { nil }
            set { _estimatedHeightForItem = newValue }
        }

        internal private(set) var _heightForHeader: ((CGFloat) -> CGFloat)?
        public var heightForHeader: ((CGFloat) -> CGFloat)? {
            get { nil }
            set { _heightForHeader = newValue }
        }

        internal private(set) var _heightForFooter: ((CGFloat) -> CGFloat)?
        public var heightForFooter: ((CGFloat) -> CGFloat)? {
            get { nil }
            set { _heightForFooter = newValue }
        }

        internal private(set) var _heightForItem: ((Int, CGFloat) -> CGFloat)?
        public var heightForItem: ((Int, CGFloat) -> CGFloat)? {
            get { nil }
            set { _heightForItem = newValue }
        }
    }

}
