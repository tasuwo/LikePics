//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

extension View {
    func alertForAlbumEditableView(viewModel: AlbumEditableViewModel) -> some View {
        modifier(AlbumEditableViewModifier(viewModel: viewModel))
    }
}

struct AlbumEditableViewModifier: ViewModifier {
    @Bindable var viewModel: AlbumEditableViewModel

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
            .alert(Text("Failed to Delete Album", bundle: .module, comment: "Alert title."), isPresented: $viewModel.isPresentingDeleteFailureAlert) {
                Button {
                    viewModel.isPresentingDeleteFailureAlert = false
                } label: {
                    Text("OK", bundle: .module)
                }
            } message: {
                Text("Album could not be deleted because an error occurred.", bundle: .module, comment: "Alert message.")
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
    }
}
