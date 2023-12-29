//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import SwiftUI

struct ClipItemPageView: View {
    let ini: Int
    let clipItems: [ClipItem]
    @EnvironmentObject var router: Router

    init(clips: [Clip], clipItem: ClipItem) {
        // TODO: パフォーマンス改善
        clipItems = clips.flatMap({ $0.items })
        ini = clipItems.firstIndex(of: clipItem)!
    }

    var body: some View {
        PageView(clipItems, from: ini) { clipItem in
            ClipItemView(item: clipItem)
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                BackButton {
                    // TODO: アニメーションさせる
                    router.path.removeLast()
                }
            }
        }
    }
}
