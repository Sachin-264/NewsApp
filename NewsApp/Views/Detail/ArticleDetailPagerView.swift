import SwiftUI

struct ArticleDetailPagerView: View {
    let initialArticle: Article
    @ObservedObject var viewModel: NewsFeedViewModel
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var selectedArticleId: Int = 0

    private var currentArticles: [Article] {
        let list = viewModel.displayedArticles
        return list.isEmpty ? viewModel.articles : list
    }

    private func handleDismiss() {
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    var body: some View {
        TabView(selection: $selectedArticleId) {
            ForEach(currentArticles) { article in
                ArticleDetailContentView(
                    article: article,
                    onBack: {
                        handleDismiss()
                    }
                )
                .tag(article.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .onAppear {
            selectedArticleId = initialArticle.id
            if let index = currentArticles.firstIndex(where: { $0.id == initialArticle.id }) {
                prefetchAdjacentImages(around: index)
            }
        }
        .onChange(of: selectedArticleId) { newId in
            guard let index = currentArticles.firstIndex(where: { $0.id == newId }) else { return }
            let article = currentArticles[index]
            prefetchAdjacentImages(around: index)
            Task {
                await viewModel.loadMoreArticlesIfNeeded(currentArticle: article)
            }
        }
    }

    private func prefetchAdjacentImages(around index: Int) {
        let adjacentIndices = [index - 1, index + 1, index + 2]
        for idx in adjacentIndices {
            if idx >= 0 && idx < currentArticles.count {
                ImageCache.shared.prefetch(urlString: currentArticles[idx].imageUrl)
            }
        }
    }
}
