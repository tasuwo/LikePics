//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Combine
import SwiftUI

public final class SuggestTextFieldCoordinator<Item: SuggestionItem>: NSObject, NSTextFieldDelegate {
    private let model: SuggestionListModel<Item>

    var textField: NSTextField?
    var suggestions: (String) -> [Item]
    var fallback: (String) -> Item
    var onSelect: (String) -> Void

    private var windowController: SuggestionListWindowController<Item>?
    private var skipNextCompletion = false

    private var inputs: CurrentValueSubject<Void, Never> = .init(())
    private var cancellable: AnyCancellable?

    init(suggestions: @escaping (String) -> [Item],
         fallback: @escaping (String) -> Item,
         onSelect: @escaping (String) -> Void)
    {
        self.model = .init(items: suggestions(""))
        self.suggestions = suggestions
        self.fallback = fallback
        self.onSelect = onSelect

        super.init()

        cancellable = inputs
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateSuggestions()
            }

        model.observe(\.selectedId) { [weak self] _, newValue in
            guard let fieldEditor = self?.textField?.currentEditor() else { return }
            // TODO: パフォーマンス向上
            if let suggestion = self?.model.items.first(where: { $0.id == newValue }) {
                self?.updateFieldEditor(fieldEditor, withSuggestion: suggestion.completionValue)
            } else {
                self?.updateFieldEditor(fieldEditor, withSuggestion: nil)
            }
        }
    }

    public func controlTextDidBeginEditing(_ obj: Notification) {
        if windowController == nil {
            windowController = SuggestionListWindowController<Item>(model) { [weak self] suggest in
                guard let self else { return }
                if let stringValue = self.textField?.stringValue, !stringValue.isEmpty {
                    onSelect(stringValue)
                }
                self.textField?.validateEditing()
                self.textField?.abortEditing()
                self.textField?.stringValue = ""
                self.windowController?.hideSuggestList()
            }
        }

        updateSuggestions()
    }

    public func controlTextDidChange(_ obj: Notification) {
        inputs.send(())
    }

    public func controlTextDidEndEditing(_ obj: Notification) {
        if let stringValue = self.textField?.stringValue, !stringValue.isEmpty {
            onSelect(stringValue)
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

        var items = suggestions(text)
        if !text.isEmpty {
            if items.isEmpty {
                // 候補がなければ、フォールバックを表示
                items.insert(fallback(text), at: 0)
            } else if skipNextCompletion, items.first?.listingValue != text {
                // 補完を停止中、かつ候補に合致するものがなければ、フォールバックを表示
                items.insert(fallback(text), at: 0)
            } else if items.first?.listingValue.hasPrefix(text) == false {
                // caseの違いなどにより候補の先頭とprefixが不一致だった場合、フォールバックを表示
                items.insert(fallback(text), at: 0)
            }
        }

        self.model.items = items
        self.model.selectedId = text.isEmpty ? nil : items.first?.id
        self.skipNextCompletion = false

        self.windowController?.showSuggestList(for: textField)
    }
}

public struct SuggestTextField<Item: SuggestionItem>: NSViewRepresentable {
    public typealias NSViewType = NSTextField
    public typealias Coordinator = SuggestTextFieldCoordinator<Item>

    let placeholder: String?
    let suggestions: (String) -> [Item]
    let fallback: (String) -> Item
    let onSelect: (String) -> Void

    public init(placeholder: String? = nil,
                suggestions: @escaping (String) -> [Item],
                fallback: @escaping (String) -> Item,
                onSelect: @escaping (String) -> Void)
    {
        self.placeholder = placeholder
        self.suggestions = suggestions
        self.fallback = fallback
        self.onSelect = onSelect
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(suggestions: suggestions, fallback: fallback, onSelect: onSelect)
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
        context.coordinator.fallback = fallback
    }
}

public struct Sugg<Item: SuggestionItem> {
    var suggestions: [Item]
}

#Preview {
    struct Item: SuggestionItem {
        let id = UUID()
        var listingValue: String
        var completionValue: String?

        init(_ value: String) {
            self.listingValue = value
            self.completionValue = value
        }

        init(listingValue: String, completionValue: String?) {
            self.listingValue = listingValue
            self.completionValue = completionValue
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
            .filter({ $0.listingValue.contains(text) })
    } fallback: { text in
        Item(listingValue: "\(text)を新たに作成", completionValue: nil)
    } onSelect: { value in
        print("Selected: \(value)")
    }
    .padding()
}
