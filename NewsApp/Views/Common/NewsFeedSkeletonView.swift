import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color.white.opacity(0.35), location: 0.5),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .offset(x: phase * geo.size.width * 2)
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .mask(content)
            .onAppear {
                phase = 1.0
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct SkeletonArticleCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .systemGray5))
                .frame(width: 104, height: 104)
                .shimmer()

            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 65, height: 12)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 16)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 170, height: 16)
                    .shimmer()

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 20, height: 20)
                        .shimmer()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 110, height: 12)
                        .shimmer()
                }
            }
            .frame(height: 104)
        }
        .padding(.vertical, 6)
    }
}

struct NewsFeedSkeletonView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonArticleCard()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
    }
}
