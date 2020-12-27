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
        return self.viewModel.outputs.item.value.id
    }

    var itemUrl: URL? {
        return self.viewModel.outputs.item.value.url
    }

    private var cancellableBag = Set<AnyCancellable>()

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.viewModel.inputs.viewWillAppear.send(())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.viewModel.inputs.viewDidAppear.send(())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.bind(to: viewModel)

        if let image = self.viewModel.outputs.readInitialImage() {
            self.previewView.source = (image, image.size)
        }
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
            .store(in: &self.cancellableBag)

        dependency.outputs.imageLoaded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.previewView.source = (image, image.size)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)
    }
}
