import Testing
import Foundation
@testable import NewsApp

struct NewsAppTests {

    final class MockNewsAPIService: NewsAPIServiceProtocol {
        var articlesToReturn: [Article] = []
        var totalCount: Int = 0
        var shouldThrowError: Bool = false

        func fetchArticles(
            limit: Int,
            offset: Int,
            search: String?,
            newsSite: String?,
            ordering: String?
        ) async throws -> ArticleResponse {
            if shouldThrowError {
                throw NetworkError.requestFailed(NSError(domain: "test", code: 1))
            }
            let slice = Array(articlesToReturn.dropFirst(offset).prefix(limit))
            return ArticleResponse(
                count: totalCount > 0 ? totalCount : articlesToReturn.count,
                next: nil,
                previous: nil,
                results: slice
            )
        }

        func fetchArticle(id: Int) async throws -> Article {
            if let article = articlesToReturn.first(where: { $0.id == id }) {
                return article
            }
            throw NetworkError.invalidResponse(statusCode: 404)
        }
    }

    private func makeSampleArticle(id: Int, title: String = "Test Article") -> Article {
        Article(
            id: id,
            title: title,
            url: "https://example.com/\(id)",
            imageUrl: "https://example.com/image\(id).jpg",
            newsSite: "NASA",
            summary: "Sample summary for article \(id)",
            publishedAt: "2026-09-18T08:00:00Z",
            updatedAt: "2026-09-18T08:20:00Z",
            featured: false,
            authors: [Author(name: "John Doe", socials: nil)]
        )
    }

    @Test func testArticleJSONDecoding() throws {
        let json = """
        {
            "id": 101,
            "title": "Starship Launch Test",
            "url": "https://example.com/starship",
            "image_url": "https://example.com/image.jpg",
            "news_site": "SpaceNews",
            "summary": "Full summary of the Starship flight.",
            "published_at": "2026-09-18T08:00:00Z",
            "updated_at": "2026-09-18T08:20:00Z",
            "featured": true,
            "authors": [
                {
                    "name": "Jane Smith",
                    "socials": null
                }
            ]
        }
        """.data(using: .utf8)!

        let article = try JSONDecoder().decode(Article.self, from: json)

        #expect(article.id == 101)
        #expect(article.title == "Starship Launch Test")
        #expect(article.newsSite == "SpaceNews")
        #expect(article.authorDisplayName == "Jane Smith")
        #expect(article.featured == true)
    }

    @Test func testInitialLoadingSuccess() async {
        let mockService = MockNewsAPIService()
        mockService.articlesToReturn = [
            makeSampleArticle(id: 1, title: "Article 1"),
            makeSampleArticle(id: 2, title: "Article 2")
        ]
        mockService.totalCount = 2

        let viewModel = await NewsFeedViewModel(apiService: mockService)
        await viewModel.loadInitialArticles()

        let articles = await viewModel.articles
        let state = await viewModel.state

        #expect(articles.count == 2)
        #expect(state == .loaded)
    }

    @Test func testEmptyResultsState() async {
        let mockService = MockNewsAPIService()
        mockService.articlesToReturn = []
        mockService.totalCount = 0

        let viewModel = await NewsFeedViewModel(apiService: mockService)
        await viewModel.reloadArticles()

        let articles = await viewModel.articles
        let state = await viewModel.state

        #expect(articles.isEmpty)
        #expect(state == .empty)
    }

    @Test func testErrorState() async {
        let mockService = MockNewsAPIService()
        mockService.shouldThrowError = true

        let viewModel = await NewsFeedViewModel(apiService: mockService)
        await viewModel.reloadArticles()

        let state = await viewModel.state
        switch state {
        case .error:
            #expect(true)
        default:
            #expect(Bool(false), "Expected error state")
        }
    }

    @Test func testPaginationAppendsArticles() async {
        let mockService = MockNewsAPIService()
        mockService.articlesToReturn = (1...15).map { makeSampleArticle(id: $0, title: "Article \($0)") }
        mockService.totalCount = 15

        let viewModel = await NewsFeedViewModel(apiService: mockService)
        await viewModel.reloadArticles()

        var articles = await viewModel.articles
        #expect(articles.count == 10)

        if let last = articles.last {
            await viewModel.loadMoreArticlesIfNeeded(currentArticle: last)
        }

        articles = await viewModel.articles
        #expect(articles.count == 15)
    }

    @Test func testCategorySelectionTriggersReload() async {
        let mockService = MockNewsAPIService()
        mockService.articlesToReturn = [makeSampleArticle(id: 1, title: "ESA Mission")]

        let viewModel = await NewsFeedViewModel(apiService: mockService)
        await viewModel.selectCategory("ESA")

        let selected = await viewModel.selectedCategory
        #expect(selected == "ESA")
    }

    @Test func testDateFormattingExtension() {
        let isoDate = "2026-09-18T08:00:00Z"
        let formatted = isoDate.toFormattedDateString()
        #expect(!formatted.isEmpty)
        #expect(formatted != isoDate)
    }
}
