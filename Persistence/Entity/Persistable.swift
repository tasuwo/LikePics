//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import RealmSwift

protocol Persistable {
    associatedtype ManagedObject: RealmSwift.Object
    static func make(by managedObject: ManagedObject) -> Self
}
