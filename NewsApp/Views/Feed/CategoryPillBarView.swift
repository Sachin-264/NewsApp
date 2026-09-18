import SwiftUI

struct CategoryPillBarView: View {
    let categories: [String]
    let selectedCategory: String
    let onSelectCategory: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    let isSelected = category.lowercased() == selectedCategory.lowercased()

                    Button(action: {
                        onSelectCategory(category)
                    }) {
                        Text(category)
                            .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? .white : .primary.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.appBlue : Color.appPillBackground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
