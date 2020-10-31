//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

public protocol ClipViewable {
    func clip(havingUrl url: URL) -> Result<TransferringClip?, Error>
}
