//
//  ChannelManager.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 15.07.2020.
//

import Foundation

protocol ChannelEventListener {
    
    func join(viewer: ViewerModel)
    
    func left(viewer: ViewerModel)
    
    func laserPointerPermissionRequest()
    
    func laserPointerCancelRequest()
    
    func startLaserPointerSession()
    
    func updateLaserPointerCoordinates(_ x: CGFloat, _ y: CGFloat, withTap: Bool)
    
    func stopLaserPointerSession()
}

final class ChannelManager {
    
    private init() {
        channels.append(ChatChannel())
        channels.append(ConnectionsChannel())
        channels.append(HostCommandsChannel())
        channels.append(JanusChannel())
        channels.append(RoomSettingsChannel())
        channels.append(StateChannel())
        channels.append(StreamSettingsChannel())
        channels.append(SystemChannel())
        channels.append(ViewersChannel())
        channels.append(LaserPointerChannel())
        channels.append(PermissionGrantsChannel())
        channels.append(PermissionRequestsChannel())
    }
    
    static let shared = ChannelManager()
    
    var eventListener: ChannelEventListener?
    
    var channels = [Channel]()
    
    func getChannel(_ name: ChannelName) -> Channel? {
        return channels.filter({ (channel) -> Bool in
            channel.name == name
        }).first
    }
    
    func grantLaserPointerPermission(_ agree: Bool) {
        let pgChannel = ChannelManager.shared.getChannel(.permissionGrants) as? PermissionGrantsChannel
        pgChannel?.grantLaserPointerPermission(agree) { [weak self] (granted) in
            if (granted) {
                self?.eventListener?.startLaserPointerSession()
            }
        }
    }
}
