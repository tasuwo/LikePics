//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

extension View {
    func nsContextMenu(menuItems: () -> [NSMenuItem]) -> some View {
        modifier(NSContextMenu(menuItems: menuItems()))
    }
}

private struct NSContextMenu: ViewModifier {
    let menuItems: [NSMenuItem]

    func body(content: Content) -> some View {
        content
            .overlay {
                ContextMenuView {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } menuItems: {
                    return menuItems
                }
                .allowsHitTesting(false)
            }
    }
}

private struct ContextMenuView<Content: View>: NSViewRepresentable {
    final class EventMonitorCoordinator {
        var monitoring: Any? {
            willSet {
                guard let monitoring else { return }
                NSEvent.removeMonitor(monitoring)
            }
        }

        deinit {
            guard let monitoring else { return }
            NSEvent.removeMonitor(monitoring)
        }
    }

    @ViewBuilder
    let content: () -> Content
    let menuItems: () -> [NSMenuItem]

    func makeCoordinator() -> EventMonitorCoordinator {
        return EventMonitorCoordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let hostingView = NSHostingView(rootView: content())
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let view = NSView()
        view.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        context.coordinator.monitoring = NSEvent.addLocalMonitorForEvents(matching: .rightMouseUp) { event in
            let eventLocation = event.locationInWindow
            let convertedLocation = view.convert(eventLocation, from: nil)

            if view.bounds.contains(convertedLocation) {
                let menu = NSMenu()
                menu.items = menuItems()
                menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
            }

            return event
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView.subviews.compactMap({ $0 as? NSHostingView<Content> }).first else { return }
        view.rootView = content()
    }
}

private var associatedKey = "NSMenuItem.AssociatedKey"

extension NSMenuItem {
    private var _action: (() -> Void)? {
        get {
            return withUnsafePointer(to: &associatedKey) { key in
                objc_getAssociatedObject(self, key) as? () -> Void
            }
        }
        set {
            withUnsafePointer(to: &associatedKey) { key in
                objc_setAssociatedObject(self, key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    convenience init(title: String, action: @escaping () -> Void, keyEquivalent: String? = nil) {
        self.init(title: title, action: #selector(pressed), keyEquivalent: keyEquivalent ?? "")
        self.target = self
        self._action = action
    }

    @objc private func pressed(sender: NSMenuItem) {
        _action?()
    }
}

#Preview {
    VStack {
        ContextMenuView {
            Text("Right click me")
        } menuItems: {
            [
                NSMenuItem(title: "Menu 1") {
                    print("Tapped menu 1")
                },
                NSMenuItem(title: "Menu 2") {
                    print("Tapped menu 2")
                },
                NSMenuItem(title: "Menu 3") {
                    print("Tapped menu 3")
                }
            ]
        }
        .padding()
    }
}
