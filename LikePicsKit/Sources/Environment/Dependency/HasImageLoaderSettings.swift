//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie

/// @mockable
public protocol HasImageLoaderSettings {
    var clipDiskCache: DiskCaching { get }
    var clipThumbnailProcessingQueue: ImageProcessingQueue { get }
    var albumThumbnailProcessingQueue: ImageProcessingQueue { get }
    var clipItemThumbnailProcessingQueue: ImageProcessingQueue { get }
    var temporaryThumbnailProcessingQueue: ImageProcessingQueue { get }
    var previewProcessingQueue: ImageProcessingQueue { get }
    var previewPrefetcher: PreviewPrefetchable { get }
}
