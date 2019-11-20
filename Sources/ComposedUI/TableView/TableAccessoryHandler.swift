import UIKit
import Composed

public protocol TableAccessoryHandler: TableSectionProvider {
    func didSelectAccessory(at index: Int)
}
