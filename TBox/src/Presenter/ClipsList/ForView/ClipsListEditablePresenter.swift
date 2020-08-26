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

protocol SelectedClipsContainer: AnyObject {
    var selectedClips: [Clip] { get set }
}

extension ClipsListEditablePresenter where Self: SelectedClipsContainer {
    var selectedIndices: [Int] {
        return self.selectedClips.compactMap { selectedClip in
            self.clips.firstIndex(where: { $0.url == selectedClip.url })
        }
    }

    func select(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        guard !self.selectedClips.contains(where: { $0.url == clip.url }) else {
            return
        }
        self.selectedClips.append(clip)
    }

    func deselect(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        guard let index = self.selectedClips.firstIndex(where: { $0.url == clip.url }) else {
            return
        }
        self.selectedClips.remove(at: index)
    }
}
