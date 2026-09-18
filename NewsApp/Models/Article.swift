import Foundation

struct Author: Codable, Hashable {
    let name: String
    let socials: [String: String]?
}

struct Article: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let url: String
    let imageUrl: String?
    let newsSite: String
    let summary: String
    let publishedAt: String
    let updatedAt: String?
    let featured: Bool?
    let authors: [Author]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case imageUrl = "image_url"
        case newsSite = "news_site"
        case summary
        case publishedAt = "published_at"
        case updatedAt = "updated_at"
        case featured
        case authors
    }

    var authorDisplayName: String {
        if let author = authors?.first?.name, !author.isEmpty {
            return author
        }
        return newsSite
    }

    var fallbackLocalImageName: String {
        let index = (abs(id) % 4) + 1
        return "news_local_\(index)"
    }

    var displaySummary: String {
        let clean = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.count > 50 && clean != "From the ESA Blogs." {
            return clean
        }
        return "This high-resolution space observation captured by \(newsSite) highlights significant developments in astronomical research and space exploration. The mission continues to deliver crucial scientific insights, capturing detailed telemetry and planetary imagery to advance our understanding of celestial phenomena."
    }
}
