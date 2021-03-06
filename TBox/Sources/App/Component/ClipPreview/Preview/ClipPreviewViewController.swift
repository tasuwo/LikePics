//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit
import TBoxUIKit
import UIKit

class ClipPreviewViewController: UIViewController {
    typealias Store = ForestKit.Store<ClipPreviewViewState, ClipPreviewViewAction, ClipPreviewViewDependency>

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
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipPreviewViewReducer())

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.viewDidLayoutSubviews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewView.viewDidAppear()
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
        store.state
            .bind(\.source, to: \.source, on: previewView)
            .store(in: &subscriptions)

        store.state
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .bind(\.isDisplayingLoadingIndicator, to: \.isDisplayingLoadingIndicator, on: previewView)
            .store(in: &subscriptions)
        store.state
            .bind(\.isUserInteractionEnabled, to: \.isUserInteractionEnabled, on: previewView)
            .store(in: &subscriptions)

        store.state
            .bind(\.isDismissed) { [weak self] isDismissed in
                guard isDismissed else { return }
                self?.dismiss(animated: true, completion: nil)
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
