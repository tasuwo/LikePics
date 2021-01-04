//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol ClipIntegrityResolvingViewModelType: AnyObject {
    var inputs: ClipIntegrityResolvingViewModelInputs { get }
    var outputs: ClipIntegrityResolvingViewModelOutputs { get }
}

protocol ClipIntegrityResolvingViewModelInputs {
    var didLaunchApp: PassthroughSubject<Void, Never> { get }
    var sceneDidBecomeActive: PassthroughSubject<Void, Never> { get }
}

protocol ClipIntegrityResolvingViewModelOutputs {
    var isLoading: CurrentValueSubject<Bool, Never> { get }
}

class ClipIntegrityResolvingViewModel: ClipIntegrityResolvingViewModelType,
    ClipIntegrityResolvingViewModelInputs,
    ClipIntegrityResolvingViewModelOutputs
{
    // MARK: - Properties

    // MARK: ClipIntegrityResolvingViewModelType

    var inputs: ClipIntegrityResolvingViewModelInputs { self }
    var outputs: ClipIntegrityResolvingViewModelOutputs { self }

    // MARK: ClipIntegrityResolvingViewModelInputs

    let didLaunchApp: PassthroughSubject<Void, Never> = .init()
    let sceneDidBecomeActive: PassthroughSubject<Void, Never> = .init()

    // MARK: ClipIntegrityResolvingViewModelOutputs

    let isLoading: CurrentValueSubject<Bool, Never> = .init(true)

    // MARK: Privates

    private let persistService: TemporariesPersistServiceProtocol
    private let integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.ClipIntegrityResolvingViewModel", qos: .userInteractive)

    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(persistService: TemporariesPersistServiceProtocol,
         integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol)
    {
        self.persistService = persistService
        self.integrityValidationService = integrityValidationService

        self.bind()
    }
}

extension ClipIntegrityResolvingViewModel {
    // MARK: - Bind

    private func bind() {
        self.inputs.didLaunchApp
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isLoading.send(true)
                _ = self.persistService.persistIfNeeded()
                self.integrityValidationService.validateAndFixIntegrityIfNeeded()
                self.isLoading.send(false)
            }
            .store(in: &self.cancellableBag)

        self.inputs.sceneDidBecomeActive
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isLoading.send(true)
                if self.persistService.persistIfNeeded() == false {
                    self.integrityValidationService.validateAndFixIntegrityIfNeeded()
                }
                self.isLoading.send(false)
            }
            .store(in: &self.cancellableBag)
    }
}
