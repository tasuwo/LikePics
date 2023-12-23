//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct AlbumListView: View {
    @Binding var albums: [Album]
    @State var layout: MultiColumnLayout = .default

    var body: some View {
        ScrollView {
            ZStack {
                Color.clear
                    .frame(maxWidth: .infinity)

                LazyVGrid(columns: layout.columns, spacing: MultiColumnLayout.spacing) {
                    ForEach(albums) { album in
                        AlbumView(album: album)
                    }
                }
                .frame(minWidth: MultiColumnLayout.column4.minRowWidth, maxWidth: layout.maxRowWidth)
                .padding(.all, 41)
            }
        }
        .onChangeFrame { size in
            layout = MultiColumnLayout.layout(forWidth: size.width - 41 * 2)
        }
    }
}

#Preview {
    @State var albums: [Album] = Array((0 ... 6).map { _ in Album(id: UUID(), title: randomAlbumName(), clips: [], isHidden: false, registeredDate: Date(), updatedDate: Date()) })

    func randomAlbumName() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< Int.random(in: 8 ... 15)).map { _ in letters.randomElement()! })
    }

    return AlbumListView(albums: $albums)
}
