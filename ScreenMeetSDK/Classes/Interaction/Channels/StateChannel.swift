//
//  StateChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 22.07.2020.
//

import Foundation

class StateChannel: Channel {
    
    var name: ChannelName = .state
    
    func pauseStream(completion: @escaping () -> Void) {
        requestSet(data: RequestSetModel(value: ["room": "open", "stream": "paused", "broadcast": "paused"])) {
            completion()
        }
    }
    
    func resumeStream(completion: @escaping () -> Void) {
        requestSet(data: RequestSetModel(value: ["room": "open", "stream": "broadcasting", "broadcast": "live"])) {
            completion()
        }
    }
}
