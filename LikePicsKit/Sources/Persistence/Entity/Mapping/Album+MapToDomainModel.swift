//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

public extension Persistence.Album {
    func map(to: Domain.Album.Type) -> Domain.Album? {
        guard let id = self.id,
              let title = self.title,
              let createdDate = self.createdDate,
              let updateDate = self.updatedDate
        else {
            return nil
        }

        let clips = self.items?
            .allObjects
            .compactMap { $0 as? AlbumItem }
            .sorted(by: { $0.index < $1.index })
            .compactMap { $0.clip }
            .compactMap { $0.map(to: Domain.Clip.self) } ?? []

        return Domain.Album(id: id,
                            title: title,
                            clips: clips,
                            isHidden: self.isHidden,
                            registeredDate: createdDate,
                            updatedDate: updateDate)
    }
}

public extension Persistence.Album {
    func map(to: Domain.ListingAlbumTitle.Type) -> Domain.ListingAlbumTitle? {
        guard let id = self.id,
              let title = self.title,
              let createdDate = self.createdDate,
              let updateDate = self.updatedDate
        else {
            return nil
        }

        return Domain.ListingAlbumTitle(id: id,
                                        title: title,
                                        isHidden: self.isHidden,
                                        registeredDate: createdDate,
                                        updatedDate: updateDate)
    }
}
