import UIKit
import Composed

/// Provides cell-move handling for `UITableView`'s
public protocol TableMovingHandler: TableSectionProvider {

    /// Return true to allow a move at the specified index
    /// - Parameter index: The element index
    func allowsMove(at index: Int) -> Bool

    /// When a move occurs, this method will be called to notifiy the section
    /// - Parameters:
    ///   - source: The source element index
    ///   - destination: The destination element index
    func didMove(from source: Int, to destination: Int)

    /// When a move is about to occur, this method will be called to give the caller an opportunity to return an alternate target element index
    /// - Parameters:
    ///   - source: The source element index
    ///   - proposed: The proposed destination element index
    func targetIndex(forMoveFrom source: Int, to proposed: Int) -> Int

}

public extension TableMovingHandler {
    func allowsMove(at index: Int) -> Bool { return false }
    func didMove(from source: Int, to destination: Int) { }
    func targetIndex(forMoveFrom source: Int, to proposed: Int) -> Int { return proposed }
}
