//
//  RoomSettingsChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 15.07.2020.
//

import Foundation

class RoomSettingsChannel: Channel {
    
    var name: ChannelName = .roomSettings
    
    func subscribeHandler(data: [Any]) {
        let roomSettings = RoomSettingsModel()
        
        guard let data = try? JSONEncoder().encode(roomSettings), let roomSettingsDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        requestSet(data: RequestSetModel(value: roomSettingsDict)) { }
    }
}
