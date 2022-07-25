//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Foundation
import os.log

public class ClipReferencesIntegrityValidationService {
    private let clipStorage: ClipStorageProtocol
    private let referenceClipStorage: ReferenceClipStorageProtocol
    private let commandQueue: StorageCommandQueue
    private let lock: NSRecursiveLock
    private let logger = Logger.init()

    // MARK: - Lifecycle

    public init(clipStorage: ClipStorageProtocol,
                referenceClipStorage: ReferenceClipStorageProtocol,
                commandQueue: StorageCommandQueue,
                lock: NSRecursiveLock)
    {
        self.clipStorage = clipStorage
        self.referenceClipStorage = referenceClipStorage
        self.commandQueue = commandQueue
        self.lock = lock
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
            self.logger.error("参照タグの読み込みに失敗: \(error.localizedDescription, privacy: .public)")
            return
        }

        let tags: [Tag.Identity: Tag]
        switch commandQueue.sync({ [weak self] in self?.clipStorage.readAllTags() }) {
        case let .success(result):
            tags = result.reduce(into: [Tag.Identity: Tag]()) { result, tag in
                result[tag.identity] = tag
            }

        case let .failure(error):
            self.logger.error("タグの読み込みに失敗: \(error.localizedDescription, privacy: .public)")
            return

        case .none:
            self.logger.error("タグの読み込みに失敗")
            return
        }

        try self.referenceClipStorage.beginTransaction()

        for (tagId, tag) in tags {
            if let referenceTag = referenceTags[tagId] {
                // Dirtyフラグが立っていた場合、整合の対象から外す
                if referenceTag.isDirty { continue }

                if referenceTag.name != tag.name {
                    if case let .failure(error) = self.referenceClipStorage.updateTag(having: referenceTag.identity, nameTo: tag.name) {
                        self.logger.error("タグの名前変更('\(referenceTag.name, privacy: .public)'>'\(tag.name, privacy: .public)'に失敗: \(error.localizedDescription, privacy: .public)")
                    }
                }

                if referenceTag.isHidden != tag.isHidden {
                    if case let .failure(error) = self.referenceClipStorage.updateTag(having: referenceTag.identity, byHiding: tag.isHidden) {
                        self.logger.error("タグの更新に失敗: \(error.localizedDescription, privacy: .public)")
                    }
                }
            } else {
                if case let .failure(error) = self.referenceClipStorage.create(tag: .init(id: tag.id, name: tag.name, isHidden: tag.isHidden)) {
                    self.logger.error("参照タグ(name='\(tag.name, privacy: .public)', id='\(tag.id, privacy: .public)'の作成に失敗: \(error.localizedDescription, privacy: .public)")
                }
            }
        }

        let extraTagIds = Set(referenceTags.keys)
            .subtracting(Set(tags.keys))
            .filter { referenceTags[$0]?.isDirty == false }
        if !extraTagIds.isEmpty {
            if case let .failure(error) = self.referenceClipStorage.deleteTags(having: Array(extraTagIds)) {
                self.logger.error("余分な参照タグの削除に失敗: \(error.localizedDescription, privacy: .public)")
            }
        }

        try self.referenceClipStorage.commitTransaction()
    }
}

extension ClipReferencesIntegrityValidationService: ClipReferencesIntegrityValidationServiceProtocol {
    // MARK: - ClipReferencesIntegrityValidationServiceProtocol

    public func validateAndFixIntegrityIfNeeded() {
        lock.lock()
        defer { lock.unlock() }

        do {
            try self.validateAndFixTagsIntegrityIfNeeded()
        } catch {
            try? self.referenceClipStorage.cancelTransactionIfNeeded()
            self.logger.error("整合に失敗: \(error.localizedDescription, privacy: .public)")
        }
    }
}

extension ClipReferencesIntegrityValidationService: CloudStackObserver {
    // MARK: - CloudStackObserver

    public func didRemoteChangedTags(inserted: [ObjectID], updated: [ObjectID], deleted: [ObjectID]) {
        lock.lock()
        defer { lock.unlock() }

        commandQueue.sync { [weak self] in
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
                self.logger.error("タグのdeduplicateに失敗: \(error.localizedDescription, privacy: .public)")
            }
        }

        do {
            if !inserted.isEmpty || !updated.isEmpty || !deleted.isEmpty {
                try self.validateAndFixTagsIntegrityIfNeeded()
            }
        } catch {
            try? self.referenceClipStorage.cancelTransactionIfNeeded()
            self.logger.error("タグの整合に失敗: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func didRemoteChangedAlbumItems(inserted: [ObjectID], updated: [ObjectID], deleted: [ObjectID]) {
        lock.lock()
        defer { lock.unlock() }

        commandQueue.sync { [weak self] in
            guard let self = self else { return }
            do {
                let insertOrUpdatedIDs = inserted + updated
                if !insertOrUpdatedIDs.isEmpty {
                    try self.clipStorage.beginTransaction()
                    insertOrUpdatedIDs.forEach { objectId in
                        self.clipStorage.deduplicateAlbumItem(for: objectId)
                    }
                    try self.clipStorage.commitTransaction()
                }
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("AlbumItemのdeduplicateに失敗: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
