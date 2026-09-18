import SwiftUI

struct NewsFeedView: View {
    @StateObject private var viewModel = NewsFeedViewModel()
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedArticle: Article? = nil

    private var gridColumns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        } else {
            return [GridItem(.flexible())]
        }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 16) {
                    VStack(spacing: 16) {
                        FeedHeaderView()
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        if !networkMonitor.isConnected {
                            HStack(spacing: 8) {
                                Image(systemName: "wifi.slash")
                                    .font(.system(size: 13, weight: .bold))
                                Text("You're offline • Showing cached news")
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        FeedSearchBarView(
                            text: $viewModel.searchText,
                            selectedSort: $viewModel.selectedSortOrder,
                            onSortChange: { _ in }
                        )
                        .padding(.horizontal, 20)

                        CategoryPillBarView(
                            categories: viewModel.availableCategories,
                            selectedCategory: viewModel.selectedCategory,
                            onSelectCategory: { category in
                                viewModel.selectCategory(category)
                            }
                        )
                        .padding(.leading, 20)
                    }
                    .transaction { $0.animation = nil }

                    Divider()
                        .padding(.horizontal, 20)

                    Group {
                        if viewModel.displayedArticles.isEmpty && (viewModel.state == .loading || viewModel.state == .idle) {
                            NewsFeedSkeletonView()
                        } else {
                            switch viewModel.state {
                            case .error(let message) where viewModel.displayedArticles.isEmpty:
                                ErrorBannerView(message: message) {
                                    Task {
                                        await viewModel.reloadArticles()
                                    }
                                }

                            case .empty where viewModel.displayedArticles.isEmpty:
                                EmptyStateView(
                                    title: "No Articles Found",
                                    subtitle: "Try searching with different keywords or switch categories."
                                ) {
                                    Task {
                                        viewModel.searchText = ""
                                        viewModel.selectCategory("All")
                                    }
                                }

                            default:
                            ScrollView {
                                LazyVGrid(columns: gridColumns, spacing: 14) {
                                    ForEach(viewModel.displayedArticles) { article in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                selectedArticle = article
                                            }
                                        }) {
                                            ArticleCardView(article: article)
                                                .onAppear {
                                                    Task {
                                                        await viewModel.loadMoreArticlesIfNeeded(currentArticle: article)
                                                    }
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 4)

                                if viewModel.isLoadingMore {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                        Text("Loading more articles...")
                                            .font(.footnote)
                                            .foregroundColor(.appSecondaryText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                }
                            }
                            .refreshable {
                                await viewModel.refresh()
                            }
                        }
                    }
                    }
                    .transaction { $0.animation = nil }
                }
                .navigationBarHidden(true)
                .background(Color.appCardBackground)
                .task {
                    await viewModel.loadInitialArticles()
                }
                .onChange(of: networkMonitor.isConnected) { connected in
                    if connected && viewModel.articles.isEmpty {
                        Task {
                            await viewModel.loadInitialArticles()
                        }
                    }
                }
            }

            if let article = selectedArticle {
                ArticleDetailPagerView(
                    initialArticle: article,
                    viewModel: viewModel,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedArticle = nil
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .bottom)
                ))
                .zIndex(100)
            }
        }
    }
}
