import Foundation

/**
 A collection of changes to be applied in batch.
 */
internal struct Changeset {
    internal struct Move: Hashable {
        internal var from: IndexPath
        internal var to: IndexPath
    }

    internal var groupsInserted: Set<Int> = []
    internal var groupsRemoved: Set<Int> = []
    internal var groupsUpdated: Set<Int> = []
    internal var elementsRemoved: Set<IndexPath> = []
    internal var elementsInserted: Set<IndexPath> = []
    internal var elementsUpdated: Set<IndexPath> = []
    internal var elementsMoved: Set<Move> = []
}
