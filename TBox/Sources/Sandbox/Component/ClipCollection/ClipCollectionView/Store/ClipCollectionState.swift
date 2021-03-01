//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct ClipCollectionState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case deletion(clipId: Clip.Identity, at: IndexPath)
        case purge(clipId: Clip.Identity, at: IndexPath)
    }

    enum Source: Equatable {
        enum SearchQuery: Equatable {
            case keywords([String])
            case tag(Tag?)
        }

        case all
        case album(Album.Identity)
        case search(SearchQuery)

        var isAlbum: Bool {
            switch self {
            case .album:
                return true

            default:
                return false
            }
        }
    }

    let selections: Set<Clip.Identity>
    let isSomeItemsHidden: Bool

    let operation: ClipCollection.Operation
    let isEmptyMessageViewDisplaying: Bool
    let isCollectionViewDisplaying: Bool

    let alert: Alert?

    let source: Source

    let isDismissed: Bool

    let _clips: [Clip.Identity: Ordered<Clip>]
    let _filteredClipIds: Set<Clip.Identity>
    let _previewingClipId: Clip.Identity?
}

extension ClipCollectionState {
    var clips: [Clip] {
        _filteredClipIds
            .compactMap { id in _clips[id] }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }

    var selectedClips: [Clip] {
        selections
            .compactMap { id in _clips[id] }
            .sorted(by: { $0.index < $1.index })
            .compactMap { $0.value }
    }

    var previewingClip: Clip? {
        guard let clipId = _previewingClipId else { return nil }
        return _clips[clipId]?.value
    }

    var _orderedClips: [Clip] {
        _clips
            .map { $0.value }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }
}

extension ClipCollectionState {
    func newSelectedClips(from previous: Self) -> Set<Clip> {
        let additions = selections.subtracting(previous.selections)
        return Set(additions.compactMap { _clips[$0]?.value })
    }

    func newDeselectedClips(from previous: Self) -> Set<Clip> {
        let deletions = previous.selections.subtracting(selections)
        return Set(deletions.compactMap { _clips[$0]?.value })
    }
}

extension ClipCollectionState {
    func updating(selections: Set<Clip.Identity>) -> Self {
        return .init(selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     operation: operation,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     alert: alert,
                     source: source,
                     isDismissed: isDismissed,
                     _clips: _clips,
                     _filteredClipIds: _filteredClipIds,
                     _previewingClipId: _previewingClipId)
    }

    func updating(_previewingClipId: Clip.Identity) -> Self {
        return .init(selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     operation: operation,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     alert: alert,
                     source: source,
                     isDismissed: isDismissed,
                     _clips: _clips,
                     _filteredClipIds: _filteredClipIds,
                     _previewingClipId: _previewingClipId)
    }

    func updating(operation: ClipCollection.Operation) -> Self {
        return .init(selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     operation: operation,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     alert: alert,
                     source: source,
                     isDismissed: isDismissed,
                     _clips: _clips,
                     _filteredClipIds: _filteredClipIds,
                     _previewingClipId: _previewingClipId)
    }

    func updating(alert: Alert?) -> Self {
        return .init(selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     operation: operation,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     alert: alert,
                     source: source,
                     isDismissed: isDismissed,
                     _clips: _clips,
                     _filteredClipIds: _filteredClipIds,
                     _previewingClipId: _previewingClipId)
    }

    func updating(_clips: [Clip.Identity: Ordered<Clip>]) -> Self {
        return .init(selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     operation: operation,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     alert: alert,
                     source: source,
                     isDismissed: isDismissed,
                     _clips: _clips,
                     _filteredClipIds: _filteredClipIds,
                     _previewingClipId: _previewingClipId)
    }

    func updating(_filteredClipIds: Set<Clip.Identity>) -> Self {
        return .init(selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     operation: operation,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     alert: alert,
                     source: source,
                     isDismissed: isDismissed,
                     _clips: _clips,
                     _filteredClipIds: _filteredClipIds,
                     _previewingClipId: _previewingClipId)
    }

    func updating(isEmptyMessageViewDisplaying: Bool,
                  isCollectionViewDisplaying: Bool) -> Self
    {
        return .init(selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     operation: operation,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     alert: alert,
                     source: source,
                     isDismissed: isDismissed,
                     _clips: _clips,
                     _filteredClipIds: _filteredClipIds,
                     _previewingClipId: _previewingClipId)
    }

    func updating(isSomeItemsHidden: Bool) -> Self {
        return .init(selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     operation: operation,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     alert: alert,
                     source: source,
                     isDismissed: isDismissed,
                     _clips: _clips,
                     _filteredClipIds: _filteredClipIds,
                     _previewingClipId: _previewingClipId)
    }

    func updating(isDismissed: Bool) -> Self {
        return .init(selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     operation: operation,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     alert: alert,
                     source: source,
                     isDismissed: isDismissed,
                     _clips: _clips,
                     _filteredClipIds: _filteredClipIds,
                     _previewingClipId: _previewingClipId)
    }
}
