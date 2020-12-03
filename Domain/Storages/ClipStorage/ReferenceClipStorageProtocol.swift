//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol ReferenceClipStorageProtocol {
    // MARK: Transaction

    var isInTransaction: Bool { get }
    func beginTransaction() throws
    func commitTransaction() throws
    func cancelTransactionIfNeeded() throws

    // MARK: Read

    func readAllTags() -> Result<[ReferenceTag], ClipStorageError>

    // MARK: Create

    func create(tag: ReferenceTag) -> Result<Void, ClipStorageError>

    // MARK: Update

    func updateTag(having id: ReferenceTag.Identity, nameTo name: String) -> Result<Void, ClipStorageError>

    // MARK: Delete

    func deleteTags(having ids: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError>
}
