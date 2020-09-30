//
//  ChannelProtocol.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 15.07.2020.
//

import Foundation

enum ChannelName: String {
    case chat               = "chat"
    case connections        = "connections"
    case hostCommands       = "host_commands"
    case janus              = "janus"
    case roomSettings       = "roomsettings"
    case state              = "state"
    case streamSettings     = "streamsettings"
    case system             = "system"
    case viewers            = "viewers"
    case laserPointer       = "lp"
    case permissionRequests = "permission_requests"
    case permissionGrants   = "permission_grants"
}

protocol Channel {
    
    var name: ChannelName { get }
    
    func subscribeHandler(data: [Any])
    
    func pubEventHandler(data: [Any])
    
    func removedEventHandler(data: [Any])
    
    func requestSet(data: RequestSetModel, completion: @escaping () -> Void)
}

extension Channel {
    
    func subscribeHandler(data: [Any]) { }
    
    func pubEventHandler(data: [Any]) { }
    
    func removedEventHandler(data: [Any]) { }
    
    func requestSet(data: RequestSetModel, completion: @escaping () -> Void) {
        NetworkManager.shared.requestSet(for: name, data: data, completion: completion)
    }
    
    func command(access: String, permission: Any, completion: @escaping ([Any]) -> ()) {
        NetworkManager.shared.command(for: name, access: access, permission: permission, completion: completion)
    }
}
