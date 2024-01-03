//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

struct SuggestionListView<Item: SuggestionItem>: View {
    enum RowID: Hashable {
        case fallback
        case item(Item.ID)
    }

    @ObservedObject var model: SuggestionListModel<Item>
    var onTap: (SuggestionListModel<Item>.Selection) -> Void
    var fallbackItemTitle: (String) -> String

    init(_ model: SuggestionListModel<Item>,
         onTap: @escaping (SuggestionListModel<Item>.Selection) -> Void,
         fallbackItemTitle: @escaping (String) -> String)
    {
        self.model = model
        self.onTap = onTap
        self.fallbackItemTitle = fallbackItemTitle
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if let fallbackItemSource = model.fallbackItem {
                    Text(fallbackItemTitle(fallbackItemSource))
                        .font(.body)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            Color.accentColor
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .opacity(model.selection?.isFallback == true ? 1 : 0)
                        }
                        .onHover { hovering in
                            guard hovering else { return }
                            model.selection = .fallback
                        }
                        .onTapGesture {
                            onTap(.fallback)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
                        .id(RowID.fallback)
                }

                ForEach(model.items) { item in
                    Text(item.title)
                        .font(.body)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            Color.accentColor
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .opacity(model.selection?.itemId == item.id ? 1 : 0)
                        }
                        .onHover { hovering in
                            guard hovering else { return }
                            model.selection = .item(item.id)
                        }
                        .onTapGesture {
                            onTap(.item(item.id))
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
                        .id(RowID.item(item.id))
                }
            }
            .listStyle(.plain)
            .padding(.vertical, 8)
            .background(Color.clear)
            .frame(height: min(preferredHeight(forItemsCount: CGFloat(model.items.count) + (model.fallbackItem != nil ? 1 : 0)),
                               preferredHeight(forItemsCount: 5.5)))
            .scrollContentBackground(.hidden)
            .onChange(of: model.selection, initial: true) { _, newValue in
                switch newValue {
                case .fallback: proxy.scrollTo(RowID.fallback)
                case let .item(id): proxy.scrollTo(RowID.item(id))
                case .none: break
                }
            }
        }
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
        var title: String

        init(_ value: String) {
            self.title = value
        }
    }

    let model = SuggestionListModel<PreviewSuggestion>(items: [
        PreviewSuggestion("hoge"),
        PreviewSuggestion("fuga"),
        PreviewSuggestion("piyo"),
        PreviewSuggestion("puyo"),
        PreviewSuggestion("poyo"),
        PreviewSuggestion("poe")
    ])
    model.fallbackItem = "Fallback"

    return SuggestionListView(model) { suggestion in
        print("Tapped \(suggestion)")
    } fallbackItemTitle: { text in
        "\(text)を追加"
    }
}
