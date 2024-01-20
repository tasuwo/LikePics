//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Domain
import Foundation
import SwiftUI

@Observable
final class AlbumEditableViewModel {
    var isPresentingUpdateFailureAlert = false
    var isPresentingCreateFailureAlert = false

    var isPresentingDeleteConfirmationAlert = false
    var isPresentingDeleteFailureAlert = false
    var deletingAlbumId: Album.ID?

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
    func createNewAlbum(in context: NSManagedObjectContext) -> UUID? {
        do {
            return try context.createAlbum(withTitle: String(localized: "Untitled Album", bundle: .module, comment: "New Album Title"))
        } catch {
            isPresentingCreateFailureAlert = true
            return nil
        }
    }

    func requestToDeleteAlbum(id: Album.ID, clipsCount: Int, in context: NSManagedObjectContext) {
        guard clipsCount > 0 else {
            deleteAlbum(having: id, in: context)
            return
        }

        deletingAlbumId = id
        isPresentingDeleteConfirmationAlert = true
    }

    fileprivate func deleteAlbum(having id: Album.ID, in context: NSManagedObjectContext) {
        do {
            try context.deleteAlbum(having: id)
        } catch {
            isPresentingDeleteFailureAlert = true
        }
    }
}

extension View {
    func alertForAlbumEditableView(viewModel: AlbumEditableViewModel) -> some View {
        modifier(AlbumEditableViewModifier(viewModel: viewModel))
    }
}

struct AlbumEditableViewModifier: ViewModifier {
    @Bindable var viewModel: AlbumEditableViewModel
    @Environment(\.managedObjectContext) private var context

    func body(content: Content) -> some View {
        content
            .alert(Text("Failed to Update Album", bundle: .module, comment: "Alert title."), isPresented: $viewModel.isPresentingUpdateFailureAlert) {
                Button {
                    viewModel.isPresentingUpdateFailureAlert = false
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: {
                Text("Album could not be updated because an error occurred.", bundle: .module, comment: "Alert message.")
            }
            .alert(Text("Failed to Create Album", bundle: .module, comment: "Alert title."), isPresented: $viewModel.isPresentingCreateFailureAlert) {
                Button {
                    viewModel.isPresentingCreateFailureAlert = false
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: {
                Text("Album could not be created because an error occurred.", bundle: .module, comment: "Alert message.")
            }
            .alert(Text("Are you sure you want to delete this album?", bundle: .module, comment: "Alert title."), isPresented: $viewModel.isPresentingDeleteConfirmationAlert, presenting: viewModel.deletingAlbumId) { target in
                Button(role: .cancel) {
                    viewModel.isPresentingDeleteConfirmationAlert = false
                } label: {
                    Text("Cancel", bundle: .module)
                }

                Button(role: .destructive) {
                    viewModel.deleteAlbum(having: target, in: context)
                } label: {
                    Text("Delete", bundle: .module)
                }
            } message: { _ in
                Text("The items in this album will still be visible in your library and other albums that contain them.", bundle: .module, comment: "Alert message.")
            }
            .alert(Text("Failed to Delete Album", bundle: .module, comment: "Alert title."), isPresented: $viewModel.isPresentingDeleteFailureAlert) {
                Button {
                    viewModel.isPresentingDeleteFailureAlert = false
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: {
                Text("Album could not be deleted because an error occurred.", bundle: .module, comment: "Alert message.")
            }
    }
}
