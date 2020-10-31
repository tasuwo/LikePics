//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol ReferenceClipStorageProtocol {
    // MARK: Transaction

    var isInTransaction: Bool { get }
    func beginTransaction() throws
    func commitTransaction() throws
    func cancelTransactionIfNeeded() throws

    // MARK: Read

    func readClip(havingUrl url: URL) -> Result<ReferenceClip?, ClipStorageError>

    // MARK: Create

    func create(clip: ReferenceClip) -> Result<Void, ClipStorageError>
    func create(tag: ReferenceTag) -> Result<Void, ClipStorageError>

    // MARK: Update

    func updateTag(having id: ReferenceTag.Identity, nameTo name: String) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [ReferenceClip.Identity], byAddingTagsHaving tagIds: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [ReferenceClip.Identity], byDeletingTagsHaving tagIds: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [ReferenceClip.Identity], byReplacingTagsHaving tagIds: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError>

    // MARK: Delete

    func deleteClips(having ids: [ReferenceClip.Identity]) -> Result<Void, ClipStorageError>
    func deleteTags(having ids: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError>
}
