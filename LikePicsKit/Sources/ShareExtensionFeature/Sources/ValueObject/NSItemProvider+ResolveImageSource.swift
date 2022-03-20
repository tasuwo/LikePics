//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import MobileCoreServices
import UIKit

extension NSItemProvider {
    func resolveImageSource() -> Future<ImageSource?, Never> {
        // swiftlint:disable:next unowned_variable_capture
        return Future { [unowned self] promise in
            self.resolveImageSource {
                promise(.success($0))
            }
        }
    }

    private func resolveImageSource(_ completion: @escaping (ImageSource?) -> Void) {
        if hasItemConformingToTypeIdentifier(kUTTypeFileURL as String) {
            loadItem(forTypeIdentifier: kUTTypeFileURL as String, options: nil) { item, _ in
                guard let url = item as? URL else {
                    completion(nil)
                    return
                }
                completion(.fileUrl(url))
            }
            return
        }

        if hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
            loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { item, _ in
                guard let url = item as? URL else {
                    completion(nil)
                    return
                }
                completion(.webUrl(url))
            }
            return
        }

        if hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
            completion(.data(.init(self)))
            return
        }

        completion(nil)
    }
}
