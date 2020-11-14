//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData

struct RelationshipKeyPath: Hashable {
    let sourcePropertyName: String
    let destinationEntityName: String
    let destinationPropertyName: String
    let inverseRelationshipKeyPath: String

    init(keyPath: String, relationships: [String: NSRelationshipDescription]) {
        let splittedKeyPath = keyPath.split(separator: ".")
        self.sourcePropertyName = String(splittedKeyPath.first!)
        self.destinationPropertyName = String(splittedKeyPath.last!)

        let relationship = relationships[sourcePropertyName]!
        self.destinationEntityName = relationship.destinationEntity!.name!
        self.inverseRelationshipKeyPath = relationship.inverseRelationship!.name

        [
            self.sourcePropertyName,
            self.destinationEntityName,
            self.destinationPropertyName
        ].forEach { property in
            assert(!property.isEmpty, "Invalid key path is used")
        }
    }
}
