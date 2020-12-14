import XCTest
import Composed
@testable import ComposedUI

final class CollectionCoordinatorTests: XCTestCase {
    func testBatchUpdates() {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let rootSectionProvider = ComposedSectionProvider()
        let collectionCoordinator = CollectionCoordinator(collectionView: collectionView, sectionProvider: rootSectionProvider)

        rootSectionProvider.updateDelegate?.willBeginUpdating(rootSectionProvider)

        let child0 = MockCollectionArraySection(["1", "2", "3"])
        let child1 = MockCollectionArraySection(["1", "2", "3"])
        let child2 = MockCollectionArraySection(["1", "2", "3"])
        let child3 = MockCollectionArraySection(["1", "2", "3"])
        var child4 = MockCollectionArraySection(["1", "2", "3"])

        rootSectionProvider.append(child0)

        XCTAssertEqual(collectionCoordinator.batchedSectionInserts, [0])
        XCTAssertTrue(collectionCoordinator.batchedSectionRemovals.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowRemovals.isEmpty)

        rootSectionProvider.remove(child0)

        XCTAssertTrue(collectionCoordinator.batchedSectionInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionRemovals.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowRemovals.isEmpty)

        rootSectionProvider.append(child0)
        rootSectionProvider.append(child1)
        rootSectionProvider.append(child2)
        rootSectionProvider.append(child3)
        rootSectionProvider.append(child4)

        rootSectionProvider.remove(child2)

        XCTAssertEqual(collectionCoordinator.batchedSectionInserts, [0, 1, 2, 3])
        XCTAssertTrue(collectionCoordinator.batchedSectionRemovals.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowRemovals.isEmpty)

        rootSectionProvider.updateDelegate?.didEndUpdating(rootSectionProvider)

        XCTAssertTrue(collectionCoordinator.batchedSectionInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionRemovals.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowRemovals.isEmpty)

        rootSectionProvider.insert(child2, after: child1)

        rootSectionProvider.updateDelegate?.willBeginUpdating(rootSectionProvider)

        rootSectionProvider.remove(child1)

        XCTAssertTrue(collectionCoordinator.batchedSectionInserts.isEmpty)
        XCTAssertEqual(collectionCoordinator.batchedSectionRemovals, [1])
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowRemovals.isEmpty)

        child3.remove(at: 1)

        XCTAssertTrue(collectionCoordinator.batchedSectionInserts.isEmpty)
        XCTAssertEqual(collectionCoordinator.batchedSectionRemovals, [1])
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowUpdates.isEmpty)
        XCTAssertEqual(
            collectionCoordinator.batchedRowRemovals,
            [IndexPath(row: 1, section: 2)],
            "Section should be updated to account for previously deleted section"
        )

        child4.swapAt(0, 2)

        XCTAssertTrue(collectionCoordinator.batchedSectionInserts.isEmpty)
        XCTAssertEqual(collectionCoordinator.batchedSectionRemovals, [1])
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertEqual(
            collectionCoordinator.batchedRowUpdates,
            [IndexPath(row: 0, section: 3), IndexPath(row: 2, section: 3)]
        )
        XCTAssertEqual(
            collectionCoordinator.batchedRowRemovals,
            [IndexPath(row: 1, section: 2)],
            "Section should be updated to account for previously deleted section"
        )

        rootSectionProvider.remove(child2)

        XCTAssertTrue(collectionCoordinator.batchedSectionInserts.isEmpty)
        XCTAssertEqual(collectionCoordinator.batchedSectionRemovals, [1, 2])
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertEqual(
            collectionCoordinator.batchedRowUpdates,
            [IndexPath(row: 0, section: 2), IndexPath(row: 2, section: 2)]
        )
        XCTAssertEqual(
            collectionCoordinator.batchedRowRemovals,
            [IndexPath(row: 1, section: 1)],
            "Section should be updated to account for previously deleted section"
        )

        child4.append("4")

        XCTAssertTrue(collectionCoordinator.batchedSectionInserts.isEmpty)
        XCTAssertEqual(collectionCoordinator.batchedSectionRemovals, [1, 2])
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertEqual(
            collectionCoordinator.batchedRowInserts,
            [IndexPath(item: 3, section: 2)]
        )
        XCTAssertEqual(
            collectionCoordinator.batchedRowUpdates,
            [IndexPath(row: 0, section: 2), IndexPath(row: 2, section: 2)]
        )
        XCTAssertEqual(
            collectionCoordinator.batchedRowRemovals,
            [IndexPath(row: 1, section: 1)],
            "Section should be updated to account for previously deleted section"
        )

        rootSectionProvider.remove(child0)

        XCTAssertTrue(collectionCoordinator.batchedSectionInserts.isEmpty)
        XCTAssertEqual(collectionCoordinator.batchedSectionRemovals, [1, 2, 0])
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertEqual(
            collectionCoordinator.batchedRowInserts,
            [IndexPath(item: 3, section: 1)]
        )
        XCTAssertEqual(
            collectionCoordinator.batchedRowUpdates,
            [IndexPath(row: 0, section: 1), IndexPath(row: 2, section: 1)]
        )
        XCTAssertEqual(
            collectionCoordinator.batchedRowRemovals,
            [IndexPath(row: 1, section: 0)],
            "Section should be updated to account for previously deleted section"
        )

        child4.remove(at: 1)

        XCTAssertTrue(collectionCoordinator.batchedSectionInserts.isEmpty)
        XCTAssertEqual(collectionCoordinator.batchedSectionRemovals, [1, 2, 0])
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertEqual(
            collectionCoordinator.batchedRowInserts,
            [IndexPath(item: 2, section: 1)]
        )
        XCTAssertEqual(
            collectionCoordinator.batchedRowUpdates,
            [IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 1)]
        )
        XCTAssertEqual(
            collectionCoordinator.batchedRowRemovals,
            [IndexPath(row: 1, section: 0), IndexPath(row: 1, section: 1)],
            "Section should be updated to account for previously deleted section"
        )

        rootSectionProvider.insert(child0, at: 0)

        XCTAssertTrue(collectionCoordinator.batchedSectionInserts.isEmpty)
        XCTAssertEqual(collectionCoordinator.batchedSectionRemovals, [1, 2])
        XCTAssertEqual(collectionCoordinator.batchedSectionUpdates, [0])
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertEqual(
            collectionCoordinator.batchedRowInserts,
            [IndexPath(item: 2, section: 2)]
        )
        XCTAssertEqual(
            collectionCoordinator.batchedRowUpdates,
            [IndexPath(row: 0, section: 2), IndexPath(row: 1, section: 2)]
        )
        XCTAssertEqual(
            collectionCoordinator.batchedRowRemovals,
            [IndexPath(row: 1, section: 0), IndexPath(row: 1, section: 2)],
            "Section should be updated to account for previously deleted section"
        )
    }
}

private final class MockCollectionArraySection: ArraySection<String>, CollectionSectionProvider {
    func section(with traitCollection: UITraitCollection) -> CollectionSection {
        let cell = CollectionCellElement(section: self, dequeueMethod: .fromClass(UICollectionViewCell.self), configure: { _, _, _ in })
        return CollectionSection(section: self, cell: cell)
    }
}
