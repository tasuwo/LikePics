//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import CoreData
import Domain
import Foundation
import SwiftUI

@Observable
final class ClipEditableViewModel {
    var isPresentingUpdateFailureAlert = false

    var isPresentingDeleteConfirmationAlert = false
    var isPresentingDeleteFailureAlert = false
    var deletingClipId: Clip.ID?

    @discardableResult
    func updateClip(having id: Album.ID, isHidden: Bool, in context: NSManagedObjectContext) -> Bool {
        do {
            try context.updateClip(having: id, isHidden: isHidden)
            return true
        } catch {
            isPresentingUpdateFailureAlert = true
            return false
        }
    }

    func requestToDeleteClip(id: Clip.ID, in context: NSManagedObjectContext) {
        deletingClipId = id
        isPresentingDeleteConfirmationAlert = true
    }

    fileprivate func deleteClip(having id: Album.ID, in context: NSManagedObjectContext) {
        do {
            try context.deleteClip(having: id)
        } catch {
            isPresentingDeleteFailureAlert = true
        }
    }
}

extension View {
    func alertForClipEditableView(viewModel: ClipEditableViewModel) -> some View {
        modifier(ClipEditableViewModifier(viewModel: viewModel))
    }
}

struct ClipEditableViewModifier: ViewModifier {
    @Bindable var viewModel: ClipEditableViewModel
    @AppStorage(\.isCloudSyncEnabled) private var isCloudSyncSettingEnabled
    @Environment(\.managedObjectContext) private var context
    @Environment(CloudSyncAvailability.self) private var cloudSyncAvailability

    private var isCloudSyncing: Bool {
        isCloudSyncSettingEnabled && cloudSyncAvailability.isAvailable == true
    }

    func body(content: Content) -> some View {
        content
            .alert(Text("Failed to Update Clip", bundle: .module, comment: "Alert title."), isPresented: $viewModel.isPresentingUpdateFailureAlert) {
                Button {
                    viewModel.isPresentingUpdateFailureAlert = false
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: {
                Text("Clip could not be updated because an error occurred.", bundle: .module, comment: "Alert message.")
            }
            .alert(
                isCloudSyncing
                    ? Text("Delete from all your devices?", bundle: .module, comment: "Alert title.")
                    : Text("Are you sure want to delete this clip?", bundle: .module, comment: "Alert title."),
                isPresented: $viewModel.isPresentingDeleteConfirmationAlert,
                presenting: viewModel.deletingClipId
            ) { target in
                Button(role: .cancel) {
                    viewModel.isPresentingDeleteConfirmationAlert = false
                } label: {
                    Text("Cancel", bundle: .module)
                }

                Button(role: .destructive) {
                    viewModel.isPresentingDeleteConfirmationAlert = false
                    viewModel.deleteClip(having: target, in: context)
                } label: {
                    Text("Delete", bundle: .module)
                }
            } message: { _ in
                isCloudSyncing
                    ? Text("This clip will be deleted from LikePics on all your devices.", bundle: .module, comment: "Alert message.")
                    : Text("This clip will be deleted immediately. This operation cannot be undone.", bundle: .module, comment: "Alert message.")
            }
            .alert(Text("Failed to Delete Clip", bundle: .module, comment: "Alert title."), isPresented: $viewModel.isPresentingDeleteFailureAlert) {
                Button {
                    viewModel.isPresentingDeleteFailureAlert = false
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: {
                Text("Clip could not be deleted because an error occurred.", bundle: .module, comment: "Alert message.")
            }
    }
}
