//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

public struct PreviewingClips: Equatable {
    public let value: [Clip]
    public let filteredClipIds: Set<Clip.Identity>
    public let isSomeItemsHidden: Bool

    private let indexByClipId: [Clip.Identity: Int]
    private let indexPathByClipItemId: [ClipItem.Identity: ClipCollection.IndexPath]

    // MARK: - Initializers

    public init(clips: [Clip], isSomeItemsHidden: Bool) {
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

    public func clip(atIndex index: Int) -> Clip? {
        guard value.indices.contains(index) else { return nil }
        return value[index]
    }

    public func clipItem(atIndexPath indexPath: ClipCollection.IndexPath) -> ClipItem? {
        guard let clip = clip(atIndex: indexPath.clipIndex) else { return nil }
        guard clip.items.indices.contains(indexPath.itemIndex) else { return nil }
        return clip.items[indexPath.itemIndex]
    }

    public func clip(having clipId: Clip.Identity) -> Clip? {
        guard let index = indexByClipId[clipId] else { return nil }
        return clip(atIndex: index)
    }

    public func clip(ofItemHaving itemId: ClipItem.Identity) -> Clip? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }
        guard value.indices.contains(indexPath.clipIndex) else { return nil }
        return value[indexPath.clipIndex]
    }

    public func visibleClip(having clipId: Clip.Identity) -> Bool {
        guard let clip = clip(having: clipId) else { return false }
        return filteredClipIds.contains(clip.id)
    }

    public func index(ofClipHaving clipId: Clip.Identity) -> Int? {
        return indexByClipId[clipId]
    }

    public func indexPath(ofItemHaving itemId: ClipItem.Identity) -> ClipCollection.IndexPath? {
        return indexPathByClipItemId[itemId]
    }

    public func visibleIndexPath(afterClipAt clipIndex: Int) -> ClipCollection.IndexPath? {
        guard clipIndex + 1 < value.count else { return nil }
        for clipIndex in clipIndex + 1 ... value.count - 1 {
            if filteredClipIds.contains(value[clipIndex].id) {
                return .init(clipIndex: clipIndex, itemIndex: 0)
            }
        }
        return nil
    }

    public func visibleIndexPath(beforeClipAt clipIndex: Int) -> ClipCollection.IndexPath? {
        guard clipIndex - 1 >= 0 else { return nil }
        for clipIndex in (0 ... clipIndex - 1).reversed() {
            if filteredClipIds.contains(value[clipIndex].id) {
                return .init(clipIndex: clipIndex, itemIndex: value[clipIndex].items.count - 1)
            }
        }
        return nil
    }

    public func pickNextVisibleItem(ofItemHaving itemId: ClipItem.Identity) -> ClipItem? {
        pickNextVisibleItem(ofItemHaving: itemId, range: .overall, loopEnabled: false)
    }

    public func pickPreviousVisibleItem(ofItemHaving itemId: ClipItem.Identity) -> ClipItem? {
        pickPreviousVisibleItem(ofItemHaving: itemId, range: .overall, loopEnabled: false)
    }

    public func pickNextVisibleItem(from indexPath: ClipCollection.IndexPath, by config: ClipPreviewPlayConfiguration) -> ClipCollection.IndexPath? {
        guard let currentItem = clipItem(atIndexPath: indexPath) else { return nil }

        switch config.order {
        case .forward:
            guard let nextItem = pickNextVisibleItem(ofItemHaving: currentItem.id, range: config.range, loopEnabled: config.loopEnabled) else { return nil }
            return self.indexPath(ofItemHaving: nextItem.id)

        case .reverse:
            guard let nextItem = pickPreviousVisibleItem(ofItemHaving: currentItem.id, range: config.range, loopEnabled: config.loopEnabled) else { return nil }
            return self.indexPath(ofItemHaving: nextItem.id)

        case .random:
            switch config.range {
            case .overall:
                guard let clipId = filteredClipIds.randomElement(),
                      let item = clip(having: clipId)?.items.randomElement() else { return nil }
                return self.indexPath(ofItemHaving: item.id)

            case .clip:
                guard let item = clip(atIndex: indexPath.clipIndex)?.items.randomElement() else { return nil }
                return self.indexPath(ofItemHaving: item.id)
            }
        }
    }

    private func pickNextVisibleItem(ofItemHaving itemId: ClipItem.Identity, range: ClipPreviewPlayConfiguration.Range, loopEnabled: Bool) -> ClipItem? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }
        guard value.indices.contains(indexPath.clipIndex) else { return nil }

        let currentClip = value[indexPath.clipIndex]

        if indexPath.itemIndex + 1 < currentClip.items.count {
            // Clip内に次のItemが存在した
            return currentClip.items[indexPath.itemIndex + 1]
        } else {
            // Clip内に次のItemが存在しなかった
            if indexPath.clipIndex + 1 < value.count {
                // 次のClipが存在した
                if loopEnabled {
                    switch range {
                    case .clip:
                        // Clipの先頭のItemに戻す
                        return currentClip.items.first

                    case .overall:
                        // 次のClipが存在すれば移動する
                        for clipIndex in indexPath.clipIndex + 1 ... value.count - 1 {
                            guard filteredClipIds.contains(value[clipIndex].id) else { continue }
                            return value[clipIndex].items.first
                        }
                        for clipIndex in 0 ... indexPath.clipIndex - 1 {
                            guard filteredClipIds.contains(value[clipIndex].id) else { continue }
                            return value[clipIndex].items.first
                        }
                        return currentClip.items.first
                    }
                } else {
                    switch range {
                    case .clip:
                        return nil

                    case .overall:
                        // 次のClipが存在すれば移動する
                        for clipIndex in indexPath.clipIndex + 1 ... value.count - 1 {
                            if filteredClipIds.contains(value[clipIndex].id) {
                                return value[clipIndex].items.first
                            }
                        }
                        return nil
                    }
                }
            } else {
                // 最後のClipだった
                if loopEnabled {
                    switch range {
                    case .clip:
                        // Clipの先頭のItemに戻す
                        return currentClip.items.first

                    case .overall:
                        // 先頭のClipの先頭のItemに戻す
                        return value.first?.items.first
                    }
                } else {
                    return nil
                }
            }
        }
    }

    private func pickPreviousVisibleItem(ofItemHaving itemId: ClipItem.Identity, range: ClipPreviewPlayConfiguration.Range, loopEnabled: Bool) -> ClipItem? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }
        guard value.indices.contains(indexPath.clipIndex) else { return nil }

        let currentClip = value[indexPath.clipIndex]

        if indexPath.itemIndex - 1 >= 0 {
            // Clip内に前のItemが存在した
            return currentClip.items[indexPath.itemIndex - 1]
        } else {
            // Clip内に前のItemが存在しなかった
            if indexPath.clipIndex - 1 >= 0 {
                if loopEnabled {
                    switch range {
                    case .clip:
                        // Clipの末尾のItemに戻す
                        return currentClip.items.last

                    case .overall:
                        for clipIndex in (0 ... indexPath.clipIndex - 1).reversed() {
                            if filteredClipIds.contains(value[clipIndex].id) {
                                return value[clipIndex].items.last
                            }
                        }
                    }
                }

                // 前のClipが存在した
                if loopEnabled, range == .clip {
                    // Clipの末尾のItemに戻す
                    return currentClip.items.last
                } else {
                    for clipIndex in (0 ... indexPath.clipIndex - 1).reversed() {
                        guard filteredClipIds.contains(value[clipIndex].id) else { continue }
                        return value[clipIndex].items.last
                    }
                    for clipIndex in (indexPath.clipIndex + 1 ... value.count - 1).reversed() {
                        guard filteredClipIds.contains(value[clipIndex].id) else { continue }
                        return value[clipIndex].items.last
                    }
                    return currentClip.items.last
                }
            } else {
                // 最初のClipだった
                if loopEnabled {
                    switch range {
                    case .clip:
                        // Clipの末尾のItemに戻す
                        return currentClip.items.last

                    case .overall:
                        // 末尾のClipの末尾のItemに戻す
                        return value.last?.items.last
                    }
                } else {
                    return nil
                }
            }
        }
    }

    // MARK: Write

    public func updated(isSomeItemsHidden: Bool) -> Self {
        let newFilteredClipIds: Set<Clip.Identity> = isSomeItemsHidden
            ? Set(value.filter({ !$0.isHidden }).map(\.id))
            : Set(value.map(\.id))

        return .init(clips: value,
                     filteredClipIds: newFilteredClipIds,
                     isSomeItemsHidden: isSomeItemsHidden,
                     indexByClipId: indexByClipId,
                     indexPathByClipItemId: indexPathByClipItemId)
    }

    public func removedClip(atIndex index: Int) -> Self {
        var newClips = value
        newClips.remove(at: index)
        return .init(clips: newClips,
                     isSomeItemsHidden: isSomeItemsHidden)
    }

    public func removedClipItem(atIndexPath indexPath: ClipCollection.IndexPath) -> Self {
        var newClips = value
        newClips[indexPath.clipIndex] = newClips[indexPath.clipIndex].removedItem(at: indexPath.itemIndex)
        return .init(clips: newClips,
                     isSomeItemsHidden: isSomeItemsHidden)
    }
}
