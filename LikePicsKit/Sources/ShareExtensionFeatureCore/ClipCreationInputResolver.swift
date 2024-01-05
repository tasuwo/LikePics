//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import Foundation

public enum ClipCreationInputResolver {
    public static func inputs(for context: NSExtensionContext) async throws -> ClipCreationInput? {
        let items = context.inputItems.compactMap { $0 as? NSExtensionItem }
        guard !items.isEmpty else {
            return nil
        }

        let sources = try await withThrowingTaskGroup(of: SharedItem?.self) { group in
            for attachment in items.compactMap({ $0.attachments }).flatMap({ $0 }) {
                group.addTask {
                    try await attachment.sharedItem()
                }
            }

            var results: [SharedItem?] = []
            for try await imageSource in group {
                results.append(imageSource)
            }

            return results
        }.compactMap({ $0 })

        if case let .webPageURL(url) = sources.first(where: { $0.isWebPageURL == true }) {
            return .webPageURL(url)
        } else {
            let data = sources.compactMap({ $0.data }).map({ ImageSource(data: $0) })
            let fileUrls = sources.compactMap({ $0.fileURL }).map({ ImageSource(fileURL: $0) })

            if data.isEmpty, fileUrls.isEmpty {
                return nil
            }

            return .imageSources(data + fileUrls)
        }
    }
}
