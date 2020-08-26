//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListPreviewablePresenter: ClipsListDisplayablePresenter {
    var selectedClip: Clip? { get }

    var selectedIndex: Int? { get }

    func select(at index: Int) -> Clip?
}

protocol SelectedClipContainer: AnyObject {
    var selectedClip: Clip? { get set }
}

extension ClipsListPreviewablePresenter where Self: SelectedClipContainer {
    var selectedIndex: Int? {
        guard let clip = self.selectedClip else { return nil }
        return self.clips.firstIndex(where: { $0.url == clip.url })
    }

    func select(at index: Int) -> Clip? {
        guard self.clips.indices.contains(index) else { return nil }
        let clip = self.clips[index]
        self.selectedClip = clip
        return clip
    }
}
