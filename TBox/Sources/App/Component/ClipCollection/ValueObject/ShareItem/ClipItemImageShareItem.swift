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
    // アプリから ActivityController に渡す前に全ての画像をロードすると遅くなる恐れがあるので、遅延して読み込ませる
    override var item: Any {
        // HACK: バックエンドが Core Data であり、同期的にアクセスする必要がある
        //       サービス実装側で Core Data の API で同期をとっているはずだが、
        //       うまく働かないケースがあるようなので、ここで明示的に同期を取る
        return DispatchQueue.main.sync {
            guard let data = try? imageQueryService.read(having: imageId),
                  let image = UIImage(data: data)
            else {
                return super.item
            }
            return image
        }
    }

    // MARK: - Initializers

    init(imageId: ImageContainer.Identity,
         imageQueryService: ImageQueryServiceProtocol)
    {
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
