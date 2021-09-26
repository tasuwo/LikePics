//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie

public class ImageSourceLoader {
    public init() {}

    public func load(for source: ImageSource, completion: @escaping (Data?) -> Void) {
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
