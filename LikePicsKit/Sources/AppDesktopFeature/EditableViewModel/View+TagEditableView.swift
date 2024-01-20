//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

extension View {
    func alertForTagEditableView(viewModel: TagEditableViewModel) -> some View {
        modifier(TagEditableViewModifier(viewModel: viewModel))
    }
}

struct TagEditableViewModifier: ViewModifier {
    @Bindable var viewModel: TagEditableViewModel

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
