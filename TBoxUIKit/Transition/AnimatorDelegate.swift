//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

protocol AnimatorDelegate: AnyObject {
    func animator(_ animator: Animator, didComplete: Bool)
}
