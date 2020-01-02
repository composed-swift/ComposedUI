import UIKit

/// Conform your section to this to signal to the Coordinator that you want to handle updates manually for the cells in this section. Your cell configuration closure will be called instead of `reloadItems`
public protocol CollectionUpdateHandling: CollectionSectionProvider {
    func allowsReload(forItemAt index: Int) -> Bool
}

public extension CollectionUpdateHandling {
    func allowsReload(forItemAt index: Int) -> Bool { return false }
}
