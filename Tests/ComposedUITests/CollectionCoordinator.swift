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
        let child4 = MockCollectionArraySection(["1", "2", "3"])

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

        XCTAssertEqual(collectionCoordinator.batchedSectionInserts, [1])
        XCTAssertTrue(collectionCoordinator.batchedSectionRemovals.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowRemovals.isEmpty)

        child3.remove(at: 1)

        XCTAssertEqual(collectionCoordinator.batchedSectionInserts, [1])
        XCTAssertTrue(collectionCoordinator.batchedSectionRemovals.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowUpdates.isEmpty)
        XCTAssertEqual(
            collectionCoordinator.batchedRowRemovals,
            [IndexPath(row: 1, section: 2)],
            "Section should be updated to account for previously deleted section"
        )

        rootSectionProvider.remove(child2)

        XCTAssertEqual(collectionCoordinator.batchedSectionInserts, [1, 2])
        XCTAssertTrue(collectionCoordinator.batchedSectionRemovals.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowUpdates.isEmpty)
        XCTAssertEqual(
            collectionCoordinator.batchedRowRemovals,
            [IndexPath(row: 1, section: 1)],
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
