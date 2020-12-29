//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

/// @mockable
public protocol ThumbnailStorageProtocol {
    /**
     * Clear all cache
     *
     * - attention: for DEBUG
     */
    func clearCache()
    func save(_ image: CGImage, for item: ClipItem) -> Bool
    func delete(for item: ClipItem) -> Bool
    func resolveImageUrl(for item: ClipItem) -> URL?
}
