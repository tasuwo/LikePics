//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain

struct ClipCollectionState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case deletion(clipId: Clip.Identity)
        case purge(clipId: Clip.Identity)
        case share(clipId: Clip.Identity, imageIds: [ImageContainer.Identity])
    }

    enum Modal: Equatable {
        case albumSelection
        case tagSelection(tagIds: Set<Tag.Identity>)
        case clipEdit(clipId: Clip.Identity)
        case clipMerge(clips: [Clip])
    }

    let source: ClipCollection.Source
    var sourceDescription: String?

    var layout: ClipCollection.Layout
    var preservedLayout: ClipCollection.Layout?
    var operation: ClipCollection.Operation

    var clips: Collection<Clip>
    var previewingClipId: Clip.Identity?

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
        previewingClipId = nil
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

    var previewingClip: Clip? {
        guard let clipId = previewingClipId else { return nil }
        return clips.value(having: clipId)
    }

    var title: String? {
        if operation != .selecting {
            if let description = sourceDescription {
                return "\(description) (\(clips._filteredIds.count))"
            } else {
                return nil
            }
        }
        return clips._selectedIds.isEmpty
            ? L10n.clipCollectionViewTitleSelect
            : L10n.clipCollectionViewTitleSelecting(clips._selectedIds.count)
    }
}

// MARK: - Codable

extension ClipCollectionState: Codable {}

extension ClipCollectionState.Alert: Codable {
    enum CodingKeys: CodingKey {
        case error
        case deletion
        case purge
        case share
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .error:
            let message = try container.decodeIfPresent(String.self, forKey: .deletion)
            self = .error(message)

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
        case tagSelection
        case clipEdit
        case clipMerge
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .albumSelection:
            self = .albumSelection

        case .tagSelection:
            let tagIds = try container.decode(Set<Tag.Identity>.self, forKey: .tagSelection)
            self = .tagSelection(tagIds: tagIds)

        case .clipEdit:
            let clipId = try container.decode(Clip.Identity.self, forKey: .clipMerge)
            self = .clipEdit(clipId: clipId)

        case .clipMerge:
            let clips = try container.decode([Clip].self, forKey: .clipMerge)
            self = .clipMerge(clips: clips)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .albumSelection:
            try container.encode(true, forKey: .albumSelection)

        case let .tagSelection(tagIds: tagIds):
            try container.encode(tagIds, forKey: .tagSelection)

        case let .clipEdit(clipId: clipId):
            try container.encode(clipId, forKey: .clipEdit)

        case let .clipMerge(clips):
            try container.encode(clips, forKey: .clipMerge)
        }
    }
}
