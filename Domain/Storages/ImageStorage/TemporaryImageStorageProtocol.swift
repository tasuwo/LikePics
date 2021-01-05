//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol TemporaryImageStorageProtocol {
    func imageFileExists(named name: String, inClipHaving clipId: Clip.Identity) -> Bool
    func save(_ image: Data, asName fileName: String, inClipHaving clipId: Clip.Identity) throws
    func delete(fileName: String, inClipHaving clipId: Clip.Identity) throws
    func deleteAll(inClipHaving clipId: Clip.Identity) throws
    func deleteAll() throws
    func readImage(named name: String, inClipHaving clipId: Clip.Identity) throws -> Data?
}
