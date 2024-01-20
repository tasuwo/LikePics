//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Domain
import Foundation
import SwiftUI

@Observable
final class TagEditableViewModel {
    var isPresentingUpdateFailureAlert = false

    var isPresentingDeleteConfirmationAlert = false
    var isPresentingDeleteFailureAlert = false
    var deletingTagId: Tag.ID?

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

    func requestToDeleteTag(id: Tag.ID, clipsCount: Int, in context: NSManagedObjectContext) {
        guard clipsCount > 0 else {
            deleteTag(having: id, in: context)
            return
        }

        deletingTagId = id
        isPresentingDeleteConfirmationAlert = true
    }

    fileprivate func deleteTag(having id: Tag.ID, in context: NSManagedObjectContext) {
        do {
            try context.deleteTag(having: id)
        } catch {
            isPresentingDeleteFailureAlert = true
        }
    }
}

extension View {
    func alertForTagEditableView(viewModel: TagEditableViewModel) -> some View {
        modifier(TagEditableViewModifier(viewModel: viewModel))
    }
}

struct TagEditableViewModifier: ViewModifier {
    @Bindable var viewModel: TagEditableViewModel
    @Environment(\.managedObjectContext) private var context

    func body(content: Content) -> some View {
        content
            .alert(Text("Failed to Update Tag", bundle: .module, comment: "Alert title."), isPresented: $viewModel.isPresentingUpdateFailureAlert) {
                Button {
                    viewModel.isPresentingUpdateFailureAlert = false
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: {
                Text("Tag could not be updated because an error occurred.", bundle: .module, comment: "Alert message.")
            }
            .alert(Text("Are you sure you want to delete this tag?", bundle: .module, comment: "Alert title."), isPresented: $viewModel.isPresentingDeleteConfirmationAlert, presenting: viewModel.deletingTagId) { target in
                Button(role: .cancel) {
                    viewModel.isPresentingDeleteConfirmationAlert = false
                } label: {
                    Text("Cancel", bundle: .module)
                }

                Button(role: .destructive) {
                    viewModel.deleteTag(having: target, in: context)
                } label: {
                    Text("Delete", bundle: .module)
                }
            } message: { _ in
                Text("The items tagged with this tag will still be visible in your library.", bundle: .module, comment: "Alert message.")
            }
            .alert(Text("Failed to Delete Tag", bundle: .module, comment: "Alert title."), isPresented: $viewModel.isPresentingDeleteFailureAlert) {
                Button {
                    viewModel.isPresentingDeleteFailureAlert = false
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: {
                Text("Tag could not be deleted because an error occurred.", bundle: .module, comment: "Alert message.")
            }
    }
}
