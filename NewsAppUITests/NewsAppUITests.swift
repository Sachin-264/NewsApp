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

        let searchScreenshot = app.screenshot()
        let searchPath = "/Users/sonoma/.gemini/antigravity-ide/brain/4ae64ad1-fd1d-488e-8fc6-71ee7e8079bf/fast_search_screen.png"
        try? searchScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: searchPath))

        // Tap the search result to open detail
        galaxyArticle.tap()

        // Detail screen should load instantly with image
        let trendingLabel = app.staticTexts["Trending"]
        XCTAssertTrue(trendingLabel.waitForExistence(timeout: 5), "Detail screen should show Trending")

        sleep(1)
        let detailScreenshot = app.screenshot()
        let detailPath = "/Users/sonoma/.gemini/antigravity-ide/brain/4ae64ad1-fd1d-488e-8fc6-71ee7e8079bf/detail_screen_updated.png"
        try? detailScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: detailPath))

        // Swipe left to navigate to next article
        app.swipeLeft()
        sleep(1)
        let swipedScreenshot = app.screenshot()
        let swipedPath = "/Users/sonoma/.gemini/antigravity-ide/brain/4ae64ad1-fd1d-488e-8fc6-71ee7e8079bf/detail_swiped_updated.png"
        try? swipedScreenshot.pngRepresentation.write(to: URL(fileURLWithPath: swipedPath))

        // Swipe right to return to previous article
        app.swipeRight()
        sleep(1)
    }
}
