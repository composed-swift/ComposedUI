import Foundation

/**
 A value that collects and reduces changes to allow them to allow multiple changes
 to be applied at once.

 The logic of how to reduce the changes is designed to match that of `UICollectionView`
 and `UITableView`, allowing for reuse between both.

 `ChangesReducer` uses the generalised terms "group" and "element", which can be mapped directly
 to "section" and "row" for `UITableView`s and "section" and "item" for `UICollectionView`.
 */
internal struct ChangesReducer {
    internal var hasActiveUpdates: Bool {
        return activeUpdates > 0
    }

    private var activeUpdates = 0

    private var changeset: Changeset = Changeset()

    /// Begin performing updates. This must be called prior to making updates.
    ///
    /// It is possible to call this function multiple times to build up a batch of changes.
    ///
    /// All calls to this must be balanced with a call to `endUpdating`.
    internal mutating func beginUpdating() {
        activeUpdates += 1
    }

    /// End the current collection of updates.
    ///
    /// - Returns: The completed changeset, if this ends the last update in the batch.
    internal mutating func endUpdating() -> Changeset? {
        activeUpdates -= 1

        guard activeUpdates == 0 else {
            assert(activeUpdates > 0, "`endUpdating` calls must be balanced with `beginUpdating`")
            return nil
        }

        let changeset = self.changeset
        self.changeset = Changeset()
        return changeset
    }

    internal mutating func updateGroups(_ groups: IndexSet) {
        changeset.groupsUpdated.formUnion(groups)
    }

    internal mutating func insertGroups(_ groups: [Int]) {
        insertGroups(IndexSet(groups))
    }

    internal mutating func insertGroups(_ groups: IndexSet) {
        groups.forEach { insertedGroup in
            if changeset.groupsRemoved.remove(insertedGroup) != nil {
                changeset.groupsUpdated.insert(insertedGroup)
            } else {
                changeset.groupsRemoved = Set(changeset.groupsRemoved.map { removedGroup in
                    if removedGroup > insertedGroup {
                        return removedGroup + 1
                    } else {
                        return removedGroup
                    }
                })
                changeset.groupsInserted.insert(insertedGroup)
            }

            changeset.groupsInserted = Set(changeset.groupsInserted.map { insertedGroup in
                if insertedGroup > insertedGroup {
                    return insertedGroup + 1
                } else {
                    return insertedGroup
                }
            })

            changeset.groupsUpdated = Set(changeset.groupsUpdated.map { updatedGroup in
                if updatedGroup > insertedGroup {
                    return updatedGroup + 1
                } else {
                    return updatedGroup
                }
            })

            changeset.elementsRemoved = Set(changeset.elementsRemoved.map { removedIndexPath in
                var removedIndexPath = removedIndexPath

                if removedIndexPath.section > insertedGroup {
                    removedIndexPath.section += 1
                }

                return removedIndexPath
            })

            changeset.elementsInserted = Set(changeset.elementsInserted.map { insertedIndexPath in
                var insertedIndexPath = insertedIndexPath

                if insertedIndexPath.section > insertedGroup {
                    insertedIndexPath.section += 1
                }

                return insertedIndexPath
            })

            changeset.elementsUpdated = Set(changeset.elementsUpdated.map { updatedIndexPath in
                var updatedIndexPath = updatedIndexPath

                if updatedIndexPath.section > insertedGroup {
                    updatedIndexPath.section += 1
                }

                return updatedIndexPath
            })

            changeset.elementsMoved = Set(changeset.elementsMoved.map { move in
                var move = move

                if move.from.section > insertedGroup {
                    move.from.section += 1
                }

                if move.to.section > insertedGroup {
                    move.to.section += 1
                }

                return move
            })
        }
    }

    internal mutating func removeGroups(_ groups: [Int]) {
        removeGroups(IndexSet(groups))
    }

