//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

public class ClipReferencesIntegrityValidationService {
    private let clipStorage: ClipStorageProtocol
    private let referenceClipStorage: ReferenceClipStorageProtocol
    private let logger: TBoxLoggable
    private let queue: DispatchQueue

    // MARK: - Lifecycle

    public init(clipStorage: ClipStorageProtocol,
                referenceClipStorage: ReferenceClipStorageProtocol,
                logger: TBoxLoggable,
                queue: DispatchQueue)
    {
        self.clipStorage = clipStorage
        self.referenceClipStorage = referenceClipStorage
        self.logger = logger
        self.queue = queue
    }

    // MARK: - Methods

    private func validateAndFixTagsIntegrityIfNeeded() throws {
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

        // swiftlint:disable:next identifier_name
        var _tags: [Tag.Identity: Tag]?
        clipStorage.performAndWait { [weak self] in
            guard let self = self else { return }
            switch self.clipStorage.readAllTags() {
            case let .success(result):
                _tags = result.reduce(into: [Tag.Identity: Tag]()) { result, tag in
                    result[tag.identity] = tag
                }

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to read tags: \(error.localizedDescription)
                """))
                _tags = nil
            }
        }
        guard let tags = _tags else { return }

        try self.referenceClipStorage.beginTransaction()

        for (tagId, tag) in tags {
            if let referenceTag = referenceTags[tagId] {
                // Dirtyフラグが立っていた場合、整合の対象から外す
                if referenceTag.isDirty { continue }

                if referenceTag.name != tag.name {
                    if case let .failure(error) = self.referenceClipStorage.updateTag(having: referenceTag.identity, nameTo: tag.name) {
                        self.logger.write(ConsoleLog(level: .error, message: """
                        Failed to update tag '\(referenceTag.name)' to '\(tag.name)'
                        Error: \(error.localizedDescription)
                        """))
                    }
                }

                if referenceTag.isHidden != tag.isHidden {
                    if case let .failure(error) = self.referenceClipStorage.updateTag(having: referenceTag.identity, byHiding: tag.isHidden) {
                        self.logger.write(ConsoleLog(level: .error, message: """
                        Failed to update tag to \(tag.isHidden ? "hide" : "reveal")
                        Error: \(error.localizedDescription)
                        """))
                    }
                }
            } else {
                if case let .failure(error) = self.referenceClipStorage.create(tag: .init(id: tag.id, name: tag.name, isHidden: tag.isHidden)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to create reference tag '\(tag.name)' with id \(tag.id)
                    Error: \(error.localizedDescription)
                    """))
                }
            }
        }

        let extraTagIds = Set(referenceTags.keys)
            .subtracting(Set(tags.keys))
            .filter { referenceTags[$0]?.isDirty == false }
        if !extraTagIds.isEmpty {
            if case let .failure(error) = self.referenceClipStorage.deleteTags(having: Array(extraTagIds)) {
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to delete extra reference tag: \(error.localizedDescription)
                """))
            }
        }

        try self.referenceClipStorage.commitTransaction()
    }
}

extension ClipReferencesIntegrityValidationService: ClipReferencesIntegrityValidationServiceProtocol {
    // MARK: - ClipReferencesIntegrityValidationServiceProtocol

    public func validateAndFixIntegrityIfNeeded() {
        queue.sync {
            do {
                try self.validateAndFixTagsIntegrityIfNeeded()
            } catch {
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to fix integrity: \(error.localizedDescription)
                """))
            }
        }
    }
}

extension ClipReferencesIntegrityValidationService: CloudStackObserver {
    // MARK: - CloudStackObserver

    public func didRemoteChangedTags(inserted: [ObjectID], updated: [ObjectID], deleted: [ObjectID]) {
        queue.async {
            self.clipStorage.performAndWait { [weak self] in
                guard let self = self else { return }
                do {
                    let insertOrUpdatedIDs = inserted + updated
                    if !insertOrUpdatedIDs.isEmpty {
                        try self.clipStorage.beginTransaction()
                        insertOrUpdatedIDs.forEach { objectId in
                            _ = self.clipStorage.deduplicateTag(for: objectId)
                        }
                        try self.clipStorage.commitTransaction()
                    }
                } catch {
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to deduplicate: \(error.localizedDescription)
                    """))
                }
            }

            do {
                if !inserted.isEmpty || !updated.isEmpty || !deleted.isEmpty {
                    // TODO: パフォーマンス向上を検討する
                    try self.validateAndFixTagsIntegrityIfNeeded()
                }
            } catch {
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to fix integrity: \(error.localizedDescription)
                """))
            }
        }
    }
}
