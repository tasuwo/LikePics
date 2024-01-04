//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import SwiftUI

struct ImageEntryListView: View {
    let images: [ImageEntry]
    let displayOrder: Bool
    @Binding var selectedIds: [UUID]
    @State var nextSelectionOrder = 0

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 130, maximum: 130)),
            GridItem(.adaptive(minimum: 130, maximum: 130)),
            GridItem(.adaptive(minimum: 130, maximum: 130)),
        ]) {
            ForEach(images) { image in
                let index = selectedIds.firstIndex(of: image.id)
                ImageEntryView(image: image, selectedOrder: index.flatMap({ $0 + 1 }), displayOrder: displayOrder)
                    .onTapGesture {
                        if let index {
                            selectedIds.remove(at: index)
                        } else {
                            selectedIds.append(image.id)
                        }
                    }
            }
        }
    }
}

struct ImageReferenceKey: FocusedValueKey {
    typealias Value = Binding<ImageEntry?>
}

extension FocusedValues {
    var selectedImage: Binding<ImageEntry?>? {
        get { self[ImageReferenceKey.self] }
        set { self[ImageReferenceKey.self] = newValue }
    }
}

#Preview {
    @State var selectedIds: [UUID] = .init()
    @State var useIndex = false

    return ImageEntryListView(images: (0 ... 10).map({ _ in ImageEntry(id: UUID(), name: "", data: Data(), width: 100, height: 100) }),
                              displayOrder: false,
                              selectedIds: $selectedIds)
        .frame(width: 300, height: 400)
        .padding()
}
