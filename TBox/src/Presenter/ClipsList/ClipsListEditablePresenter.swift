//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListEditablePresenter: ClipsListDisplayablePresenter {
    var selectedClips: [Clip] { get }

    var selectedIndices: [Int] { get }

    func select(at index: Int)

    func deselect(at index: Int)
}

extension ClipsListEditablePresenter {
    var selectedIndices: [Int] {
        return self.selectedClips.compactMap { selectedClip in
            self.clips.firstIndex(where: { $0.url == selectedClip.url })
        }
    }
}
