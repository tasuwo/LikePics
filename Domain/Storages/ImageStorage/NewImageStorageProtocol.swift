//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol NewImageStorageProtocol {
    // MARK: Transaction

    var isInTransaction: Bool { get }
    func beginTransaction() throws
    func commitTransaction() throws
    func cancelTransactionIfNeeded() throws

    // MARK: Create

    func create(_ image: Data, id: UUID) throws

    // MARK: Delete

    func delete(having id: UUID) throws

    // MARK: Read

    func read(having id: UUID) throws -> Data?
}
