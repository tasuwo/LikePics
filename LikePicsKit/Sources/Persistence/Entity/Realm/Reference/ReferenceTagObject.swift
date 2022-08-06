//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation
import RealmSwift

class ReferenceTagObject: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var name: String = ""
    @Persisted var isHidden = false
    @Persisted var isDirty = false
}

extension ReferenceTag {
    static func make(by managedObject: ReferenceTagObject) -> ReferenceTag {
        return .init(id: managedObject.id,
                     name: managedObject.name,
                     isHidden: managedObject.isHidden,
                     isDirty: managedObject.isDirty)
    }
}
