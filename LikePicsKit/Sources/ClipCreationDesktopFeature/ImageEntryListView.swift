//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import SwiftUI

struct ImageEntryListView: View {
    let images: [ImageSource]
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

extension ClipCreationFeatureCore.ImageSource: Identifiable {
    public var id: UUID { identifier }
}

#Preview {
    @State var selectedIds: [UUID] = .init()
    @State var useIndex = false

    return ImageEntryListView(images: (0 ... 10).map({ _ in .init(fileURL: URL(string: "https://localhost")!) }),
                              displayOrder: false,
                              selectedIds: $selectedIds)
        .frame(width: 300, height: 400)
        .padding()
}
