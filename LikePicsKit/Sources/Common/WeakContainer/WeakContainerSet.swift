//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public class WeakContainerSet<T> {
    private var containers: [WeakContainer<T>]

    // MARK: - Initializers

    public init() {
        containers = []
    }

    public init(_ containers: [WeakContainer<T>]) {
        self.containers = containers
    }

    // MARK: - Methods

    public subscript(_ index: Int) -> WeakContainer<T> {
        get {
            clean()
            return containers[index]
        }
        set {
            clean()
            containers[index] = newValue
        }
    }

    public func append(_ container: WeakContainer<T>) {
        clean()
        containers.append(container)
    }

    public func forEach(_ body: (WeakContainer<T>) -> Void) {
        clean()
        containers.forEach(body)
    }

    // MARK: - Privates

    private func clean() {
        containers = containers.filter { container -> Bool in
            return container.value != nil
        }
    }
}
