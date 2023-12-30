//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

public struct AppScene: Scene {
    private let container: AppContainer

    @AppStorage(\.userInterfaceStyle) var userInterfaceStyle

    public init(_ container: AppContainer) {
        self.container = container
    }

    public var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(container)
                .environment(\.albumThumbnailProcessingQueue, container.albumThumbnailProcessingQueue)
                .environment(\.clipThumbnailProcessingQueue, container.clipThumbnailProcessingQueue)
                .environment(\.imageQueryService, container.imageQueryService)
                .preferredColorScheme(userInterfaceStyle.colorScheme)
        }

        Settings {
            SettingsView()
                .environment(container.cloudAvailability)
                .preferredColorScheme(userInterfaceStyle.colorScheme)
        }
    }
}

private extension UserInterfaceStyle {
    var colorScheme: ColorScheme? {
        switch self {
        case .dark:
            return .dark

        case .light:
            return .light

        case .unspecified:
            return nil
        }
    }
}
