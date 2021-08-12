//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipItemListMenuBuildable {
    static func build(for item: ClipItem) -> [ClipItemListMenuItem]
}

enum ClipItemListMenuBuilder: ClipItemListMenuBuildable {
    // MARK: - ClipItemListMenuBuildable

    static func build(for item: ClipItem) -> [ClipItemListMenuItem] {
        return [
            item.imageUrl == nil ? nil : .copyImageUrl,
            item.imageUrl == nil ? nil : .openImageUrl,
            .delete
        ].compactMap { $0 }
    }
}
