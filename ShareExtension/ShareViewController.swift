//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import MobileCoreServices
import Persistence
import Social
import UIKit

class ShareViewController: SLComposeServiceViewController {
    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        self.extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .forEach { item in
                item.attachments?
                    .compactMap { $0 }
                    .forEach { attachment in
                        attachment.resolveImage { result in
                            print(result)
                        }
                        attachment.resolveUrl { result in
                            print(result)
                        }
                        attachment.resolveText { result in
                            print(result)
                        }
                    }
            }

        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}
