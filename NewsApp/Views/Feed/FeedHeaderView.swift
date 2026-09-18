import SwiftUI

struct FeedHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Discover")
                .font(.newsLargeTitle())
                .foregroundColor(.primary)

            Text("News from all around the world")
                .font(.newsSubheadline())
                .foregroundColor(.appSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
