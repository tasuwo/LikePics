//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie

public class ImageSourceLoader {
    public init() {}
}

extension ImageSourceLoader: ImageLoadable {
    // MARK: - ImageLoadable

    public func load(for request: LegacyImageRequest, completion: @escaping (Data?) -> Void) {
        guard let source = request as? ImageSource else {
            completion(nil)
            return
        }

        switch source.value {
        case let .imageProvider(provider):
            provider.load(completion)

        case let .fileUrl(url):
            guard let data = try? Data(contentsOf: url) else {
                completion(nil)
                return
            }
            completion(data)

        case let .urlSet(urlSet):
            let semaphore = DispatchSemaphore(value: 0)

            var result: Data?
            let task = URLSession.shared.dataTask(with: urlSet.url) { data, _, _ in
                result = data
                semaphore.signal()
            }
            task.resume()

            if semaphore.wait(timeout: .now() + 5) == .timedOut {
                completion(nil)
                return
            }

            completion(result)
        }
    }
}

extension ImageSource: LegacyImageRequest {}
