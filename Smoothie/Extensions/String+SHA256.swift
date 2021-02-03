//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CommonCrypto

public extension String {
    func sha256() -> String? {
        guard let data = self.data(using: .utf8) else { return nil }

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes {
            CC_SHA256($0.baseAddress, UInt32(data.count), &digest)
        }

        var sha256String = ""
        for byte in digest {
            sha256String += String(format: "%02x", UInt8(byte))
        }

        return sha256String.isEmpty ? nil : sha256String
    }
}
