//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

struct ClipItemCellOverlay: View {
    let page: Int
    let numberOfPage: Int

    var body: some View {
        ZStack {
            Text("\(page)/\(numberOfPage)")
                .font(.system(size: 10))
                .padding(4)
                .foregroundColor(.white)
                .opacity(0.8)
        }
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .padding(4)
    }
}

// MARK: - Preview

struct ClipItemCellOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ClipItemCellOverlay(page: 1, numberOfPage: 100)
    }
}
