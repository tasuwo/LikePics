//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

/// @mockable
public protocol ImageStorageProtocol {
    // MARK: Transaction

    var isInTransaction: Bool { get }
    func beginTransaction() throws
    func commitTransaction() throws
    func cancelTransactionIfNeeded() throws

    // MARK: Create

    func create(_ image: Data, id: ImageContainer.Identity) throws

    // MARK: Delete

    func delete(having id: ImageContainer.Identity) throws

    // MARK: Read

    func exists(having id: ImageContainer.Identity) throws -> Bool
}
