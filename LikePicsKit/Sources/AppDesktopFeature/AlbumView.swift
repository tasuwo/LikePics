//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

struct AlbumView: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .aspectRatio(1, contentMode: .fit)

            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.body)
                Text("\(album.clips.count)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    AlbumView(album: Album(id: UUID(),
                           title: "Test Album",
                           clips: [],
                           isHidden: false,
                           registeredDate: Date(),
                           updatedDate: Date()))
        .padding()
}
