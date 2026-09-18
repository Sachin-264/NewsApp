import Foundation

protocol NewsAPIServiceProtocol {
    func fetchArticles(limit: Int, offset: Int, search: String?, newsSite: String?, ordering: String?) async throws -> ArticleResponse
    func fetchArticle(id: Int) async throws -> Article
}
