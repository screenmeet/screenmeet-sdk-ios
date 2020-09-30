//
//  SystemChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 22.07.2020.
//

import Foundation

class SystemChannel: Channel {
    
    var name: ChannelName = .system
    
    func subscribeHandler(data: [Any]) {
        let systemInfo = SystemInfoModel()
        
        guard let data = try? JSONEncoder().encode(systemInfo), let systemInfoDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
    
        requestSet(data: RequestSetModel(value: systemInfoDict)) { }
    }
}
