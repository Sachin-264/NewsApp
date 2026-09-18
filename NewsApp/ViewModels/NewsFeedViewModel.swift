import Foundation
import Combine

enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
}

enum NewsSortOrder: String, CaseIterable, Identifiable {
    case latest = "-published_at"
    case oldest = "published_at"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .latest:
            return "Latest First"
        case .oldest:
            return "Oldest First"
        }
    }
}

@MainActor
final class NewsFeedViewModel: ObservableObject {
    @Published private(set) var articles: [Article] = []
    @Published private(set) var state: ViewState = .loading
    @Published private(set) var isLoadingMore: Bool = false
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    @Published var selectedSortOrder: NewsSortOrder = .latest

    let availableCategories: [String] = [
        "All",
        "Sports",
        "Politics",
        "Technology",
        "Science",
        "Business"
    ]

    private let apiService: NewsAPIServiceProtocol
    private let pageSize = 20
    private var currentOffset = 0
    private var totalCount = 0

    private var categoryCache: [String: [Article]] = [:]
    private var categoryTotals: [String: Int] = [:]
    private var categoryOffsets: [String: Int] = [:]

    private var allArticlesCache: [Article] = []
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    var displayedArticles: [Article] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return articles
        }
        let query = trimmed.lowercased()
        return allArticlesCache.filter {
            $0.title.lowercased().contains(query) ||
            $0.summary.lowercased().contains(query) ||
            $0.newsSite.lowercased().contains(query)
        }
    }

    var hasMoreArticles: Bool {
        articles.count < totalCount
    }

    init(apiService: NewsAPIServiceProtocol? = nil) {
        self.apiService = apiService ?? NewsAPIService.shared
        setupInstantSearch()
    }

    private func setupInstantSearch() {
        $searchText
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                self.performFastSearch(query: query)
            }
            .store(in: &cancellables)
    }

    private func performFastSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            state = articles.isEmpty ? .empty : .loaded
            print("🔍 [Search Cleared] Showing current feed (\(articles.count) articles)")
            return
        }

        let localMatches = allArticlesCache.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.summary.localizedCaseInsensitiveContains(trimmed) ||
            $0.newsSite.localizedCaseInsensitiveContains(trimmed)
        }

        print("⚡ [Instant Search] Query: '\(trimmed)' | Instant memory matches: \(localMatches.count)")

        if !localMatches.isEmpty {
            self.state = .loaded
        }

        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }

            print("🌐 [Search API] Querying server for: '\(trimmed)'...")
            do {
                let response = try await self.apiService.fetchArticles(
                    limit: self.pageSize,
                    offset: 0,
                    search: trimmed,
                    newsSite: nil,
                    ordering: self.selectedSortOrder.rawValue
                )
                guard !Task.isCancelled else { return }

                self.mergeIntoCache(response.results)
                print("✅ [Search API Result] Server returned \(response.results.count) matching articles")

                if self.displayedArticles.isEmpty {
                    self.state = .empty
                } else {
                    self.state = .loaded
                }
            } catch {
                print("⚠️ [Search API Error] \(error.localizedDescription)")
                if self.displayedArticles.isEmpty {
                    self.state = .empty
                }
            }
        }
    }

    private func mergeIntoCache(_ newArticles: [Article]) {
        var existingIds = Set(allArticlesCache.map(\.id))
        for article in newArticles {
            if !existingIds.contains(article.id) {
                allArticlesCache.append(article)
                existingIds.insert(article.id)
            }
        }
    }

    private func apiSearchQuery(for category: String) -> String? {
        switch category.lowercased() {
        case "sports", "sport":
            return "sport"
        case "politics", "politic":
            return "politics"
        case "technology", "tech":
            return "technology"
        case "science":
            return "science"
        case "business":
            return "business"
        default:
            return nil
        }
    }

    func loadInitialArticles() async {
        guard articles.isEmpty else { return }
        self.state = .loading
        print("🚀 [ViewModel] Loading initial feed articles for '\(selectedCategory)'...")
        await fetchCategoryArticles(category: selectedCategory)
    }

    func selectCategory(_ category: String) {
        guard selectedCategory != category else { return }
        print("🏷️ [Category Selected] '\(category)'")
        selectedCategory = category

        if let cached = categoryCache[category], !cached.isEmpty {
            print("📦 [Category Cache Hit] Instantly displaying \(cached.count) cached articles for '\(category)'")
            self.articles = cached
            self.totalCount = categoryTotals[category] ?? cached.count
            self.currentOffset = categoryOffsets[category] ?? cached.count
            self.state = .loaded
        } else {
            print("⏳ [Category Cache Miss] '\(category)' not fetched yet. Showing skeleton loader...")
            self.articles = []
            self.state = .loading
            Task {
                await fetchCategoryArticles(category: category)
            }
        }
    }

    private func fetchCategoryArticles(category: String) async {
        currentOffset = 0
        if articles.isEmpty {
            self.state = .loading
        }
        let query = apiSearchQuery(for: category)
        do {
            let response = try await apiService.fetchArticles(
                limit: pageSize,
                offset: 0,
                search: query,
                newsSite: nil,
                ordering: selectedSortOrder.rawValue
            )
            self.totalCount = response.count
            self.articles = response.results
            self.currentOffset = response.results.count

            self.categoryCache[category] = response.results
            self.categoryTotals[category] = response.count
            self.categoryOffsets[category] = response.results.count

            self.mergeIntoCache(response.results)

            print("📰 [Category Loaded] Loaded \(response.results.count) articles for '\(category)'")

            if response.results.isEmpty {
                self.state = .empty
            } else {
                self.state = .loaded
            }
        } catch {
            print("❌ [Category Error] Failed to load '\(category)': \(error.localizedDescription)")
            self.state = .error(error.localizedDescription)
        }
    }

    func reloadArticles() async {
        categoryCache[selectedCategory] = nil
        articles = []
        state = .loading
        await fetchCategoryArticles(category: selectedCategory)
    }

    func refresh() async {
        print("🔄 [Pull-To-Refresh] User pulled to refresh. Clearing image cache and fetching newest articles for '\(selectedCategory)'...")
        ImageCache.shared.clearCache()
        categoryCache[selectedCategory] = nil
        currentOffset = 0
        let query = apiSearchQuery(for: selectedCategory)

        do {
            let response = try await apiService.fetchArticles(
                limit: pageSize,
                offset: 0,
                search: query,
                newsSite: nil,
                ordering: selectedSortOrder.rawValue
            )
            self.totalCount = response.count
            self.articles = response.results
            self.currentOffset = response.results.count

            self.categoryCache[selectedCategory] = response.results
            self.categoryTotals[selectedCategory] = response.count
            self.categoryOffsets[selectedCategory] = response.results.count

            self.mergeIntoCache(response.results)
            self.state = response.results.isEmpty ? .empty : .loaded
            print("✅ [Pull-To-Refresh Complete] Received \(response.results.count) fresh articles from API")
        } catch {
            print("❌ [Pull-To-Refresh Error] \(error.localizedDescription)")
            if articles.isEmpty {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    func loadMoreArticlesIfNeeded(currentArticle: Article) async {
        guard searchText.isEmpty else { return }
        guard !isLoadingMore, hasMoreArticles else { return }
        guard let currentIndex = articles.firstIndex(where: { $0.id == currentArticle.id }) else {
            return
        }

        let thresholdIndex = max(articles.count - 6, 0)
        guard currentIndex >= thresholdIndex else {
            return
        }

        print("📄 [Pagination] Pre-loading next batch from offset \(currentOffset) for '\(selectedCategory)'...")
        isLoadingMore = true
        let query = apiSearchQuery(for: selectedCategory)
        do {
            let response = try await apiService.fetchArticles(
                limit: pageSize,
                offset: currentOffset,
                search: query,
                newsSite: nil,
                ordering: selectedSortOrder.rawValue
            )
            var existingIds = Set(self.articles.map(\.id))
            var appendedArticles: [Article] = []
            for article in response.results {
                if !existingIds.contains(article.id) {
                    existingIds.insert(article.id)
                    appendedArticles.append(article)
                }
            }
            if !appendedArticles.isEmpty {
                self.articles.append(contentsOf: appendedArticles)
                self.mergeIntoCache(appendedArticles)
            }
            self.currentOffset += response.results.count
            self.totalCount = response.count

            self.categoryCache[selectedCategory] = self.articles
            self.categoryOffsets[selectedCategory] = self.currentOffset
            self.categoryTotals[selectedCategory] = self.totalCount

            print("✅ [Pagination Complete] Total articles for '\(selectedCategory)': \(self.articles.count) of \(self.totalCount)")
        } catch {
            print("❌ [Pagination Error] Failed: \(error.localizedDescription)")
        }
        isLoadingMore = false
    }

    func selectSortOrder(_ sort: NewsSortOrder) {
        guard selectedSortOrder != sort else { return }
        print("📊 [Sort Order Selected] '\(sort.title)'")
        selectedSortOrder = sort
        categoryCache.removeAll()
        Task {
            await reloadArticles()
        }
    }
}
