//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain

struct PreviewingClips: Equatable {
    let value: [Clip]
    let filteredClipIds: Set<Clip.Identity>
    let isSomeItemsHidden: Bool

    private let indexByClipId: [Clip.Identity: Int]
    private let indexPathByClipItemId: [ClipItem.Identity: ClipCollection.IndexPath]

    // MARK: - Initializers

    init(clips: [Clip], isSomeItemsHidden: Bool) {
        var clipIds: Set<Clip.Identity> = .init()
        var filteredClipIds: Set<Clip.Identity> = .init()
        var indexByClipId: [Clip.Identity: Int] = [:]
        var indexPathByClipItemId: [ClipItem.Identity: ClipCollection.IndexPath] = [:]

        var clipIndex = 0
        for clip in clips {
            defer { clipIndex += 1 }

            clipIds.insert(clip.id)

            if isSomeItemsHidden {
                if !clip.isHidden {
                    filteredClipIds.insert(clip.id)
                }
            } else {
                filteredClipIds.insert(clip.id)
            }

            indexByClipId[clip.id] = clipIndex

            var clipItemIndex = 0
            for item in clip.items {
                defer { clipItemIndex += 1 }
                indexPathByClipItemId[item.id] = .init(clipIndex: clipIndex, itemIndex: clipItemIndex)
            }
        }

        self.value = clips
        self.filteredClipIds = filteredClipIds
        self.isSomeItemsHidden = isSomeItemsHidden
        self.indexByClipId = indexByClipId
        self.indexPathByClipItemId = indexPathByClipItemId
    }

    private init(clips: [Clip],
                 filteredClipIds: Set<Clip.Identity>,
                 isSomeItemsHidden: Bool,
                 indexByClipId: [Clip.Identity: Int],
                 indexPathByClipItemId: [ClipItem.Identity: ClipCollection.IndexPath])
    {
        self.value = clips
        self.filteredClipIds = filteredClipIds
        self.isSomeItemsHidden = isSomeItemsHidden
        self.indexByClipId = indexByClipId
        self.indexPathByClipItemId = indexPathByClipItemId
    }

    // MARK: - Methods

    // MARK: Read

    func clip(atIndex index: Int) -> Clip? {
        guard value.indices.contains(index) else { return nil }
        return value[index]
    }

    func clipItem(atIndexPath indexPath: ClipCollection.IndexPath) -> ClipItem? {
        guard let clip = clip(atIndex: indexPath.clipIndex) else { return nil }
        guard clip.items.indices.contains(indexPath.itemIndex) else { return nil }
        return clip.items[indexPath.itemIndex]
    }

    func clip(ofHaving clipId: Clip.Identity) -> Clip? {
        guard let index = indexByClipId[clipId] else { return nil }
        return clip(atIndex: index)
    }

    func clip(ofItemHaving itemId: ClipItem.Identity) -> Clip? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }
        guard value.indices.contains(indexPath.clipIndex) else { return nil }
        return value[indexPath.clipIndex]
    }

    func indexPath(ofItemHaving itemId: ClipItem.Identity) -> ClipCollection.IndexPath? {
        return indexPathByClipItemId[itemId]
    }

    func pickNextItem(ofItemHaving itemId: ClipItem.Identity) -> ClipItem? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }
        guard value.indices.contains(indexPath.clipIndex) else { return nil }

        let currentClip = value[indexPath.clipIndex]

        if indexPath.itemIndex + 1 < currentClip.items.count {
            return currentClip.items[indexPath.itemIndex + 1]
        } else {
            guard indexPath.clipIndex + 1 < value.count else { return nil }
            for clipIndex in indexPath.clipIndex + 1 ... value.count - 1 {
                if filteredClipIds.contains(value[clipIndex].id) {
                    return value[clipIndex].items.first
                }
            }
            return nil
        }
    }

    func pickPreviousItem(ofItemHaving itemId: ClipItem.Identity) -> ClipItem? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }
        guard value.indices.contains(indexPath.clipIndex) else { return nil }

        let currentClip = value[indexPath.clipIndex]

        if indexPath.itemIndex - 1 >= 0 {
            return currentClip.items[indexPath.itemIndex - 1]
        } else {
            guard indexPath.clipIndex - 1 >= 0 else { return nil }
            for clipIndex in (0 ... indexPath.clipIndex - 1).reversed() {
                if filteredClipIds.contains(value[clipIndex].id) {
                    return value[clipIndex].items.last
                }
            }
            return nil
        }
    }

    // MARK: Write

    func updated(isSomeItemsHidden: Bool) -> Self {
        let newFilteredClipIds: Set<Clip.Identity> = isSomeItemsHidden
            ? Set(value.filter({ !$0.isHidden }).map(\.id))
            : Set(value.map(\.id))

        return .init(clips: value,
                     filteredClipIds: newFilteredClipIds,
                     isSomeItemsHidden: isSomeItemsHidden,
                     indexByClipId: indexByClipId,
                     indexPathByClipItemId: indexPathByClipItemId)
    }

    func removedClip(atIndex index: Int) -> Self {
        var newClips = value
        newClips.remove(at: index)
        return .init(clips: newClips,
                     isSomeItemsHidden: isSomeItemsHidden)
    }

    func removedClipItem(atIndexPath indexPath: ClipCollection.IndexPath) -> Self {
        var newClips = value
        newClips[indexPath.clipIndex] = newClips[indexPath.clipIndex].removedItem(at: indexPath.itemIndex)
        return .init(clips: newClips,
                     isSomeItemsHidden: isSomeItemsHidden)
    }
}