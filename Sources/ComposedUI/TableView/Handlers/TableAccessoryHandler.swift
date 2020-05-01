import UIKit
import Composed

/// Provides cell accessory handling for `UITableView`'s
public protocol TableAccessoryHandler: TableSectionProvider {

    /// Called when the accessory view is tapped for the cell at the specified index
    /// - Parameter index: The element index
    func didSelectAccessory(at index: Int)

}
