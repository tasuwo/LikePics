//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

public protocol ClipStorable {
    func create(clip: ClipRecipe, withContainers containers: [ImageContainer], forced: Bool) -> Result<Void, ClipStorageError>
}
