import UIKit
import Composed

// MARK: - Deprecations

@available(*, deprecated, renamed: "MoveHandler")
public protocol TableMovingHandler: TableSectionProvider {

    /// Return true to allow a move at the specified index
    /// - Parameter index: The element index
    @available(*, deprecated, renamed: "canMove(at:)")
    func allowsMove(at index: Int) -> Bool

    /// When a move occurs, this method will be called to notifiy the section
    /// - Parameters:
    ///   - source: The source element index
    ///   - destination: The destination element index
    func didMove(from sourceIndex: Int, to destinationIndex: Int)

    /// When a move is about to occur, this method will be called to give the caller an opportunity to return an alternate target element index
    /// - Parameters:
    ///   - source: The source element index
    ///   - proposed: The proposed destination element index
    @available(*, deprecated, renamed: "targetIndex(for:)")
    func targetIndex(forMoveFrom source: Int, to proposed: Int) -> Int

}
