//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

class ClipPreviewViewController: UIViewController {
    typealias Store = LikePics.Store<ClipPreviewViewState, ClipPreviewViewAction, ClipPreviewViewDependency>

    // MARK: - Properties

    // MARK: View

    let previewView = ClipPreviewView()

    // MARK: Store

    var itemId: ClipItem.Identity { store.stateValue.itemId }

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(state: ClipPreviewViewState,
         dependency: ClipPreviewViewDependency)
    {
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipPreviewViewReducer.self)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Life-Cycle Methods

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.shouldRecalculateInitialScale()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()

        bind(to: store)

        store.execute(.viewDidLoad)
    }
}

// MARK: - Bind

extension ClipPreviewViewController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            self.previewView.source = state.source
            self.previewView.isLoading = state.isLoading

            if state.isDismissed {
                self.dismiss(animated: true, completion: nil)
            }
        }
        .store(in: &subscriptions)
    }
}

// MARK: - Configuration

extension ClipPreviewViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = .clear

        previewView.backgroundColor = .clear
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        NSLayoutConstraint.activate(previewView.constraints(fittingIn: view))
    }
}
