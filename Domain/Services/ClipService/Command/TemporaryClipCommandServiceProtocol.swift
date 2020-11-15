//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol TemporaryClipCommandServiceProtocol {
    func create(clip: Clip, withContainers containers: [ImageContainer], forced: Bool) -> Result<Void, ClipStorageError>
}
