//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Foundation

// sourcery: AutoDefaultValue, AutoDefaultValueUsePublic
public struct ReferenceAlbum: Codable, Equatable, Hashable {
    public let id: UUID
    public let title: String
    public let isHidden: Bool
    public let registeredDate: Date
    public let updatedDate: Date
    public let isDirty: Bool

    // MARK: - Lifecycle

    // sourcery: AutoDefaultValueUseThisInitializer
    public init(id: UUID, title: String, isHidden: Bool, registeredDate: Date, updatedDate: Date, isDirty: Bool = false) {
        self.id = id
        self.title = title
        self.isHidden = isHidden
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
        self.isDirty = isDirty
    }
}

extension ReferenceAlbum: Identifiable {
    public typealias Identity = Album.Identity

    public var identity: Album.Identity {
        return self.id
    }
}

extension ReferenceAlbum {
    func map(to: Album.Type) -> Album {
        return .init(id: id, title: title, clips: [], isHidden: isHidden, registeredDate: registeredDate, updatedDate: updatedDate)
    }
}
