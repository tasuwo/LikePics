//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

public struct AppScene: Scene {
    private let container: AppContainer

    public init(_ container: AppContainer) {
        self.container = container
    }

    public var body: some Scene {
        WindowGroup {
            AppView(clipStore: .init(clipQueryService: container.clipQueryService),
                    albumStore: .init(clipQueryService: container.clipQueryService))
                .environmentObject(container)
                .environment(\.albumThumbnailProcessingQueue, container.albumThumbnailProcessingQueue)
                .environment(\.clipThumbnailProcessingQueue, container.clipThumbnailProcessingQueue)
                .environment(\.imageQueryService, container.imageQueryService)
        }
    }
}
