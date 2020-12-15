import XCTest
import Composed
@testable import ComposedUI

final class ChangesReducerTests: XCTestCase {
    func testGroupInserts() {
        var changesReducer = ChangesReducer()
        changesReducer.beginUpdating()
        changesReducer.insertGroups(IndexSet([0, 2]))
        changesReducer.insertGroups(IndexSet(integer: 1))
        let changeset = changesReducer.endUpdating()

        XCTAssertNotNil(changeset)

        XCTAssertEqual(changeset!.groupsInserted, [0, 1, 2])
        XCTAssertTrue(changeset!.groupsRemoved.isEmpty)
        XCTAssertTrue(changeset!.groupsUpdated.isEmpty)
        XCTAssertTrue(changeset!.elementsRemoved.isEmpty)
        XCTAssertTrue(changeset!.elementsInserted.isEmpty)
        XCTAssertTrue(changeset!.elementsUpdated.isEmpty)
        XCTAssertTrue(changeset!.elementsMoved.isEmpty)
    }

    func testGroupRemoves() {
        var changesReducer = ChangesReducer()
        changesReducer.beginUpdating()
        changesReducer.removeGroups(IndexSet([0, 2]))
        changesReducer.removeGroups(IndexSet(integer: 1))
        let changeset = changesReducer.endUpdating()

        XCTAssertNotNil(changeset)

        XCTAssertEqual(changeset!.groupsRemoved, [0, 1, 2])
        XCTAssertTrue(changeset!.groupsInserted.isEmpty)
        XCTAssertTrue(changeset!.groupsUpdated.isEmpty)
        XCTAssertTrue(changeset!.elementsRemoved.isEmpty)
        XCTAssertTrue(changeset!.elementsInserted.isEmpty)
        XCTAssertTrue(changeset!.elementsUpdated.isEmpty)
        XCTAssertTrue(changeset!.elementsMoved.isEmpty)
    }

    func testRemovingAGroupInsertedInTheSameBatch() {
        var changesReducer = ChangesReducer()
        changesReducer.beginUpdating()

        changesReducer.insertGroups([0])
        changesReducer.removeGroups([0])
        changesReducer.insertGroups([0, 1, 2, 3, 4])
        changesReducer.removeGroups([2])

        let changeset = changesReducer.endUpdating()

        XCTAssertNotNil(changeset)

        XCTAssertEqual(changeset!.groupsInserted, [0, 1, 2, 3])
        XCTAssertTrue(changeset!.groupsRemoved.isEmpty)
        XCTAssertTrue(changeset!.groupsUpdated.isEmpty)
        XCTAssertTrue(changeset!.elementsRemoved.isEmpty)
        XCTAssertTrue(changeset!.elementsInserted.isEmpty)
        XCTAssertTrue(changeset!.elementsUpdated.isEmpty)
        XCTAssertTrue(changeset!.elementsMoved.isEmpty)
    }

    func testMoveElement() {
        var changesReducer = ChangesReducer()
        changesReducer.beginUpdating()

        changesReducer.moveElements([(from: IndexPath(row: 0, section: 0), to: IndexPath(row: 1, section: 0))])

        let changeset = changesReducer.endUpdating()

        XCTAssertNotNil(changeset)

        XCTAssertEqual(
            changeset!.elementsMoved,
            [
                Changeset.Move(
                    from: IndexPath(row: 0, section: 0),
                    to: IndexPath(row: 1, section: 0)
                )
            ]
        )
        XCTAssertTrue(changeset!.elementsRemoved.isEmpty)
        XCTAssertTrue(changeset!.elementsInserted.isEmpty)
        XCTAssertTrue(changeset!.elementsUpdated.isEmpty)
        XCTAssertTrue(changeset!.groupsRemoved.isEmpty)
        XCTAssertTrue(changeset!.groupsRemoved.isEmpty)
        XCTAssertTrue(changeset!.groupsUpdated.isEmpty)
    }

