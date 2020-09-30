//
//  PermissionGrantsChannel.swift
//  ScreenMeetMacOS
//
//  Copyright © 2017 Screenmeet. All rights reserved.
//

import Foundation

class PermissionGrantsChannel: Channel {

    var name: ChannelName = .permissionGrants
    
    func subscribeHandler(data: [Any]) {
        let allData = data[1] as? [String: Any]
        let sharedData = allData?["sharedData"] as? [String: Any]
        
        if let sharedData = sharedData, let jsonData = try? JSONSerialization.data(withJSONObject: sharedData, options: .prettyPrinted) {
            if let wrapper = try? JSONDecoder().decode(PermissionGrantsModelWrapper.self, from: jsonData), let value = wrapper.permission {
                let perm = ChannelManager.shared.getChannel(.permissionRequests) as? PermissionRequestsChannel

                switch value.value {
                case .remoteControl:
                    perm?.CID = value.id
                case .laserPointer:
                    perm?.CID = value.id
                    ChannelManager.shared.eventListener?.startLaserPointerSession()
                case .unknown:
                    break
                }
            }
        }
    }
    
    func removedEventHandler(data: [Any]) {
        ChannelManager.shared.eventListener?.stopLaserPointerSession()
    }
    
    func grantLaserPointerPermission(_ isAllowed: Bool, callback: @escaping (_ granted: Bool) -> Void) {
        let permissionRequestsChannel = ChannelManager.shared.getChannel(.permissionRequests) as? PermissionRequestsChannel
        
        guard let cidValue = permissionRequestsChannel?.CID else {
            //If no CID value then no response received from support helper / malformed data or non-existent permission_requests channel. In either case; setup has failed.
            return
        }
        
        let access = isAllowed ? "grant" : "deny"
        let permission = ["cid" : cidValue, "operation" : "laser-pointer"]
        
        self.command(access: access, permission: permission, completion: { (data) in
            guard let ackObject = data[0] as? [String: Any] else {
                return
            }
            
            let success = ackObject["success"] as! Bool
            
            callback(success && isAllowed)
        })
    }
    
    func stopRemote() {
        self.command(access: "revokeAll", permission: NSNull(), completion: { (data) in })
    }
}
