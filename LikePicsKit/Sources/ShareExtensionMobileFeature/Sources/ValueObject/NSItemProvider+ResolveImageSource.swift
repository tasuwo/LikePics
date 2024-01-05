//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit
import UniformTypeIdentifiers

extension NSItemProvider {
    func resolveImageSource() -> Future<SharedImageSource?, Never> {
        // swiftlint:disable:next unowned_variable_capture
        return Future { [unowned self] promise in
            self.resolveImageSource {
                promise(.success($0))
            }
        }
    }

    private func resolveImageSource(_ completion: @escaping (SharedImageSource?) -> Void) {
        if hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let url = item as? URL else {
                    completion(nil)
                    return
                }
                completion(.fileURL(url))
            }
            return
        }

        if hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                guard let url = item as? URL else {
                    completion(nil)
                    return
                }
                completion(.webPageURL(url))
            }
            return
        }

        if hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            completion(.data(.init(self)))
            return
        }

        completion(nil)
    }
}
