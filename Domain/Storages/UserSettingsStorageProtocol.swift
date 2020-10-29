//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol UserSettingsStorageProtocol {
    var showHiddenItems: AnyPublisher<Bool, Never> { get }
    func set(showHiddenItems: Bool)
}
