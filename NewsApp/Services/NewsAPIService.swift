import Foundation

final class NewsAPIService: NewsAPIServiceProtocol {
    static let shared = NewsAPIService()
    private let baseURLString = "https://api.spaceflightnewsapi.net/v4/articles/"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchArticles(
        limit: Int = 10,
        offset: Int = 0,
        search: String? = nil,
        newsSite: String? = nil,
        ordering: String? = nil
    ) async throws -> ArticleResponse {
        guard var components = URLComponents(string: baseURLString) else {
            print("❌ [API Error] Invalid base URL: \(baseURLString)")
            throw NetworkError.invalidURL
        }

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]

        if let search = search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        if let newsSite = newsSite, !newsSite.isEmpty, newsSite.lowercased() != "all" {
            queryItems.append(URLQueryItem(name: "news_site", value: newsSite))
        }

        if let ordering = ordering, !ordering.isEmpty {
            queryItems.append(URLQueryItem(name: "ordering", value: ordering))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            print("❌ [API Error] Could not construct URL from components")
            throw NetworkError.invalidURL
        }

        print("📡 [API Request] GET \(url.absoluteString)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            print("❌ [API Network Error] \(error.localizedDescription)")
            throw NetworkError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [API Error] Response is not HTTPURLResponse")
            throw NetworkError.invalidResponse(statusCode: -1)
        }

        print("📥 [API Response] HTTP Status: \(httpResponse.statusCode) | Payload: \(data.count) bytes")

        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ [API HTTP Error] Server returned error status \(httpResponse.statusCode)")
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(ArticleResponse.self, from: data)
            print("📦 [API Data] Total articles in database: \(decoded.count) | Batch count: \(decoded.results.count)")
            for (idx, article) in decoded.results.prefix(3).enumerated() {
                print("   📰 [Sample Article #\(idx + 1)] ID: \(article.id) | Title: '\(article.title)' | Site: \(article.newsSite)")
            }
            return decoded
        } catch {
            print("❌ [API Decoding Error] \(error)")
            throw NetworkError.decodingError(error)
        }
    }

    func fetchArticle(id: Int) async throws -> Article {
        guard let url = URL(string: "\(baseURLString)\(id)/") else {
            throw NetworkError.invalidURL
        }

        print("📡 [API Request Single] GET \(url.absoluteString)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            print("❌ [API Network Error] \(error.localizedDescription)")
            throw NetworkError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(statusCode: -1)
        }

        print("📥 [API Response Single] HTTP Status: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Article.self, from: data)
            print("📦 [API Data Single] Loaded article #\(decoded.id): '\(decoded.title)'")
            return decoded
        } catch {
            print("❌ [API Decoding Error Single] \(error)")
            throw NetworkError.decodingError(error)
        }
    }
}
