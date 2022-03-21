//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Environment
import Foundation

typealias SettingsViewDependency = HasCloudAvailabilityService
    & HasUserSettingStorage
    & HasDiskCaches

struct SettingsViewReducer: Reducer {
    typealias Dependency = SettingsViewDependency
    typealias State = SettingsViewState
    typealias Action = SettingsViewAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return Self.prepare(state: state, dependency: dependency)

        // MARK: State Observation

        case let .itemsVisibilityUpdated(isHidden):
            nextState.isSomeItemsHidden = isHidden
            return (nextState, .none)

        case let .iCloudSyncAvailabilityUpdated(isEnabled):
            nextState.isICloudSyncEnabled = isEnabled
            return (nextState, .none)

        case let .cloudAvailabilityUpdated(availability: availability):
            nextState.cloudAvailability = availability
            return (nextState, .none)

        // MARK: Control

        case let .itemsVisibilityChanged(isHidden):
            dependency.userSettingStorage.set(showHiddenItems: !isHidden)
            nextState.isSomeItemsHidden = isHidden
            return (nextState, .none)

        case let .iCloudSyncAvailabilityChanged(isEnabled):
            guard let availability = state.cloudAvailability else {
                return (nextState, .none)
            }

            // iCloudが利用不可な場合は、内部状態を書き換えるか確認する
            if isEnabled, availability == .unavailable {
                if dependency.userSettingStorage.readEnabledICloudSync() {
                    nextState.alert = .iCloudSettingForceTurnOffConfirmation
                } else {
                    nextState.alert = .iCloudSettingForceTurnOnConfirmation
                }
                nextState.isICloudSyncAvailabilitySetting = true
                return (nextState, .none)
            }

            if isEnabled {
                dependency.userSettingStorage.set(enabledICloudSync: true)
            } else {
                nextState.alert = .iCloudTurnOffConfirmation
                nextState.isICloudSyncAvailabilitySetting = true
            }

            return (nextState, .none)

        case .clearAllCache:
            nextState.alert = .clearAllCacheConfirmation
            return (nextState, .none)

        // MARK: Alert Completion

        case .iCloudForceTurnOffConfirmed:
            nextState.alert = nil
            nextState.isICloudSyncAvailabilitySetting = false
            dependency.userSettingStorage.set(enabledICloudSync: false)
            return (nextState, .none)

        case .iCloudForceTurnOnConfirmed:
            nextState.alert = nil
            nextState.isICloudSyncAvailabilitySetting = false
            dependency.userSettingStorage.set(enabledICloudSync: true)
            return (nextState, .none)

        case .iCloudTurnOffConfirmed:
            nextState.alert = nil
            nextState.isICloudSyncAvailabilitySetting = false
            dependency.userSettingStorage.set(enabledICloudSync: false)
            return (nextState, .none)

        case .clearAllCacheConfirmed:
            dependency.clipDiskCache.removeAll()
            dependency.albumDiskCache.removeAll()
            dependency.clipItemDiskCache.removeAll()
            nextState.alert = nil
            return (nextState, .none)

        case .alertDismissed:
            nextState.alert = nil
            nextState.isICloudSyncAvailabilitySetting = false
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension SettingsViewReducer {
    private static func prepare(state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        let settingStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.itemsVisibilityUpdated(isHidden: !$0) as Action? }
            .eraseToAnyPublisher()
        let settingEffect = Effect(settingStream)

        let availabilityStream = dependency.cloudAvailabilityService.availability
            .catch { _ in Just(.unavailable) }
            .map { Action.cloudAvailabilityUpdated(availability: $0) as Action? }
        let availabilityEffect = Effect(availabilityStream)

        let syncSettingStream = dependency.userSettingStorage.enabledICloudSync
            .map { Action.iCloudSyncAvailabilityUpdated(isEnabled: $0) as Action? }
        let syncSettingEffect = Effect(syncSettingStream)

        var nextState = state
        nextState.isSomeItemsHidden = !dependency.userSettingStorage.readShowHiddenItems()
        nextState.isICloudSyncEnabled = dependency.userSettingStorage.readEnabledICloudSync()
        nextState.cloudAvailability = nil
        // swiftlint:disable:next force_cast force_unwrapping
        nextState.version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

        return (nextState, [settingEffect, availabilityEffect, syncSettingEffect])
    }
}
