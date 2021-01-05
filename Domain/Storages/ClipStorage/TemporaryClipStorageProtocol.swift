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

    func readAllClips() -> Result<[Clip], ClipStorageError>

    // MARK: Create

    func create(clip: Clip) -> Result<Clip, ClipStorageError>

    // MARK: Delete

    func deleteClips(having ids: [Clip.Identity]) -> Result<[Clip], ClipStorageError>
    func deleteAll() -> Result<Void, ClipStorageError>
}
