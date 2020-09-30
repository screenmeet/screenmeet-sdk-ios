//
//  SessionEventListener.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 27.08.2020.
//

import Foundation

/// Listens for activity on this session
public protocol SessionEventListener: class {
    
    var sid: UUID { get }
    
    /// Called when a participant-related action occurs
    /// - Parameter participant: the participant (see `ScreenMeet.Session.Participant`)
    /// - Parameter participantAction: the action that occurred (see `ScreenMeet.Session.ParticipantAction`)
    func onParticipantAction(participant: ScreenMeet.Session.Participant, participantAction: ScreenMeet.Session.ParticipantAction)
}

public extension SessionEventListener {
    
    var sid: UUID {
        return UUID()
    }
}

class WeakSessionEventListener {
    
    weak var value: SessionEventListener?

    init(_ value: SessionEventListener?) {
        self.value = value
    }
}

extension Array where Element: WeakSessionEventListener {
    
    func onParticipantAction(participant: ScreenMeet.Session.Participant, participantAction: ScreenMeet.Session.ParticipantAction) {
        self.forEach { $0.value?.onParticipantAction(participant: participant, participantAction: participantAction) }
    }
}
