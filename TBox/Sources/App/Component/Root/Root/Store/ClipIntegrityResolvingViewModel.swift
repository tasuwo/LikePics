//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxCore

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
    var allLoadingTargetCount: CurrentValueSubject<Int?, Never> { get }
    var loadingTargetIndex: CurrentValueSubject<Int?, Never> { get }
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
    let allLoadingTargetCount: CurrentValueSubject<Int?, Never> = .init(nil)
    let loadingTargetIndex: CurrentValueSubject<Int?, Never> = .init(nil)

    // MARK: Privates

    private let persistService: TemporariesPersistServiceProtocol
    private let integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol
    private let darwinNotificationCenter: DarwinNotificationCenterProtocol
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.ClipIntegrityResolvingViewModel", qos: .userInteractive)

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(persistService: TemporariesPersistServiceProtocol,
         integrityValidationService: ClipReferencesIntegrityValidationServiceProtocol,
         darwinNotificationCenter: DarwinNotificationCenterProtocol)
    {
        self.persistService = persistService
        self.integrityValidationService = integrityValidationService
        self.darwinNotificationCenter = darwinNotificationCenter

        self.bind()

        darwinNotificationCenter.addObserver(self, for: .shareExtensionDidCompleteRequest) { [weak self] _ in
            self?.queue.async {
                self?.isLoading.send(true)
                if self?.persistService.persistIfNeeded() == false {
                    self?.integrityValidationService.validateAndFixIntegrityIfNeeded()
                }
                self?.finishLoading()
            }
        }
    }

    // MARK: - Methods

    private func finishLoading() {
        self.isLoading.send(false)
        self.allLoadingTargetCount.send(nil)
        self.loadingTargetIndex.send(nil)
    }
}

extension ClipIntegrityResolvingViewModel {
    // MARK: - Bind

    private func bind() {
        self.persistService.set(observer: self)

        self.inputs.didLaunchApp
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isLoading.send(true)
                _ = self.persistService.persistIfNeeded()
                self.integrityValidationService.validateAndFixIntegrityIfNeeded()
                self.finishLoading()
            }
            .store(in: &self.subscriptions)
    }
}

extension ClipIntegrityResolvingViewModel: TemporariesPersistServiceObserver {
    // MARK: - TemporariesPersistServiceObserver

    func temporariesPersistService(_ service: TemporariesPersistService, didStartThe index: Int, outOf count: Int) {
        self.outputs.allLoadingTargetCount.send(count)
        self.outputs.loadingTargetIndex.send(index)
    }
}
