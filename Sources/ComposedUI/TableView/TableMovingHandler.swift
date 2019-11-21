import UIKit
import Composed

public protocol TableMovingHandler: TableSectionProvider {
    func allowsMove(at index: Int) -> Bool
    func didMove(from source: Int, to destination: Int)
    func targetIndex(forMoveFrom source: Int, to proposed: Int) -> Int
}

public extension TableMovingHandler {
    func allowsMove(at index: Int) -> Bool { return false }
    func didMove(from source: Int, to destination: Int) { }
    func targetIndex(forMoveFrom source: Int, to proposed: Int) -> Int { return proposed }
}
