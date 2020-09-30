//
//  LifecycleListener.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 26.08.2020.
//

import Foundation

/// Listener for lifcycle-related state of for the session
public protocol LifecycleListener: class {
    
    var lid: UUID { get }
    
    /// Sesson stream was started or restored
    /// - Parameter oldState:        Previous state value
    /// - Parameter streamingReason: Reason why state was changed
    func onStreaming(oldState: ScreenMeet.Session.State, streamingReason: ScreenMeet.Session.State.StreamingReason)
        
    /// Sesson stream was started or restored
    /// - Parameter oldState:        Previous state value
    /// - Parameter inactiveReason:  Reason why state was changed
    func onInactive(oldState: ScreenMeet.Session.State, inactiveReason: ScreenMeet.Session.State.InactiveReason)
    
    /// Sesson stream was started or restored
    /// - Parameter oldState:        Previous state value
    /// - Parameter pauseReason:     Reason why state was changed
    func onPause(oldState: ScreenMeet.Session.State, pauseReason: ScreenMeet.Session.State.PauseReason)
    
    /// Is called when application fased with network issues and trys to restore connection
    func networkDisconnect()
    
    /// Is called when application restored network connection
    func networkReconnect()
}

public extension LifecycleListener {
    
    var lid: UUID {
        return UUID()
    }
}

class WeakLifecycleListener {
    
    weak var value: LifecycleListener?

    init(_ value: LifecycleListener?) {
        self.value = value
    }
}

extension Array where Element: WeakLifecycleListener {
    
    func onStreaming(oldState: ScreenMeet.Session.State, streamingReason: ScreenMeet.Session.State.StreamingReason) {
        self.forEach { $0.value?.onStreaming(oldState: oldState, streamingReason: streamingReason) }
    }
    
    func onInactive(oldState: ScreenMeet.Session.State, inactiveReason: ScreenMeet.Session.State.InactiveReason) {
        self.forEach { $0.value?.onInactive(oldState: oldState, inactiveReason: inactiveReason) }
    }
    
    func onPause(oldState: ScreenMeet.Session.State, pauseReason: ScreenMeet.Session.State.PauseReason) {
        self.forEach { $0.value?.onPause(oldState: oldState, pauseReason: pauseReason) }
    }
    
    func networkDisconnect() {
        self.forEach { $0.value?.networkDisconnect() }
    }
    
    func networkReconnect() {
        self.forEach { $0.value?.networkReconnect() }
    }
}
