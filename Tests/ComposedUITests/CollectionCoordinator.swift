import XCTest
import Composed
@testable import ComposedUI

final class CollectionCoordinatorTests: XCTestCase {
    func testBatchUpdates() {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let rootSectionProvider = ComposedSectionProvider()
        let collectionCoordinator = CollectionCoordinator(collectionView: collectionView, sectionProvider: rootSectionProvider)

        rootSectionProvider.updateDelegate?.willBeginUpdating(rootSectionProvider)

        let childA = ArraySection(["1", "2", "3"])
        rootSectionProvider.append(childA)

        XCTAssertEqual(collectionCoordinator.batchedSectionInserts, [0])
        XCTAssertTrue(collectionCoordinator.batchedSectionRemovals.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowRemovals.isEmpty)

        rootSectionProvider.remove(childA)

        XCTAssertTrue(collectionCoordinator.batchedSectionInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionRemovals.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedSectionUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowMoves.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowInserts.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowUpdates.isEmpty)
        XCTAssertTrue(collectionCoordinator.batchedRowRemovals.isEmpty)
    }
}
