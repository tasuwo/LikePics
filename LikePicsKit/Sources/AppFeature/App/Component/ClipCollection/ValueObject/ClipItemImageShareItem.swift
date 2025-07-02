//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LinkPresentation
import MobileCoreServices
import UIKit

class ClipItemImageShareItem: UIActivityItemProvider {
    let imageId: ImageContainer.Identity
    let imageQueryService: ImageQueryServiceProtocol
    private let metadata: LPLinkMetadata

    // 画像データはCoreDataから直接読み出す
    // アプリから ActivityController に渡す前に全ての画像をロードすると遅くなる、かつメモリ不足になる恐れがあるので、遅延して読み込ませる
    override var item: Any {
        guard let data = try? imageQueryService.read(having: imageId) else {
            return super.item
        }
        return data
    }

    // MARK: - Initializers

    init(
        imageId: ImageContainer.Identity,
        imageQueryService: ImageQueryServiceProtocol
    ) {
        self.imageId = imageId
        self.imageQueryService = imageQueryService

        self.metadata = LPLinkMetadata()
        self.metadata.imageProvider = NSItemProvider(object: UIImage())

        super.init(placeholderItem: UIImage())
    }
}

extension ClipItemImageShareItem {
    // MARK: - UIActivityItemSource

    override func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return metadata
    }
}
