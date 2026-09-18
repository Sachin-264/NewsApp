import SwiftUI

struct ArticleCardView: View {
    let article: Article

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ArticleImageView(
                urlString: article.imageUrl,
                publisherName: article.newsSite
            )
            .frame(width: 104, height: 104)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(article.newsSite)
                    .font(.newsMeta())
                    .foregroundColor(.appSecondaryText)

                Text(article.title)
                    .font(.newsHeadline())
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.appBlue.opacity(0.15))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text(String(article.authorDisplayName.prefix(1)).uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.appBlue)
                        )

                    Text(article.authorDisplayName)
                        .font(.newsCaption())
                        .fontWeight(.medium)
                        .foregroundColor(.primary.opacity(0.75))
                        .lineLimit(1)

                    Text("•")
                        .font(.newsCaption())
                        .foregroundColor(.appSecondaryText)

                    Text(article.publishedAt.toFormattedDateString())
                        .font(.newsCaption())
                        .foregroundColor(.appSecondaryText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 104)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
