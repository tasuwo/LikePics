//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Foundation

public extension UserDefaults {
    static let appGroup: UserDefaults = UserDefaultsPlaceholder()
}

private class UserDefaultsPlaceholder: UserDefaults, @unchecked Sendable {
    override func object(forKey defaultName: String) -> Any? { fatalError("UserDefaults for appGroup is not set.") }
    override func url(forKey defaultName: String) -> URL? { fatalError("UserDefaults for appGroup is not set.") }
    override func array(forKey defaultName: String) -> [Any]? { fatalError("UserDefaults for appGroup is not set.") }
    override func dictionary(forKey defaultName: String) -> [String: Any]? { fatalError("UserDefaults for appGroup is not set.") }
    override func string(forKey defaultName: String) -> String? { fatalError("UserDefaults for appGroup is not set.") }
    override func stringArray(forKey defaultName: String) -> [String]? { fatalError("UserDefaults for appGroup is not set.") }
    override func data(forKey defaultName: String) -> Data? { fatalError("UserDefaults for appGroup is not set.") }
    override func bool(forKey defaultName: String) -> Bool { fatalError("UserDefaults for appGroup is not set.") }
    override func integer(forKey defaultName: String) -> Int { fatalError("UserDefaults for appGroup is not set.") }
    override func float(forKey defaultName: String) -> Float { fatalError("UserDefaults for appGroup is not set.") }
    override func double(forKey defaultName: String) -> Double { fatalError("UserDefaults for appGroup is not set.") }
    override func dictionaryWithValues(forKeys keys: [String]) -> [String: Any] { fatalError("UserDefaults for appGroup is not set.") }
    override func set(_ value: Any?, forKey defaultName: String) { fatalError("UserDefaults for appGroup is not set.") }
    override func set(_ value: Float, forKey defaultName: String) { fatalError("UserDefaults for appGroup is not set.") }
    override func set(_ value: Double, forKey defaultName: String) { fatalError("UserDefaults for appGroup is not set.") }
    override func set(_ value: Int, forKey defaultName: String) { fatalError("UserDefaults for appGroup is not set.") }
    override func set(_ value: Bool, forKey defaultName: String) { fatalError("UserDefaults for appGroup is not set.") }
    override func set(_ value: URL?, forKey defaultName: String) { fatalError("UserDefaults for appGroup is not set.") }
    override func removeObject(forKey defaultName: String) { fatalError("UserDefaults for appGroup is not set.") }
    override func register(defaults registrationDictionary: [String: Any]) { fatalError("UserDefaults for appGroup is not set.") }
}

extension UserDefaults: @unchecked @retroactive Sendable {}
