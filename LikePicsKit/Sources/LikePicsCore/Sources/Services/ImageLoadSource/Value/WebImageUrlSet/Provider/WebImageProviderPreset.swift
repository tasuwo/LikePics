//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

public enum WebImageProviderPreset: CaseIterable {
    case twitter
    case pixiv

    public var provider: WebImageProvider.Type {
        switch self {
        case .twitter:
            return WebImageProvidingService.Twitter.self

        case .pixiv:
            return WebImageProvidingService.Pixiv.self
        }
    }

    public static func resolveProvider(by url: URL) -> WebImageProvider.Type? {
        return Self.allCases
            .map { $0.provider }
            .first(where: { $0.isProviding(url: url) })
    }
}
