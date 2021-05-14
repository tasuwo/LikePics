//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

protocol ActionConvertible {
    associatedtype Parent: Action
    associatedtype Child: Action
    func extract(from parent: Parent) -> Child?
    func convert(_ child: Child) -> Parent
}
