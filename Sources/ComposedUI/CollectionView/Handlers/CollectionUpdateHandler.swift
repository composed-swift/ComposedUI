import UIKit

/// Conform your section to this to signal to the Coordinator that you want to handle updates manually for the cells in this section. Your cell configuration closure will be called instead of `reloadItems`
public protocol CollectionUpdateHandler: CollectionSectionProvider {

    /// Return true to signal to the view that it should reload the cell vs re-calling the cell configuration handler on `CollectionElement`
    /// - Parameter index: The element index
    func prefersReload(forElementAt index: Int) -> Bool

}
