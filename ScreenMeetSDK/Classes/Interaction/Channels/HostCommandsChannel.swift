//
//  HostCommandsChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 15.07.2020.
//

import Foundation

class HostCommandsChannel: Channel {
    
    var name: ChannelName = .hostCommands
    
    func subscribeHandler(data: [Any]) {
        requestSet(data: RequestSetModel(key: "hostTimeout", value: 300000)) { }
    }
}
