@testable import ProtonMail
import XCTest

class SingleRowTagsViewTests: XCTestCase {

    var sut: SingleRowTagsView!

    override func setUp() {
        super.setUp()

        sut = SingleRowTagsView()
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
    }

    func testTagsPerfectlyFitRow() {
        sut.frame.size = .init(width: 400, height: 0)
        sut.horizontalSpacing = 0
        let tag1 = UIView(frame: .init(origin: .zero, size: .init(width: 300, height: 0)))
        let tag2 = UIView(frame: .init(origin: .zero, size: .init(width: 50, height: 0)))
        let tag3 = UIView(frame: .init(origin: .zero, size: .init(width: 50, height: 0)))
        sut.tagViews = [tag1, tag2, tag3]

        XCTAssertEqual(sut.subviews, [tag1, tag2, tag3])
        XCTAssertEqual(sut.subviews.last?.frame.maxX, 400)
    }

    func testTagsWithSpacingPerfectlyFitsRow() {
        sut.frame.size = .init(width: 300, height: 0)
        sut.horizontalSpacing = 100
        let tag1 = UIView(frame: .init(origin: .zero, size: .init(width: 100, height: 0)))
        let tag2 = UIView(frame: .init(origin: .zero, size: .init(width: 100, height: 0)))
        sut.tagViews = [tag1, tag2]

        XCTAssertEqual(sut.subviews, [tag1, tag2])
        XCTAssertEqual(sut.subviews.last?.frame.maxX, 300)
    }

    func testTagsdoNOTFitRow() {
        sut.frame.size = .init(width: 400, height: 0)
        sut.horizontalSpacing = 0
        let tag1 = UIView(frame: .init(origin: .zero, size: .init(width: 300, height: 0)))
        let tag2 = UIView(frame: .init(origin: .zero, size: .init(width: 50, height: 0)))
        let tag3 = UIView(frame: .init(origin: .zero, size: .init(width: 100, height: 0)))
        sut.tagViews = [tag1, tag2, tag3]

        XCTAssertEqual(sut.subviews[safe: 0], tag1)
        XCTAssertEqual(sut.subviews[safe: 1], tag2)
        XCTAssertTrue(sut.subviews[safe: 2] is UILabel)

        let label = sut.subviews[safe: 2] as? UILabel

        XCTAssertEqual(label?.text, "+1")
    }

    func testFirstBigTag() {
        sut.frame.size = .init(width: 400, height: 0)
        sut.horizontalSpacing = 0
        let tag1 = UIView(frame: .init(origin: .zero, size: .init(width: 500, height: 0)))
        let tag2 = UIView(frame: .init(origin: .zero, size: .init(width: 50, height: 0)))
        let tag3 = UIView(frame: .init(origin: .zero, size: .init(width: 100, height: 0)))
        sut.tagViews = [tag1, tag2, tag3]

        XCTAssertEqual(sut.subviews[safe: 0], tag1)
        XCTAssertTrue(sut.subviews[safe: 1] is UILabel)

        let label = sut.subviews[safe: 1] as? UILabel

        XCTAssertEqual(label?.text, "+2")
    }

    func testRemoveLastTagToPlaceLabelWithNumber() {
        sut.frame.size = .init(width: 400, height: 0)
        sut.horizontalSpacing = 0
        let tag1 = UIView(frame: .init(origin: .zero, size: .init(width: 300, height: 0)))
        let tag2 = UIView(frame: .init(origin: .zero, size: .init(width: 50, height: 0)))
        let tag3 = UIView(frame: .init(origin: .zero, size: .init(width: 50, height: 0)))
        let tag4 = UIView(frame: .init(origin: .zero, size: .init(width: 50, height: 0)))
        sut.tagViews = [tag1, tag2, tag3, tag4]

        XCTAssertEqual(sut.subviews.count, 3)
        XCTAssertEqual(sut.subviews[safe: 0], tag1)
        XCTAssertEqual(sut.subviews[safe: 1], tag2)
        XCTAssertTrue(sut.subviews[safe: 2] is UILabel)

        let label = sut.subviews[safe: 2] as? UILabel

        XCTAssertEqual(label?.text, "+2")
    }

}
