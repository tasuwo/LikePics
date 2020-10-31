//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol LightweightClipStorageProtocol {
    // MARK: Transaction

    var isInTransaction: Bool { get }
    func beginTransaction() throws
    func commitTransaction() throws
    func cancelTransactionIfNeeded() throws

    // MARK: Read

    func readClip(havingUrl url: URL) -> Result<LightweightClip?, ClipStorageError>

    // MARK: Create

    func create(clip: LightweightClip) -> Result<Void, ClipStorageError>
    func create(tag: LightweightTag) -> Result<Void, ClipStorageError>

    // MARK: Update

    func updateTag(having id: LightweightTag.Identity, nameTo name: String) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [LightweightClip.Identity], byAddingTagsHaving tagIds: [LightweightTag.Identity]) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [LightweightClip.Identity], byDeletingTagsHaving tagIds: [LightweightTag.Identity]) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [LightweightClip.Identity], byReplacingTagsHaving tagIds: [LightweightTag.Identity]) -> Result<Void, ClipStorageError>

    // MARK: Delete

    func deleteClips(having ids: [LightweightClip.Identity]) -> Result<Void, ClipStorageError>
    func deleteTags(having ids: [LightweightTag.Identity]) -> Result<Void, ClipStorageError>
}
