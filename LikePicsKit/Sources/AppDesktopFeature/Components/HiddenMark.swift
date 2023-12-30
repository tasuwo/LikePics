//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

struct HiddenMark: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "eye.slash")
            .resizable()
            .scaledToFit()
            .padding(size / 6)
            .frame(width: size, height: size)
            .background(.ultraThinMaterial, in: Circle())
    }
}

#Preview {
    HStack(spacing: 0) {
        Color.red
        Color.blue
        Color.green
        Color.yellow
        Color.pink
        Color.gray
    }
    .overlay {
        HiddenMark(size: 40)
    }
}
