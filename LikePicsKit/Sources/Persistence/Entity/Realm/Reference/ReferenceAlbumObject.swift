//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation
import RealmSwift

class ReferenceAlbumObject: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var index: Int = 0
    @Persisted var title: String = ""
    @Persisted var isHidden = false
    @Persisted var registeredDate = Date()
    @Persisted var updatedDate = Date()
    @Persisted var isDirty = false
}

extension ReferenceAlbum {
    static func make(by managedObject: ReferenceAlbumObject) -> ReferenceAlbum {
        return .init(
            id: managedObject.id,
            title: managedObject.title,
            isHidden: managedObject.isHidden,
            registeredDate: managedObject.registeredDate,
            updatedDate: managedObject.updatedDate,
            isDirty: managedObject.isDirty
        )
    }
}
