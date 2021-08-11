//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipInformationMenuBuildable {
    static func build(for item: ClipItem) -> [ClipInformationMenuItem]
}

enum ClipInformationMenuBuilder: ClipInformationMenuBuildable {
    // MARK: - ClipInformationMenuBuildable

    static func build(for item: ClipItem) -> [ClipInformationMenuItem] {
        return [
            item.imageUrl == nil ? nil : .copyImageUrl,
            item.imageUrl == nil ? nil : .openImageUrl,
            .delete
        ].compactMap { $0 }
    }
}