    func testMoveElementThenRemoveElementBeforeMovedElement() {
        var changesReducer = ChangesReducer()
        changesReducer.beginUpdating()

        /**
         This is testing:

         - A
         - B
         - C
         - D

         # Swap C and D

         - A
         - B
         - D
         - C

         # Delete A

         - B
         - D
         - C
         */

        changesReducer.moveElements([(from: IndexPath(row: 2, section: 0), to: IndexPath(row: 3, section: 0))])
        changesReducer.removeElements(at: [IndexPath(row: 0, section: 0)])

        let changeset = changesReducer.endUpdating()

        XCTAssertNotNil(changeset)

        XCTAssertEqual(
            changeset!.elementsMoved,
            [
                Changeset.Move(
                    from: IndexPath(row: 1, section: 0),
                    to: IndexPath(row: 2, section: 0)
                )
            ]
        )
        XCTAssertEqual(changeset!.elementsRemoved, [IndexPath(row: 0, section: 0)])
        XCTAssertTrue(changeset!.elementsInserted.isEmpty)
        XCTAssertTrue(changeset!.elementsUpdated.isEmpty)
        XCTAssertTrue(changeset!.groupsRemoved.isEmpty)
        XCTAssertTrue(changeset!.groupsRemoved.isEmpty)
        XCTAssertTrue(changeset!.groupsUpdated.isEmpty)
    }

    func testRemoveAMovedIndex() {
        var changesReducer = ChangesReducer()
        changesReducer.beginUpdating()

        /**
         This is testing:

         - A
         - B
         - C

         # Swap B and C

         - A
         - C
         - B

         # Delete B

         - A
         - C

         `UICollectionView` does not support deleting an index path and moving to the same index path, so this should produce:

         - Delete 0
         - Delete 1
         - Delete 2
         - Insert 0
         - Insert 2
         */

        changesReducer.moveElements([(from: IndexPath(row: 1, section: 0), to: IndexPath(row: 2, section: 0))])
        changesReducer.removeElements(at: [IndexPath(row: 1, section: 0)])

        let changeset = changesReducer.endUpdating()

        XCTAssertNotNil(changeset)

        XCTAssertEqual(
            changeset!.elementsRemoved,
            [
                IndexPath(row: 0, section: 0),
                IndexPath(row: 1, section: 0),
                IndexPath(row: 2, section: 0),
            ]
        )
        XCTAssertEqual(
            changeset!.elementsInserted,
            [
                IndexPath(row: 0, section: 0),
                IndexPath(row: 1, section: 0),
            ]
        )
        XCTAssertTrue(changeset!.elementsUpdated.isEmpty)
        XCTAssertTrue(changeset!.elementsMoved.isEmpty)
        XCTAssertTrue(changeset!.groupsRemoved.isEmpty)
        XCTAssertTrue(changeset!.groupsRemoved.isEmpty)
        XCTAssertTrue(changeset!.groupsUpdated.isEmpty)
    }

    func testMoveElementAtSameIndexAsRemove() {
        var changesReducer = ChangesReducer()
        changesReducer.beginUpdating()

        /**
         This is testing:

         - A
         - B
         - C

         # Delete B

         - A
         - C

         # Swap A and C

         - C
         - A

         `UICollectionView` does not support deleting an index path and moving to the same index path, so this should produce:

         - Delete 0
         - Delete 1
         - Delete 2
         - Insert 0
         - Insert 2
         */

        changesReducer.removeElements(at: [IndexPath(row: 1, section: 0)])
        changesReducer.moveElements([(from: IndexPath(row: 0, section: 0), to: IndexPath(row: 1, section: 0))])

        let changeset = changesReducer.endUpdating()

        XCTAssertNotNil(changeset)

        XCTAssertEqual(
            changeset!.elementsRemoved,
            [
                IndexPath(row: 0, section: 0),
                IndexPath(row: 1, section: 0),
                IndexPath(row: 2, section: 0),
            ]
        )
        XCTAssertEqual(
            changeset!.elementsInserted,
            [
                IndexPath(row: 0, section: 0),
                IndexPath(row: 1, section: 0),
            ]
        )
        XCTAssertTrue(changeset!.elementsUpdated.isEmpty)
        XCTAssertTrue(changeset!.elementsMoved.isEmpty)
        XCTAssertTrue(changeset!.groupsRemoved.isEmpty)
        XCTAssertTrue(changeset!.groupsRemoved.isEmpty)
        XCTAssertTrue(changeset!.groupsUpdated.isEmpty)
    }
}
