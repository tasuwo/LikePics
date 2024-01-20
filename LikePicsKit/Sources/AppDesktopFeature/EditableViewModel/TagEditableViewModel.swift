//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Domain
import Foundation

@Observable
final class TagEditableViewModel {
    var isPresentingUpdateFailureAlert = false
    var isPresentingDeleteFailureAlert = false

    @discardableResult
    func updateTag(having id: Tag.ID, isHidden: Bool, in context: NSManagedObjectContext) -> Bool {
        do {
            try context.updateTag(having: id, isHidden: isHidden)
            return true
        } catch {
            isPresentingUpdateFailureAlert = true
            return false
        }
    }

    @discardableResult
    func deleteTag(having id: Tag.ID, in context: NSManagedObjectContext) -> Bool {
        do {
            try context.deleteTag(having: id)
            return true
        } catch {
            isPresentingDeleteFailureAlert = true
            return false
        }
    }
}
