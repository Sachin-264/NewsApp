import XCTest

final class NewsAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFastSearchAndDetailSwipe() throws {
        let app = XCUIApplication()
        app.launch()

        // Test Fast Search
        let searchField = app.textFields["Search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 10), "Search bar should appear")
        searchField.tap()
        searchField.typeText("galaxy")

        // Instant results appear
        let galaxyArticle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'galaxy'")).firstMatch
        XCTAssertTrue(galaxyArticle.waitForExistence(timeout: 3), "Galaxy article should appear instantly")

        // Take search screenshot
        let searchAttachment = XCTAttachment(screenshot: app.screenshot())
        searchAttachment.lifetime = .keepAlways
        add(searchAttachment)

        // Tap the search result to open detail
        galaxyArticle.tap()

        // Detail screen should load
        let trendingLabel = app.staticTexts["Trending"]
        XCTAssertTrue(trendingLabel.waitForExistence(timeout: 5), "Detail screen should show Trending")

        let detailAttachment = XCTAttachment(screenshot: app.screenshot())
        detailAttachment.lifetime = .keepAlways
        add(detailAttachment)

        // Swipe left to navigate to next article
        app.swipeLeft()

        let swipedAttachment = XCTAttachment(screenshot: app.screenshot())
        swipedAttachment.lifetime = .keepAlways
        add(swipedAttachment)

        // Swipe right to return to previous article
        app.swipeRight()
    }
}
