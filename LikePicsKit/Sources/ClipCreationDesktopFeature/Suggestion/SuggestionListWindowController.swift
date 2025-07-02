//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

final class SuggestionListWindowController<Item: SuggestionItem>: NSWindowController {
    private let model: SuggestionListModel<Item>
    private let onTap: (SuggestionListModel<Item>.Selection) -> Void
    private let fallbackItemTitle: (String) -> String

    private var suggestListView: NSView?
    private var localMouseDownEventMonitor: Any?
    private var lostFocusObserver: Any?

    init(
        _ model: SuggestionListModel<Item>,
        onTap: @escaping (SuggestionListModel<Item>.Selection) -> Void,
        fallbackItemTitle: @escaping (String) -> String
    ) {
        self.model = model
        self.onTap = onTap
        self.fallbackItemTitle = fallbackItemTitle

        let contentRec = NSRect(x: 0, y: 0, width: 20, height: 20)
        let window = SuggestionListWindow(contentRect: contentRec, defer: true)
        super.init(window: window)

        let contentView = SuggestionListWindowBaseView(frame: contentRec)
        window.contentView = contentView
        contentView.autoresizesSubviews = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func showSuggestList(for parentTextField: NSTextField) {
        let suggestListWindow: NSWindow? = window
        let parentWindow: NSWindow? = parentTextField.window
        let parentFrame: NSRect = parentTextField.frame
        var suggestListFrame: NSRect? = suggestListWindow?.frame
        suggestListFrame?.size.width = parentFrame.size.width

        // サジェストウインドウをテキストフィールドの直下に配置する
        var location = parentTextField.superview?.convert(parentFrame.origin, to: nil)
        location = parentWindow?.convertToScreen(NSRect(x: location!.x, y: location!.y, width: 0, height: 0)).origin
        location?.y -= 2.0

        suggestListWindow?.setFrame(suggestListFrame ?? NSRect.zero, display: false)
        suggestListWindow?.setFrameTopLeftPoint(location ?? NSPoint.zero)

        if let contentView = window?.contentView {
            self.suggestListView?.removeFromSuperview()
            self.suggestListView = nil

            let view = NSHostingView(rootView: SuggestionListView(model, onTap: onTap, fallbackItemTitle: fallbackItemTitle))
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)

            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: contentView.topAnchor),
                view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])

            self.suggestListView = view
        }

        if let window {
            parentWindow?.addChildWindow(window, ordered: .above)
        }

        // アプリ内で別の場所がクリックされたら、サジェストを閉じる
        localMouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            guard let self, self.window?.isVisible == true else { return event }

            // マウスイベントがサジェストウインドウ内のものであれば、何もしない
            guard event.window != suggestListWindow else { return event }

            if event.window == parentWindow {
                guard let parentWindow, let contentView = parentWindow.contentView else {
                    self.hideSuggestList()
                    return event
                }

                let locationTest = contentView.convert(event.locationInWindow, from: nil)
                let hitView = contentView.hitTest(
                    .init(
                        x: locationTest.x,
                        // タイトルバー分の高さを除く
                        y: locationTest.y - (contentView.frame.height - parentWindow.contentLayoutRect.size.height)
                    )
                )

                let fieldEditor: NSText? = parentTextField.currentEditor()
                if hitView != parentTextField, let fieldEditor, hitView != fieldEditor {
                    // TextField外をクリックしたら、サジェストを閉じる
                    self.hideSuggestList()
                    return event
                }
            } else {
                // サジェストウインドウを表示しているウインドウとは別のウインドウをタップしていたら、サジェストを閉じる
                self.hideSuggestList()
            }

            return event
        }

        // アプリ外がクリックされたら、サジェストを閉じる
        lostFocusObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: parentWindow, queue: nil) { [weak self] _ in
            self?.hideSuggestList()
        }
    }

    func hideSuggestList() {
        if let window {
            if window.isVisible {
                window.parent?.removeChildWindow(window)
            }
            // これを削除の前にやると親Windowも非表示にされてしまうので、このタイミングで実施する
            window.orderOut(nil)
        }

        suggestListView?.removeFromSuperview()
        suggestListView = nil

        if let lostFocusObserver {
            NotificationCenter.default.removeObserver(lostFocusObserver)
            self.lostFocusObserver = nil
        }

        if let localMouseDownEventMonitor {
            NSEvent.removeMonitor(localMouseDownEventMonitor)
            self.localMouseDownEventMonitor = nil
        }
    }

    override func moveUp(_ sender: Any?) {
        guard window?.isVisible == true else { return }
        model.moveSelectonUp()
    }

    override func moveDown(_ sender: Any?) {
        guard window?.isVisible == true else { return }
        model.moveSelectionDown()
    }
}
