//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Domain
import Foundation

@Observable
final class AlbumEditableViewModel {
    var isPresentingUpdateFailureAlert = false
    var isPresentingDeleteFailureAlert = false
    var isPresentingCreateFailureAlert = false

    @discardableResult
    func updateAlbum(having id: Album.ID, title: String, in context: NSManagedObjectContext) -> Bool {
        do {
            try context.updateAlbum(having: id, title: title)
            return true
        } catch {
            isPresentingUpdateFailureAlert = true
            return false
        }
    }

    @discardableResult
    func updateAlbum(having id: Album.ID, isHidden: Bool, in context: NSManagedObjectContext) -> Bool {
        do {
            try context.updateAlbum(having: id, isHidden: isHidden)
            return true
        } catch {
            isPresentingUpdateFailureAlert = true
            return false
        }
    }

    @discardableResult
    func deleteAlbum(having id: Album.ID, in context: NSManagedObjectContext) -> Bool {
        do {
            try context.deleteAlbum(having: id)
            return true
        } catch {
            isPresentingDeleteFailureAlert = true
            return false
        }
    }

    @discardableResult
    func createNewAlbum(in context: NSManagedObjectContext) -> UUID? {
        do {
            return try context.createAlbum(withTitle: String(localized: "Untitled Album", bundle: .module, comment: "New Album Title"))
        } catch {
            isPresentingCreateFailureAlert = true
            return nil
        }
    }
}
