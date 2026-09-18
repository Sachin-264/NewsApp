import SwiftUI

struct FeedSearchBarView: View {
    @Binding var text: String
    @Binding var selectedSort: NewsSortOrder
    let onSortChange: (NewsSortOrder) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.appSecondaryText)
                .font(.system(size: 18, weight: .medium))

            TextField("Search", text: $text)
                .font(.system(size: 16))
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Menu {
                Picker("Sort Articles", selection: $selectedSort) {
                    ForEach(NewsSortOrder.allCases) { sort in
                        Text(sort.title).tag(sort)
                    }
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.primary)
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 32, height: 32)
            }
            .onChange(of: selectedSort) { newSort in
                onSortChange(newSort)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appPillBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
