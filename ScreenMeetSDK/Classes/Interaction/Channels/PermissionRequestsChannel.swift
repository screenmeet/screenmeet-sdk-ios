//
//  PermissionRequestsChannel.swift
//  ScreenMeetMacOS
//
//  Copyright © 2017 Screenmeet. All rights reserved.
//

import Foundation

class PermissionRequestsChannel: Channel {

    var name: ChannelName = .permissionRequests    
    
    var CID: String?
    
    func pubEventHandler(data: [Any]) {
        
        let requestObject = data[1] as! [String : Any]
        
        guard let request = requestObject["value"] as? String else {
            return
        }
        
        self.CID = data[2] as? String
            
        if request == "laser-pointer" {
            ChannelManager.shared.eventListener?.laserPointerPermissionRequest()
        }
    }
    
    func removedEventHandler(data: [Any]) {
        ChannelManager.shared.eventListener?.laserPointerCancelRequest()
    }
}
