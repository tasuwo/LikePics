//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie

public protocol HasImageLoaderSettings {
    var clipDiskCache: DiskCaching { get }
    var clipThumbnailPipeline: Pipeline { get }
    var albumThumbnailPipeline: Pipeline { get }
    var clipItemThumbnailPipeline: Pipeline { get }
    var temporaryThumbnailPipeline: Pipeline { get }
    var previewPipeline: Pipeline { get }
    var previewPrefetcher: PreviewPrefetchable { get }
}
