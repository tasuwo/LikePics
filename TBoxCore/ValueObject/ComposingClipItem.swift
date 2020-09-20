//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

struct ComposingClipItem {
    let thumbnailImageUrl: URL?
    let thumbnailSize: ImageSize?
    let thumbnailImage: UIImage?
    let largeImageUrl: URL?
    let largeImageSize: ImageSize?
    let largeImage: UIImage?

    init(imageUrl: URL, imageSize: CGSize, imageData: UIImage, quality: ImageQuality) {
        switch quality {
        case .low:
            self.thumbnailImageUrl = imageUrl
            self.thumbnailSize = ImageSize(height: Double(imageSize.height),
                                           width: Double(imageSize.width))
            self.thumbnailImage = imageData
            self.largeImageUrl = nil
            self.largeImageSize = nil
            self.largeImage = nil
        case .high:
            self.largeImageUrl = imageUrl
            self.largeImageSize = ImageSize(height: Double(imageSize.height),
                                            width: Double(imageSize.width))
            self.largeImage = imageData
            self.thumbnailImageUrl = nil
            self.thumbnailSize = nil
            self.thumbnailImage = nil
        }
    }

    init(item: ComposingClipItem, imageUrl: URL, imageSize: CGSize, imageData: UIImage, quality: ImageQuality) {
        switch quality {
        case .low:
            self.thumbnailImageUrl = imageUrl
            self.thumbnailSize = ImageSize(height: Double(imageSize.height),
                                           width: Double(imageSize.width))
            self.thumbnailImage = imageData
            self.largeImageUrl = item.largeImageUrl
            self.largeImageSize = item.largeImageSize
            self.largeImage = item.largeImage
        case .high:
            self.largeImageUrl = imageUrl
            self.largeImageSize = ImageSize(height: Double(imageSize.height),
                                            width: Double(imageSize.width))
            self.largeImage = imageData
            self.thumbnailImageUrl = item.thumbnailImageUrl
            self.thumbnailSize = item.thumbnailSize
            self.thumbnailImage = item.thumbnailImage
        }
    }

    func toLoadedClipItem(at index: Int, inClip url: URL, currentDate: Date) -> LoadedClipItem? {
        guard let thumbnailImageUrl = self.thumbnailImageUrl,
            let thumbnailSize = self.thumbnailSize,
            let largeImageUrl = self.largeImageUrl,
            let largeImageSize = self.largeImageSize,
            let thumbnailImage = self.thumbnailImage,
            let largeImage = self.largeImage
        else {
            return nil
        }

        let item = ClipItem(clipUrl: url,
                            clipIndex: index,
                            thumbnail: .init(url: thumbnailImageUrl,
                                             size: thumbnailSize),
                            image: .init(url: largeImageUrl,
                                         size: largeImageSize),
                            registeredDate: currentDate,
                            updatedDate: currentDate)
        return (item, (.low, thumbnailImageUrl, thumbnailImage), (.high, largeImageUrl, largeImage))
    }
}
