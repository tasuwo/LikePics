//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Smoothie

/// @mockable
public protocol HasDiskCaches {
    var clipDiskCache: DiskCaching { get }
    var albumDiskCache: DiskCaching { get }
    var clipItemDiskCache: DiskCaching { get }
}
