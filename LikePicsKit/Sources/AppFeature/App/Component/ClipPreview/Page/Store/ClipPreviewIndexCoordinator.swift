//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain

enum ClipPreviewIndexCoordinator {
    struct Result {
        let indexPath: ClipCollection.IndexPath
        let pageChange: ClipPreviewPageViewState.PageChange?
        let isPageAnimated: Bool
        let isDismissed: Bool
    }

    static func coordinate(previousIndexPath: ClipCollection.IndexPath,
                           previousSelectedClip: Clip?,
                           previousSelectedItem: ClipItem?,
                           newPreviewingClips: PreviewingClips) -> Result
    {
        guard let previousSelectedClip = previousSelectedClip,
              let previousSelectedItem = previousSelectedItem
        else {
            return .init(indexPath: previousIndexPath,
                         pageChange: nil,
                         isPageAnimated: false,
                         isDismissed: false)
        }

        if let clipIndex = newPreviewingClips.index(ofClipHaving: previousSelectedClip.id) {
            // 直前にフォーカスしていたClipが存在した場合
            if newPreviewingClips.visibleClip(having: previousSelectedClip.id) {
                // 直前にフォーカスしていたClipが表示可能だった場合
                if let indexPath = newPreviewingClips.indexPath(ofItemHaving: previousSelectedItem.id) {
                    // 直前にフォーカスしていた Item が存在した場合、その場に止まる
                    return .init(indexPath: indexPath,
                                 pageChange: nil,
                                 isPageAnimated: false,
                                 isDismissed: false)
                } else {
                    // 直前にフォーカスしていた Item が存在しなかった場合、Clipの一番最初に移動する
                    return .init(indexPath: .init(clipIndex: clipIndex, itemIndex: 0),
                                 pageChange: .reverse,
                                 isPageAnimated: true,
                                 isDismissed: false)
                }
            } else {
                // 直前にフォーカスしていたClipが表示不可だった場合、周囲のClipに移動する
                return transitToClip(around: previousIndexPath.clipIndex,
                                     previousIndexPath: previousIndexPath,
                                     newPreviewingClips: newPreviewingClips)
            }
        } else {
            // 直前にフォーカスしていたClipが存在しなかった場合、周囲のClipに移動する
            return transitToClip(around: previousIndexPath.clipIndex,
                                 previousIndexPath: previousIndexPath,
                                 newPreviewingClips: newPreviewingClips)
        }
    }

    private static func transitToClip(around clipIndex: Int, previousIndexPath: ClipCollection.IndexPath, newPreviewingClips: PreviewingClips) -> Result {
        if let clip = newPreviewingClips.clip(atIndex: clipIndex), newPreviewingClips.filteredClipIds.contains(clip.id) {
            // 直前にフォーカスしていたindexと同じ位置にClipが存在し、表示可能な場合
            return .init(indexPath: ClipCollection.IndexPath(clipIndex: clipIndex, itemIndex: 0),
                         // 本来は移動方向を調整するのが望ましいが、計算コストが高いためforward固定にする
                         pageChange: .forward,
                         isPageAnimated: true,
                         isDismissed: false)
        } else if let indexPath = newPreviewingClips.visibleIndexPath(afterClipAt: clipIndex) {
            // 直前にフォーカスしていたindexから前方向に表示可能なClipが存在すれば、移動する
            return .init(indexPath: indexPath,
                         pageChange: .forward,
                         isPageAnimated: true,
                         isDismissed: false)
        } else if let indexPath = newPreviewingClips.visibleIndexPath(beforeClipAt: clipIndex) {
            // 直前にフォーカスしていたindexから後方向に表示可能なClipが存在すれば、移動する
            return .init(indexPath: indexPath,
                         pageChange: .reverse,
                         isPageAnimated: true,
                         isDismissed: false)
        } else {
            // 直前にフォーカスしていたindexの前後に表示可能なClipが存在しなければ、表示できるクリップが存在しないため、閉じる
            return .init(indexPath: previousIndexPath,
                         pageChange: nil,
                         isPageAnimated: false,
                         isDismissed: true)
        }
    }
}
