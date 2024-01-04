//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Combine
import SwiftUI

public final class SuggestTextFieldCoordinator<Item: SuggestionItem>: NSObject, NSTextFieldDelegate {
    private let model: SuggestionListModel<Item>

    var textField: NSTextField?
    var suggestions: (String) -> [Item]
    var fallbackItemTitle: (String) -> String
    var onSelect: (SuggestionListSelection<Item>) -> Void
    var cancellable: AnyCancellable?

    private var windowController: SuggestionListWindowController<Item>?
    private var skipNextCompletion = false

    init(suggestions: @escaping (String) -> [Item],
         fallback: @escaping (String) -> String,
         onSelect: @escaping (SuggestionListSelection<Item>) -> Void)
    {
        self.model = .init(items: suggestions(""))
        self.suggestions = suggestions
        self.fallbackItemTitle = fallback
        self.onSelect = onSelect

        super.init()

        cancellable = model.$selection
            .sink { [weak self] newValue in
                guard let fieldEditor = self?.textField?.currentEditor() else { return }
                switch newValue {
                case let .item(item):
                    self?.updateFieldEditor(fieldEditor, withSuggestion: item.title)

                case .fallback:
                    if let fallbackItemSource = self?.model.fallbackItem {
                        self?.updateFieldEditor(fieldEditor, withSuggestion: fallbackItemSource)
                    }

                case .none:
                    self?.updateFieldEditor(fieldEditor, withSuggestion: nil)
                }
            }
    }

    public func controlTextDidBeginEditing(_ obj: Notification) {
        if windowController == nil {
            windowController = SuggestionListWindowController<Item>(model) { [weak self] suggest in
                guard let self else { return }
                if let selection = self.model.listSelection {
                    onSelect(selection)
                }
                self.textField?.validateEditing()
                self.textField?.abortEditing()
                self.textField?.stringValue = ""
                self.windowController?.hideSuggestList()
            } fallbackItemTitle: { [weak self] text in
                self?.fallbackItemTitle(text) ?? ""
            }
        }

        updateSuggestions()
    }

    public func controlTextDidChange(_ obj: Notification) {
        updateSuggestions()
    }

    public func controlTextDidEndEditing(_ obj: Notification) {
        if let selection = model.listSelection {
            onSelect(selection)
        }
        textField?.stringValue = ""
        windowController?.hideSuggestList()
    }

    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            windowController?.moveUp(textView)
            return true
        }

        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            windowController?.moveDown(textView)
            return true
        }

        if commandSelector == #selector(NSResponder.deleteForward(_:)) || commandSelector == #selector(NSResponder.deleteBackward(_:)) {
            let insertionRange = textView.selectedRanges[0].rangeValue
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                skipNextCompletion = (insertionRange.location != 0 || insertionRange.length > 0)
            } else {
                skipNextCompletion = (insertionRange.location != textView.string.count || insertionRange.length > 0)
            }
            return false
        }

        if commandSelector == #selector(NSResponder.complete(_:)) {
            return true
        }

        return false
    }

    // MARK: - Privates

    private func updateFieldEditor(_ fieldEditor: NSText, withSuggestion suggestion: String?) {
        guard let suggestion else { return }
        let selection = NSRange(location: fieldEditor.selectedRange.location, length: suggestion.count)
        fieldEditor.string = suggestion
        fieldEditor.selectedRange = selection
    }

    private func updateSuggestions() {
        guard let textField, let fieldEditor = textField.currentEditor() else { return }

        // キャレット位置までのテキストを利用する
        let text = fieldEditor.selectedRange.length == 0 ? fieldEditor.string : (fieldEditor.string as NSString).substring(to: fieldEditor.selectedRange.location)

        let items = suggestions(text)

        if !text.isEmpty && (
            // 候補がなければ、フォールバックを表示
            items.isEmpty
                // 補完を停止中、かつ候補に合致するものがなければ、フォールバックを表示
                || (skipNextCompletion && items.first?.title != text)
                // caseの違いなどにより候補の先頭とprefixが不一致だった場合、フォールバックを表示
                || items.first?.title.hasPrefix(text) == false
        ) {
            model.fallbackItem = text
            model.selection = .fallback
        } else {
            model.fallbackItem = nil
            model.selection = text.isEmpty ? nil : items.first.flatMap({ .item($0) })
        }

        model.items = items
        skipNextCompletion = false

        windowController?.showSuggestList(for: textField)
    }
}

public struct SuggestTextField<Item: SuggestionItem>: NSViewRepresentable {
    public typealias NSViewType = NSTextField
    public typealias Coordinator = SuggestTextFieldCoordinator<Item>

    let placeholder: String?
    let suggestions: (String) -> [Item]
    let fallbackItemTitle: (String) -> String
    let onSelect: (SuggestionListSelection<Item>) -> Void

    public init(placeholder: String? = nil,
                suggestions: @escaping (String) -> [Item],
                fallbackItemTitle: @escaping (String) -> String,
                onSelect: @escaping (SuggestionListSelection<Item>) -> Void)
    {
        self.placeholder = placeholder
        self.suggestions = suggestions
        self.fallbackItemTitle = fallbackItemTitle
        self.onSelect = onSelect
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(suggestions: suggestions, fallback: fallbackItemTitle, onSelect: onSelect)
    }

    public func makeNSView(context: Context) -> NSViewType {
        let textField = NSTextField()
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.focusRingType = .none
        textField.isAutomaticTextCompletionEnabled = true
        context.coordinator.textField = textField
        return textField
    }

    public func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.placeholderString = placeholder
        context.coordinator.suggestions = suggestions
        context.coordinator.fallbackItemTitle = fallbackItemTitle
    }
}

public struct Sugg<Item: SuggestionItem> {
    var suggestions: [Item]
}

#Preview {
    struct Item: SuggestionItem {
        let id = UUID()
        var title: String

        init(_ value: String) {
            self.title = value
        }
    }

    let store: [Item] = [
        .init("hoge"),
        .init("hogehoge"),
        .init("fuga"),
        .init("fugafuga"),
    ]

    return SuggestTextField<Item>(placeholder: "タグを追加") { text in
        guard !text.isEmpty else {
            return store
        }

        return store
            .filter({ $0.title.hasPrefix(text) })
    } fallbackItemTitle: { text in
        "\(text)を新たに作成"
    } onSelect: { value in
        print("Selected: \(value)")
    }
    .padding()
}
