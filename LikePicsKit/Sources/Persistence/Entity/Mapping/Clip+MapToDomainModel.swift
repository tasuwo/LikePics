//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

public extension Persistence.Clip {
    func map(to type: Domain.Clip.Type) -> Domain.Clip? {
        guard let id = self.id,
              let createdDate = self.createdDate,
              let updatedDate = self.updatedDate
        else {
            return nil
        }

        let items = self.clipItems?
            .compactMap { $0 as? Persistence.Item }
            .compactMap { $0.map(to: Domain.ClipItem.self) } ?? []

        return Domain.Clip(id: id,
                           description: self.descriptionText,
                           items: items,
                           isHidden: self.isHidden,
                           dataSize: Int(self.imagesSize),
                           registeredDate: createdDate,
                           updatedDate: updatedDate)
    }
}

public extension Persistence.Clip {
    func map(to type: Domain.ListingClip.Type) -> Domain.ListingClip? {
        guard let id = self.id else {
            return nil
        }
        return Domain.ListingClip(id: id,
                                  itemsCount: Int(self.itemsCount),
                                  isHidden: self.isHidden)
    }
}
