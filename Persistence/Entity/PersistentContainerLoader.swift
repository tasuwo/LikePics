//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreData

public enum PersistentContainerLoader {
    class Class {}

    public static func load() -> NSPersistentContainer {
        let bundle = Bundle(for: Self.Class.self)
        guard let url = bundle.url(forResource: "Model", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: url)
        else {
            fatalError("Unable to load Core Data Model")
        }
        return NSPersistentContainer(name: "Model", managedObjectModel: model)
    }
}
