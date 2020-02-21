import UIKit

/// Conform your section to this to signal to the Coordinator that you want to handle updates manually for the cells in this section. Your cell configuration closure will be called instead of `reloadItems`
public protocol TableUpdateHandling: TableSectionProvider {
    func allowsReload(forItemAt index: Int) -> Bool
}

public extension TableUpdateHandling {
    func allowsReload(forItemAt index: Int) -> Bool { return false }
}

