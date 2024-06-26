//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain
import Foundation

struct ClipCollectionState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case removeFromAlbum(clipId: Clip.Identity)
        case deletion(clipId: Clip.Identity)
        case purge(clipId: Clip.Identity)
        case share(clipId: Clip.Identity, imageIds: [ImageContainer.Identity])
    }

    enum Modal: Equatable {
        case albumSelection(id: UUID, clipIds: Set<Clip.Identity>)
        case tagSelectionForClip(id: UUID, clipId: Clip.Identity, tagIds: Set<Tag.Identity>)
        case tagSelectionForClips(id: UUID, clipIds: Set<Clip.Identity>)
        case clipMerge(id: UUID, clips: [Clip])
    }

    let source: ClipCollection.Source
    var sourceDescription: String?

    var layout: ClipCollection.Layout
    var preservedLayout: ClipCollection.Layout?
    var operation: ClipCollection.Operation

    var clips: EntityCollectionSnapshot<Clip>

    var isPreparedQueryEffects: Bool

    var isEmptyMessageViewDisplaying: Bool
    var isCollectionViewDisplaying: Bool

    var alert: Alert?
    var modal: Modal?

    var isDismissed: Bool

    var isSomeItemsHidden: Bool
}

extension ClipCollectionState {
    init(source: ClipCollection.Source, isSomeItemsHidden: Bool) {
        self.source = source
        sourceDescription = nil
        layout = .waterfall
        operation = .none
        clips = .init()
        isPreparedQueryEffects = false
        isEmptyMessageViewDisplaying = false
        isCollectionViewDisplaying = false
        alert = nil
        isDismissed = false
        self.isSomeItemsHidden = isSomeItemsHidden
    }
}

extension ClipCollectionState {
    var isEditing: Bool {
        operation.isEditing
    }

    var isDragInteractionEnabled: Bool {
        source.isAlbum && !operation.isEditing
    }

    var isCollectionViewHidden: Bool {
        !isCollectionViewDisplaying
    }

    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewDisplaying ? 1 : 0
    }

    var title: String? {
        if operation != .selecting {
            if let description = sourceDescription {
                return "\(description) (\(clips.filteredIds.count))"
            } else {
                return nil
            }
        }
        return clips.selectedIds.isEmpty
            ? L10n.clipCollectionViewTitleSelect
            : L10n.clipCollectionViewTitleSelecting(clips.selectedIds.count)
    }
}

// MARK: - Codable

extension ClipCollectionState: Codable {}

extension ClipCollectionState.Alert: Codable {
    enum CodingKeys: CodingKey {
        case error
        case removeFromAlbum
        case deletion
        case purge
        case share
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .error:
            let message = try container.decodeIfPresent(String.self, forKey: .error)
            self = .error(message)

        case .removeFromAlbum:
            let clipId = try container.decode(Clip.Identity.self, forKey: .removeFromAlbum)
            self = .removeFromAlbum(clipId: clipId)

        case .deletion:
            let clipId = try container.decode(Clip.Identity.self, forKey: .deletion)
            self = .deletion(clipId: clipId)

        case .purge:
            let clipId = try container.decode(Clip.Identity.self, forKey: .purge)
            self = .purge(clipId: clipId)

        case .share:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .share)
            let clipId = try nestedContainer.decode(Clip.Identity.self)
            let imageIds = try nestedContainer.decode([ImageContainer.Identity].self)
            self = .share(clipId: clipId, imageIds: imageIds)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .error(message):
            try container.encode(message, forKey: .error)

        case let .removeFromAlbum(clipId: clipId):
            try container.encode(clipId, forKey: .removeFromAlbum)

        case let .deletion(clipId: clipId):
            try container.encode(clipId, forKey: .deletion)

        case let .purge(clipId: clipId):
            try container.encode(clipId, forKey: .purge)

