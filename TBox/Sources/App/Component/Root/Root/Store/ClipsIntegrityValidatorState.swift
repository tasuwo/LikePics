//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct ClipsIntegrityValidatorState: Equatable {
    enum LoadState: Equatable {
        case loading(currentIndex: Int?, counts: Int?)
        case stopped

        var isLoading: Bool {
            switch self {
            case .loading:
                return true

            case .stopped:
                return false
            }
        }
    }

    var state: LoadState = .stopped
}
