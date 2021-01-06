//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie

public class ImageSourceLoader {
    public init() {}
}

extension ImageSourceLoader: OriginalImageLoader {
    // MARK: - OriginalImageLoader

    public func loadData(with request: OriginalImageRequest) -> Data? {
        guard let source = request as? ImageSource else { return nil }

        switch source.value {
        case let .rawData(data):
            return data

        case let .urlSet(urlSet):
            let semaphore = DispatchSemaphore(value: 0)

            var result: Data?
            let task = URLSession.shared.dataTask(with: urlSet.url) { data, _, _ in
                result = data
                semaphore.signal()
            }
            task.resume()

            if semaphore.wait(timeout: .now() + 15) == .timedOut {
                return nil
            }

            return result
        }
    }
}

extension ImageSource: OriginalImageRequest {}
