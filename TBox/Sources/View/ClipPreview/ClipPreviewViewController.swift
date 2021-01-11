//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

class ClipPreviewViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = ClipPreviewViewModelType

    private let factory: Factory
    private let viewModel: Dependency

    private var isInitialLoaded: Bool = false

    var itemId: ClipItem.Identity {
        return self.viewModel.outputs.itemIdValue
    }

    var itemUrl: URL? {
        return self.viewModel.outputs.itemUrlValue
    }

    private var subscriptions = Set<AnyCancellable>()

    @IBOutlet var previewView: ClipPreviewView!

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: Dependency)
    {
        self.factory = factory
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.bind(to: viewModel)

        self.previewView.source = self.viewModel.outputs.readPreview()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.previewView.shouldRecalculateInitialScale()
    }

    // MARK: - Methods

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.dismiss
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.displayImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.previewView.source = .image(.init(uiImage: image))
            }
            .store(in: &self.subscriptions)

        dependency.outputs.isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self.previewView)
            .store(in: &self.subscriptions)

        dependency.outputs.displayErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.subscriptions)
    }
}
