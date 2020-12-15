import XCTest
import Composed
@testable import ComposedUI

final class ChangesReducerTests: XCTestCase {
    func testGroupInsertsUpdates() {
        var changesReducer = ChangesReducer()

        changesReducer.insertGroups(IndexSet([0, 1, 2]))

        XCTAssertEqual(changesReducer.changeset.groupsInserted, [0, 1, 2])
        XCTAssertTrue(changesReducer.changeset.groupsRemoved.isEmpty)
        XCTAssertTrue(changesReducer.changeset.groupsUpdated.isEmpty)
        XCTAssertTrue(changesReducer.changeset.elementsRemoved.isEmpty)
        XCTAssertTrue(changesReducer.changeset.elementsInserted.isEmpty)
        XCTAssertTrue(changesReducer.changeset.elementsUpdated.isEmpty)
        XCTAssertTrue(changesReducer.changeset.elementsMoved.isEmpty)
    }
}
