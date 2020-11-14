//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData

extension Set where Element: NSManagedObject {
    func updatedObjectIDs(for keyPaths: Set<RelationshipKeyPath>) -> Set<NSManagedObjectID>? {
        return reduce(into: Set<NSManagedObjectID>()) { objectIds, object in
            guard let changedKeyPath = object.changedKeyPath(from: keyPaths) else { return }

            let value = object.value(forKey: changedKeyPath.inverseRelationshipKeyPath)
            if let toManyObjects = value as? Set<NSManagedObject> {
                toManyObjects.forEach {
                    objectIds.insert($0.objectID)
                }
            } else if let toOneObject = value as? NSManagedObject {
                objectIds.insert(toOneObject.objectID)
            } else {
                assertionFailure("Invalid relationship observed for keyPath: \(changedKeyPath)")
                return
            }
        }
    }
}

private extension NSManagedObject {
    func changedKeyPath(from keyPaths: Set<RelationshipKeyPath>) -> RelationshipKeyPath? {
        return keyPaths.first { keyPath -> Bool in
            guard keyPath.destinationEntityName == entity.name!
                || keyPath.destinationEntityName == entity.superentity?.name
            else {
                return false
            }
            return changedValues().keys.contains(keyPath.destinationPropertyName)
        }
    }
}
