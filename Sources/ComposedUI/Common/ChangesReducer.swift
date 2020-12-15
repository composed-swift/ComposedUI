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
    internal private(set) var changeset: Changeset = Changeset()

    /// Reset the set of changes to be empty.
    internal mutating func reset() {
        changeset = Changeset()
    }

    internal mutating func updateGroups(_ groups: IndexSet) {
        changeset.groupsUpdated.formUnion(groups)
    }

    internal mutating func insertGroups(_ groups: IndexSet) {
        groups.forEach { insertedSection in
            if changeset.groupsRemoved.remove(insertedSection) != nil {
                changeset.groupsUpdated.insert(insertedSection)
            } else {
                changeset.groupsRemoved = Set(changeset.groupsRemoved.map { batchedSectionRemoval in
                    if batchedSectionRemoval > insertedSection {
                        return batchedSectionRemoval + 1
                    } else {
                        return batchedSectionRemoval
                    }
                })
                changeset.groupsInserted.insert(insertedSection)
            }

            changeset.groupsInserted = Set(changeset.groupsInserted.map { batchedSectionInsert in
                if batchedSectionInsert > insertedSection {
                    return batchedSectionInsert + 1
                } else {
                    return batchedSectionInsert
                }
            })

            changeset.groupsUpdated = Set(changeset.groupsUpdated.map { batchedSectionUpdate in
                if batchedSectionUpdate > insertedSection {
                    return batchedSectionUpdate + 1
                } else {
                    return batchedSectionUpdate
                }
            })

            changeset.elementsRemoved = Set(changeset.elementsRemoved.map { removedIndexPath in
                var removedIndexPath = removedIndexPath

                if removedIndexPath.section > insertedSection {
                    removedIndexPath.section += 1
                }

                return removedIndexPath
            })

            changeset.elementsInserted = Set(changeset.elementsInserted.map { insertedIndexPath in
                var insertedIndexPath = insertedIndexPath

                if insertedIndexPath.section > insertedSection {
                    insertedIndexPath.section += 1
                }

                return insertedIndexPath
            })

            changeset.elementsUpdated = Set(changeset.elementsUpdated.map { updatedIndexPath in
                var updatedIndexPath = updatedIndexPath

                if updatedIndexPath.section > insertedSection {
                    updatedIndexPath.section += 1
                }

                return updatedIndexPath
            })

            changeset.elementsMoved = Set(changeset.elementsMoved.map { move in
                var move = move

                if move.from.section > insertedSection {
                    move.from.section += 1
                }

                if move.to.section > insertedSection {
                    move.to.section += 1
                }

                return move
            })
        }
    }

    public mutating func mapping(_ mapping: SectionProviderMapping, didRemoveSections sections: IndexSet) {
        sections.forEach { removedSectionIndex in
            if changeset.groupsInserted.remove(removedSectionIndex) == nil {
                changeset.groupsRemoved = Set(changeset.groupsRemoved
                    .sorted(by: <)
                    .reduce(into: (previous: Int?.none, batchedSectionRemovals: [Int]()), { (result, batchedSectionRemoval) in
                        if batchedSectionRemoval == removedSectionIndex {
                            result.batchedSectionRemovals.append(batchedSectionRemoval)
                            result.batchedSectionRemovals.append(batchedSectionRemoval + 1)
                            result.previous = batchedSectionRemoval + 1
                        } else if let previous = result.previous, batchedSectionRemoval == previous {
                            result.batchedSectionRemovals.append(batchedSectionRemoval + 1)
                            result.previous = batchedSectionRemoval + 1
                        } else {
                            result.batchedSectionRemovals.append(batchedSectionRemoval)
                            result.previous = batchedSectionRemoval
                        }
                    })
                    .batchedSectionRemovals
                )

                if !changeset.groupsRemoved.contains(removedSectionIndex) {
                    changeset.groupsRemoved.insert(removedSectionIndex)
                }
            }

            changeset.groupsInserted = Set(changeset.groupsInserted.map { batchedSectionInsert in
                if batchedSectionInsert > removedSectionIndex {
                    return batchedSectionInsert - 1
                } else {
                    return batchedSectionInsert
                }
            })

            changeset.groupsUpdated = Set(changeset.groupsUpdated.map { batchedSectionUpdate in
                if batchedSectionUpdate > removedSectionIndex {
                    return batchedSectionUpdate - 1
                } else {
                    return batchedSectionUpdate
                }
            })

            changeset.elementsInserted = Set(changeset.elementsInserted.compactMap { batchedRowInsert in
                guard batchedRowInsert.section != removedSectionIndex else { return nil }

                var batchedRowInsert = batchedRowInsert

                if batchedRowInsert.section > removedSectionIndex {
                    batchedRowInsert.section -= 1
                }

                return batchedRowInsert
            })

            changeset.elementsUpdated = Set(changeset.elementsUpdated.compactMap { batchedRowUpdate in
                guard batchedRowUpdate.section != removedSectionIndex else { return nil }

                var batchedRowUpdate = batchedRowUpdate

                if batchedRowUpdate.section > removedSectionIndex {
                    batchedRowUpdate.section -= 1
                }

                return batchedRowUpdate
            })

            changeset.elementsRemoved = Set(changeset.elementsRemoved.compactMap { batchedRowRemoval in
                guard batchedRowRemoval.section != removedSectionIndex else { return nil }

                var batchedRowRemoval = batchedRowRemoval

                if batchedRowRemoval.section > removedSectionIndex {
                    batchedRowRemoval.section -= 1
                }

                return batchedRowRemoval
            })

            changeset.elementsMoved = Set(changeset.elementsMoved.compactMap { move in
                guard move.to.section != removedSectionIndex else { return nil }

                var move = move

                if move.from.section > removedSectionIndex {
                    move.from.section -= 1
                }

                if move.to.section > removedSectionIndex {
                    move.to.section -= 1
                }

                return move
            })
        }
    }

    public mutating func mapping(_ mapping: SectionProviderMapping, didInsertElementsAt indexPaths: [IndexPath]) {
        changeset.elementsInserted.formUnion(indexPaths)
    }

    public mutating func mapping(_ mapping: SectionProviderMapping, didRemoveElementsAt indexPaths: [IndexPath]) {
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

    public mutating func mapping(_ mapping: SectionProviderMapping, didUpdateElementsAt indexPaths: [IndexPath]) {
        changeset.elementsUpdated.formUnion(indexPaths)
    }

    public mutating func mapping(_ mapping: SectionProviderMapping, didMoveElementsAt moves: [(IndexPath, IndexPath)]) {
        let moves = moves.map { move in
            Changeset.Move(from: move.0, to: move.1)
        }
        changeset.elementsMoved.formUnion(moves)
    }
}
