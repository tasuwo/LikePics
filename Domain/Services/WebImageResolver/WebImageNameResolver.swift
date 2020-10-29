//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum WebImageNameResolver {
    public static func resolveFileName(from url: URL) -> String? {
        guard let lastComponent = url.pathComponents.last else {
            return nil
        }
        return NSString(string: lastComponent).deletingPathExtension
    }
}