    internal mutating func removeGroups(_ groups: IndexSet) {
        groups.forEach { removedGroup in
            if changeset.groupsInserted.remove(removedGroup) == nil {
                changeset.groupsRemoved = Set(changeset.groupsRemoved
                    .sorted(by: <)
                    .reduce(into: (previous: Int?.none, groupsRemoved: [Int]()), { (result, groupsRemoved) in
                        if groupsRemoved == removedGroup {
                            result.groupsRemoved.append(groupsRemoved)
                            result.groupsRemoved.append(groupsRemoved + 1)
                            result.previous = groupsRemoved + 1
                        } else if let previous = result.previous, groupsRemoved == previous {
                            result.groupsRemoved.append(groupsRemoved + 1)
                            result.previous = groupsRemoved + 1
                        } else {
                            result.groupsRemoved.append(groupsRemoved)
                            result.previous = groupsRemoved
                        }
                    })
                    .groupsRemoved
                )

                if !changeset.groupsRemoved.contains(removedGroup) {
                    changeset.groupsRemoved.insert(removedGroup)
                }
            }

            changeset.groupsInserted = Set(changeset.groupsInserted.map { insertedGroup in
                if insertedGroup > removedGroup {
                    return insertedGroup - 1
                } else {
                    return insertedGroup
                }
            })

            changeset.groupsUpdated = Set(changeset.groupsUpdated.map { updatedGroup in
                if updatedGroup > removedGroup {
                    return updatedGroup - 1
                } else {
                    return updatedGroup
                }
            })

            changeset.elementsInserted = Set(changeset.elementsInserted.compactMap { insertedIndexPath in
                guard insertedIndexPath.section != removedGroup else { return nil }

                var batchedRowInsert = insertedIndexPath

                if batchedRowInsert.section > removedGroup {
                    batchedRowInsert.section -= 1
                }

                return batchedRowInsert
            })

            changeset.elementsUpdated = Set(changeset.elementsUpdated.compactMap { updatedIndexPath in
                guard updatedIndexPath.section != removedGroup else { return nil }

                var batchedRowUpdate = updatedIndexPath

                if batchedRowUpdate.section > removedGroup {
                    batchedRowUpdate.section -= 1
                }

                return batchedRowUpdate
            })

            changeset.elementsRemoved = Set(changeset.elementsRemoved.compactMap { removedIndexPath in
                guard removedIndexPath.section != removedGroup else { return nil }

                var batchedRowRemoval = removedIndexPath

                if batchedRowRemoval.section > removedGroup {
                    batchedRowRemoval.section -= 1
                }

                return batchedRowRemoval
            })

            changeset.elementsMoved = Set(changeset.elementsMoved.compactMap { move in
                guard move.to.section != removedGroup else { return nil }

                var move = move

                if move.from.section > removedGroup {
                    move.from.section -= 1
                }

                if move.to.section > removedGroup {
                    move.to.section -= 1
                }

                return move
            })
        }
    }

    internal mutating func insertElements(at indexPaths: [IndexPath]) {
        changeset.elementsInserted.formUnion(indexPaths)
    }

    internal mutating func removeElements(at indexPaths: [IndexPath]) {
        indexPaths.forEach { removedIndexPath in
            if changeset.elementsUpdated.remove(removedIndexPath) == nil, changeset.elementsInserted.remove(removedIndexPath) == nil {
                changeset.elementsRemoved.insert(removedIndexPath)
            }

            changeset.elementsUpdated = Set(changeset.elementsUpdated.compactMap { updatedIndexPath in
                guard updatedIndexPath.section == removedIndexPath.section else { return updatedIndexPath }

                if updatedIndexPath.item > removedIndexPath.item {
                    if updatedIndexPath.item == removedIndexPath.item + 1 {
                        // Triggering an update to row with the same index path as one that's been removed
                        // will trigger "attempt to delete and reload the same index path"
                        changeset.elementsRemoved.insert(updatedIndexPath)
                        changeset.elementsInserted.insert(updatedIndexPath)
                        return nil
                    }

                    return IndexPath(item: updatedIndexPath.item - 1, section: updatedIndexPath.section)
                } else {
                    return updatedIndexPath
                }
            })

            changeset.elementsInserted = Set(changeset.elementsInserted.map { insertedIndexPath in
                guard insertedIndexPath.section == removedIndexPath.section else { return insertedIndexPath }

                if insertedIndexPath.item > removedIndexPath.item {
                    return IndexPath(item: insertedIndexPath.item - 1, section: insertedIndexPath.section)
                } else {
                    return insertedIndexPath
                }
            })

            changeset.elementsMoved = Set(changeset.elementsMoved.map { move in
                var move = move

                if move.from.section == removedIndexPath.section, move.from.item > removedIndexPath.item {
                    move.from.item -= 1
                }

                if move.to.section == removedIndexPath.section, move.to.item > removedIndexPath.item {
                    move.to.item -= 1
                }

                return move
            })
        }
    }

    internal mutating func updateElements(at indexPaths: [IndexPath]) {
        changeset.elementsUpdated.formUnion(indexPaths)
    }

    internal mutating func moveElements(_ moves: [Changeset.Move]) {
        changeset.elementsMoved.formUnion(moves)
    }

    internal mutating func moveElements(_ moves: [(from: IndexPath, to: IndexPath)]) {
        changeset.elementsMoved.formUnion(moves.map { Changeset.Move(from: $0.from, to: $0.to) })
    }
}
