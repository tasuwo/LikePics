//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension Persistence.Item {
    func map(to: Domain.ClipItem.Type) -> Domain.ClipItem? {
        guard let id = self.id,
            let clipId = self.clip?.id,
            let imageId = self.imageId,
            let createdDate = self.createdDate,
            let updatedDate = self.updatedDate
        else {
            return nil
        }

        return Domain.ClipItem(id: id,
                               url: self.siteUrl,
                               clipId: clipId,
                               clipIndex: Int(self.index),
                               imageId: imageId,
                               imageFileName: self.imageFileName ?? "",
                               imageUrl: self.imageUrl,
                               imageSize: .init(height: self.imageHeight, width: self.imageWidth),
                               imageDataSize: Int(self.imageSize),
                               registeredDate: createdDate,
                               updatedDate: updatedDate)
    }
}
