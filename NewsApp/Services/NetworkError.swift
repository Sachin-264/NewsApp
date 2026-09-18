import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingError(Error)
    case requestFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The requested URL is invalid."
        case .invalidResponse(let code):
            return "Server responded with status code \(code)."
        case .decodingError(let error):
            return "Failed to process news data: \(error.localizedDescription)"
        case .requestFailed(let error):
            return error.localizedDescription
        }
    }
}
