//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import Foundation

public enum ClipCreationInput {
    case webPageURL(URL)
    case imageSources([ImageSource])
}