        case let .share(clipId: clipId, imageIds: imageIds):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .share)
            try nestedContainer.encode(clipId)
            try nestedContainer.encode(imageIds)
        }
    }
}

extension ClipCollectionState.Modal: Codable {
    enum CodingKeys: CodingKey {
        case albumSelection
        case tagSelectionForClip
        case tagSelectionForClips
        case clipMerge
    }

    enum AlbumSelectionKeys: CodingKey {
        case id
        case clipIds
    }

    enum TagSelectionForClipKeys: CodingKey {
        case id
        case clipId
        case tagIds
    }

    enum TagSelectionForClipsKeys: CodingKey {
        case id
        case clipIds
    }

    enum ClipEditKeys: CodingKey {
        case id
        case clipId
    }

    enum ClipMergeKeys: CodingKey {
        case id
        case clips
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .albumSelection:
            let nestedContainer = try container.nestedContainer(keyedBy: AlbumSelectionKeys.self, forKey: .albumSelection)
            let id = try nestedContainer.decode(UUID.self, forKey: .id)
            let clipIds = try nestedContainer.decode(Set<Clip.Identity>.self, forKey: .clipIds)
            self = .albumSelection(id: id, clipIds: clipIds)

        case .tagSelectionForClip:
            let nestedContainer = try container.nestedContainer(keyedBy: TagSelectionForClipKeys.self, forKey: .tagSelectionForClip)
            let id = try nestedContainer.decode(UUID.self, forKey: .id)
            let clipId = try nestedContainer.decode(Clip.Identity.self, forKey: .clipId)
            let tagIds = try nestedContainer.decode(Set<Tag.Identity>.self, forKey: .tagIds)
            self = .tagSelectionForClip(id: id, clipId: clipId, tagIds: tagIds)

        case .tagSelectionForClips:
            let nestedContainer = try container.nestedContainer(keyedBy: TagSelectionForClipsKeys.self, forKey: .tagSelectionForClips)
            let id = try nestedContainer.decode(UUID.self, forKey: .id)
            let clipIds = try nestedContainer.decode(Set<Clip.Identity>.self, forKey: .clipIds)
            self = .tagSelectionForClips(id: id, clipIds: clipIds)

        case .clipMerge:
            let nestedContainer = try container.nestedContainer(keyedBy: ClipMergeKeys.self, forKey: .clipMerge)
            let id = try nestedContainer.decode(UUID.self, forKey: .id)
            let clips = try nestedContainer.decode([Clip].self, forKey: .clips)
            self = .clipMerge(id: id, clips: clips)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .albumSelection(id: id, clipIds: clipIds):
            var nestedContainer = container.nestedContainer(keyedBy: AlbumSelectionKeys.self, forKey: .albumSelection)
            try nestedContainer.encode(id, forKey: .id)
            try nestedContainer.encode(clipIds, forKey: .clipIds)

        case let .tagSelectionForClip(id: id, clipId: clipId, tagIds: tagIds):
            var nestedContainer = container.nestedContainer(keyedBy: TagSelectionForClipKeys.self, forKey: .tagSelectionForClip)
            try nestedContainer.encode(id, forKey: .id)
            try nestedContainer.encode(clipId, forKey: .clipId)
            try nestedContainer.encode(tagIds, forKey: .tagIds)

        case let .tagSelectionForClips(id: id, clipIds: clipIds):
            var nestedContainer = container.nestedContainer(keyedBy: TagSelectionForClipsKeys.self, forKey: .tagSelectionForClips)
            try nestedContainer.encode(id, forKey: .id)
            try nestedContainer.encode(clipIds, forKey: .clipIds)

        case let .clipMerge(id: id, clips: clips):
            var nestedContainer = container.nestedContainer(keyedBy: ClipMergeKeys.self, forKey: .clipMerge)
            try nestedContainer.encode(id, forKey: .id)
            try nestedContainer.encode(clips, forKey: .clips)
        }
    }
}
