import SwiftUI

struct ArticleDetailContentView: View {
  let article: Article
  let onBack: () -> Void

  @State private var showSafari = false
  @State private var isBookmarked = false
  @State private var showShareSheet = false

  private var topBarPadding: CGFloat {
    let windowInset =
      UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: { $0.isKeyWindow })?
      .safeAreaInsets.top ?? 0

    if windowInset >= 59 {
      return 56
    } else if windowInset >= 44 {
      return 48
    } else {
      return 24
    }
  }

  var body: some View {
    GeometryReader { proxy in
      let heroHeight = max(proxy.size.height * 0.50, 360)

      ZStack(alignment: .top) {
        Color.black
          .ignoresSafeArea()

        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
              ArticleImageView(
                urlString: article.imageUrl,
                publisherName: article.newsSite
              )
              .frame(width: proxy.size.width, height: heroHeight)
              .clipped()

              LinearGradient(
                gradient: Gradient(stops: [
                  .init(color: Color.black.opacity(0.65), location: 0.0),
                  .init(color: Color.black.opacity(0.2), location: 0.22),
                  .init(color: Color.clear, location: 0.38),
                  .init(color: Color.black.opacity(0.55), location: 0.60),
                  .init(color: Color.black.opacity(0.85), location: 0.80),
                  .init(color: Color.black.opacity(0.96), location: 1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
              )
              .frame(width: proxy.size.width, height: heroHeight)

              VStack(alignment: .leading, spacing: 10) {
                Text(article.newsSite)
                  .font(.inter(.bold, size: 12))
                  .foregroundColor(.white)
                  .padding(.horizontal, 14)
                  .padding(.vertical, 6)
                  .background(Color.appBlue)
                  .clipShape(Capsule())

                Text(article.title)
                  .font(.inter(.bold, size: 22))
                  .foregroundColor(.white)
                  .lineLimit(3)
                  .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                  Text("Trending")
                    .font(.inter(.medium, size: 13))
                    .foregroundColor(.white.opacity(0.85))

                  Text("•")
                    .foregroundColor(.white.opacity(0.7))

                  Text(article.publishedAt.toRelativeTimeString())
                    .font(.inter(.regular, size: 13))
                    .foregroundColor(.white.opacity(0.85))
                }
              }
              .padding(.horizontal, 20)
              .padding(.bottom, 50)
            }
            .frame(width: proxy.size.width, height: heroHeight)

            VStack(alignment: .leading, spacing: 20) {
              HStack(spacing: 12) {
                Circle()
                  .fill(Color.red.opacity(0.9))
                  .frame(width: 44, height: 44)
                  .overlay(
                    Text(String(article.newsSite.prefix(3)).uppercased())
                      .font(.system(size: 12, weight: .black))
                      .foregroundColor(.white)
                  )
                Text(article.newsSite)
                  .font(.inter(.bold, size: 18))
                  .foregroundColor(.black)

                Image(systemName: "checkmark.seal.fill")
                  .font(.system(size: 16))
                  .foregroundColor(.appBlue)

                Spacer()
              }

              if !article.authorDisplayName.isEmpty && article.authorDisplayName != article.newsSite
              {
                HStack(spacing: 6) {
                  Text("Reported by")
                    .font(.inter(.regular, size: 13))
                    .foregroundColor(Color(white: 0.45))
                  Text(article.authorDisplayName)
                    .font(.inter(.semiBold, size: 13))
                    .foregroundColor(.black)
                }
              }

              Text(article.displaySummary)
                .font(.inter(.regular, size: 16))
                .lineSpacing(8)
                .foregroundColor(Color(white: 0.15))

              if URL(string: article.url) != nil {
                Button(action: { showSafari = true }) {
                  HStack(spacing: 6) {
                    Text("Read full coverage on \(article.newsSite)")
                      .font(.inter(.semiBold, size: 15))
                    Image(systemName: "arrow.up.right")
                      .font(.system(size: 13, weight: .bold))
                  }
                  .foregroundColor(.appBlue)
                  .padding(.top, 4)
                }
              }

              Spacer(minLength: 50)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: proxy.size.height * 0.55)
            .padding(24)
            .background(
              Color.white
                .clipShape(RoundedCornerShape(radius: 28, corners: [.topLeft, .topRight]))
                .padding(.bottom, -1000)
            )
            .padding(.top, -24)
          }
        }

        // Floating Top Bar: Anchored directly below Dynamic Island / Notch
        HStack {
          Button(action: onBack) {
            Image(systemName: "chevron.left")
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(.white)
              .frame(width: 42, height: 42)
              .background(Color.black.opacity(0.35))
              .clipShape(Circle())
          }

          Spacer()

          if !NetworkMonitor.shared.isConnected {
            HStack(spacing: 5) {
              Image(systemName: "wifi.slash")
                .font(.system(size: 11, weight: .bold))
              Text("Offline")
                .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())

            Spacer()
          }

          HStack(spacing: 12) {
            Button(action: { isBookmarked.toggle() }) {
              Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(Color.black.opacity(0.35))
                .clipShape(Circle())
            }

            Menu {
              Button(action: { showShareSheet = true }) {
                Label("Share Story", systemImage: "square.and.arrow.up")
              }
              if let url = URL(string: article.url) {
                Link(destination: url) {
                  Label("Open in Safari", systemImage: "safari")
                }
              }
            } label: {
              Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(Color.black.opacity(0.35))
                .clipShape(Circle())
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, topBarPadding)
      }
      .sheet(isPresented: $showSafari) {
        if let url = URL(string: article.url) {
          SafariView(url: url)
            .edgesIgnoringSafeArea(.bottom)
        }
      }
      .sheet(isPresented: $showShareSheet) {
        if let url = URL(string: article.url) {
          ActivityView(activityItems: [article.title, url])
        }
      }
    }
    .ignoresSafeArea()
  }
}

struct RoundedCornerShape: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

struct ActivityView: UIViewControllerRepresentable {
  let activityItems: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
