//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

extension ClipCommandService {
    fileprivate func validateAndFixTagsIntegrityIfNeeded() throws {
        let referenceTags: [ReferenceTag.Identity: ReferenceTag]
        switch self.referenceClipStorage.readAllTags() {
        case let .success(result):
            referenceTags = result.reduce(into: [ReferenceTag.Identity: ReferenceTag]()) { result, tag in
                result[tag.identity] = tag
            }

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read reference tags: \(error.localizedDescription)
            """))
            return
        }

        let tags: [Tag.Identity: Tag]
        switch self.clipStorage.readAllTags() {
        case let .success(result):
            tags = result.reduce(into: [Tag.Identity: Tag]()) { result, tag in
                result[tag.identity] = tag
            }

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read tags: \(error.localizedDescription)
            """))
            return
        }

        try self.referenceClipStorage.beginTransaction()

        for (tagId, tag) in tags {
            if let referenceTag = referenceTags[tagId] {
                if referenceTag.name == tag.name { continue }
                if case let .failure(error) = self.referenceClipStorage.updateTag(having: referenceTag.identity, nameTo: tag.name) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to update tag '\(referenceTag.name)' to '\(tag.name)'
                    Error: \(error.localizedDescription)
                    """))
                }
            } else {
                if case let .failure(error) = self.referenceClipStorage.create(tag: .init(id: tag.id, name: tag.name)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to create reference tag '\(tag.name)' with id \(tag.id)
                    Error: \(error.localizedDescription)
                    """))
                }
            }
        }

        // TODO: 余分なタグがあった場合削除

        try self.referenceClipStorage.commitTransaction()
    }

    fileprivate func validateAndFixClipsIntegrityIfNeeded() throws {
        let referenceClips: [ReferenceClip.Identity: ReferenceClip]
        switch self.referenceClipStorage.readAllClips() {
        case let .success(result):
            referenceClips = result.reduce(into: [ReferenceClip.Identity: ReferenceClip]()) { result, clip in
                result[clip.identity] = clip
            }

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read reference clips: \(error.localizedDescription)
            """))
            return
        }

        let clips: [Clip.Identity: Clip]
        switch self.clipStorage.readAllClips() {
        case let .success(result):
            clips = result.reduce(into: [Clip.Identity: Clip]()) { result, clip in
                result[clip.identity] = clip
            }

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read clips: \(error.localizedDescription)
            """))
            return
        }

        try self.referenceClipStorage.beginTransaction()

        for (clipId, clip) in clips {
            if let _ = referenceClips[clipId] {
                // Note: Clipのタグについては、transport前のものである可能性があるため無視する
            } else {
                let newClip = ReferenceClip(id: clip.id,
                                            url: clip.url,
                                            description: clip.description,
                                            tags: clip.tags.map { ReferenceTag(id: $0.id, name: $0.name) },
                                            isHidden: clip.isHidden,
                                            registeredDate: clip.registeredDate)
                if case let .failure(error) = self.referenceClipStorage.create(clip: newClip) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to create reference clip: \(error.localizedDescription)
                    """))
                }
            }
        }

        // Note: 余分なClipはtransport前のものである可能性があるため無視する

        try self.referenceClipStorage.commitTransaction()
    }
}

extension ClipCommandService: ClipReferencesIntegrityValidationService {
    // MARK: - ClipReferencesIntegrityValidationService

    public func validateAndFixIntegrityIfNeeded() {
        self.queue.sync {
            do {
                try self.validateAndFixTagsIntegrityIfNeeded()
                try self.validateAndFixClipsIntegrityIfNeeded()
            } catch {
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to fix integrity: \(error.localizedDescription)
                """))
            }
        }
    }
}
