//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

struct AppStack<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @StateObject private var router = Router()

    init(content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            content()
                .environmentObject(router)
                .navigationDestination(for: Route.ClipList.self) { route in
                    ClipListView(clips: route.clips)
                        .environmentObject(router)
                }
                .navigationDestination(for: Route.ClipItemPage.self) { route in
                    ClipItemPageView(clips: route.clips, clipItem: route.clipItem)
                        .environmentObject(router)
                }
        }
    }
}