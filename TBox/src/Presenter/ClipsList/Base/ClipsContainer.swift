//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsContainer: AnyObject {
    var clips: [Clip] { get set }
}
