//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

struct SuggestionListView<Item: SuggestionItem>: View {
    var model: SuggestionListModel<Item>
    var onTap: (Item) -> Void

    init(_ model: SuggestionListModel<Item>, onTap: @escaping (Item) -> Void) {
        self.model = model
        self.onTap = onTap
    }

    var body: some View {
        List {
            ForEach(model.items) { item in
                Text(item.listingValue)
                    .font(.body)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        Color.accentColor
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .opacity(model.selectedId == item.id ? 1 : 0)
                    }
                    .onHover { hovering in
                        guard hovering else { return }
                        model.selectedId = item.id
                    }
                    .onTapGesture {
                        onTap(item)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
            }
        }
        .listStyle(.plain)
        .padding(.vertical, 8)
        .background(Color.clear)
        .frame(height: min(preferredHeight(forItemsCount: CGFloat(model.items.count)),
                           preferredHeight(forItemsCount: 5.5)))
        .scrollContentBackground(.hidden)
    }

    private func preferredHeight(forItemsCount count: CGFloat) -> CGFloat {
        let rect = "PLACEHOLDER".boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                                              options: [.usesLineFragmentOrigin, .usesFontLeading],
                                              attributes: [.font: NSFont.preferredFont(forTextStyle: .body)],
                                              context: nil)
        return (rect.height + (4 + 2) * 2) * count + 8 * 2
    }
}

#Preview {
    struct PreviewSuggestion: SuggestionItem {
        var id = UUID()
        var listingValue: String
        var completionValue: String?

        init(_ value: String) {
            self.listingValue = value
            self.completionValue = value
        }
    }

    return SuggestionListView(.init(items: [
        PreviewSuggestion("hoge"),
        PreviewSuggestion("hoge"),
        PreviewSuggestion("fuga"),
        PreviewSuggestion("fuga"),
        PreviewSuggestion("piyo"),
        PreviewSuggestion("piyo")
    ])) { suggestion in
        print("Tapped \(suggestion.listingValue)")
    }
}
