import UIKit

/// Conform to this protocol to provide layout specific details for a `UITableView` and its cells, headers and footers.
public protocol TableSectionLayoutHandler: TableSectionProvider {

    /// Provide the view with an estimated height for its header.
    ///
    /// Providing an estimate can improve the user experience when loading the content. If the view contains variable height headers, it might be expensive to calculate all their heights and so lead to a longer load time. Using estimation allows you to defer some of the cost of geometry calculation from load time to scrolling time.
    ///
    /// - Parameters:
    ///   - suggested: The suggested height will generally be the UIKit default
    ///   - traitCollection: The current trait collection applied to the view
    func estimatedHeightForHeader(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat

    /// Provide the view with an estimated height for its footer.
    ///
    /// Providing an estimate can improve the user experience when loading the content. If the view contains variable height footers, it might be expensive to calculate all their heights and so lead to a longer load time. Using estimation allows you to defer some of the cost of geometry calculation from load time to scrolling time.
    ///
    /// - Parameters:
    ///   - suggested: The suggested height will generally be the UIKit default
    ///   - traitCollection: The current trait collection applied to the view
    func estimatedHeightForFooter(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat

    /// Provide the view with an estimated height for its cell.
    ///
    /// Providing an estimate can improve the user experience when loading the content. If the view contains variable height cells, it might be expensive to calculate all their heights and so lead to a longer load time. Using estimation allows you to defer some of the cost of geometry calculation from load time to scrolling time.
    ///
    /// - Parameters:
    ///   - index: The element index
    ///   - suggested: The suggested height will generally be the UIKit default
    ///   - traitCollection: The current trait collection applied to the view
    func estimatedHeightForItem(at index: Int, suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat

    /// Provide the view with the height of your header.
    /// - Parameters:
    ///   - suggested: The suggested height will generally be the UIKit default or an inherited value
    ///   - traitCollection: The current trait collection applied to the view
    func heightForHeader(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat

    /// Provide the view with the height of your footer.
    /// - Parameters:
    ///   - suggested: The suggested height will generally be the UIKit default or an inherited value
    ///   - traitCollection: The current trait collection applied to the view
    func heightForFooter(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat

    /// Provide the view with the height of your footer.
    /// - Parameters:
    ///   - index: The element index
    ///   - suggested: The suggested height will generally be the UIKit default or an inherited value
    ///   - traitCollection: The current trait collection applied to the view
    func heightForItem(at index: Int, suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat

}

public extension TableSectionLayoutHandler {
    func estimatedHeightForHeader(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }
    func estimatedHeightForFooter(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }
    func estimatedHeightForItem(at index: Int, suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }

    func heightForHeader(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }
    func heightForFooter(suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }
    func heightForItem(at index: Int, suggested: CGFloat, traitCollection: UITraitCollection) -> CGFloat { return suggested }
}
