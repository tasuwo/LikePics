//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol TemporaryClipStorageProtocol {
    // MARK: Transaction

    var isInTransaction: Bool { get }
    func beginTransaction() throws
    func commitTransaction() throws
    func cancelTransactionIfNeeded() throws

    // MARK: Read

    func readAllClips() -> Result<[ClipRecipe], ClipStorageError>

    // MARK: Create

    func create(clip: ClipRecipe) -> Result<ClipRecipe, ClipStorageError>

    // MARK: Delete

    func deleteClips(having ids: [Clip.Identity]) -> Result<[ClipRecipe], ClipStorageError>
    func deleteAll() -> Result<Void, ClipStorageError>
}
