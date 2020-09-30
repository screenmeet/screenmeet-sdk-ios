//
//  RoomSettingsModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 20.07.2020.
//

import Foundation

struct RoomSettingsModel: Encodable {
    
    var clientsupport: Clientsupport = Clientsupport()

    struct Clientsupport: Encodable {
        
        var chat: Bool = false // TODO change value when chat will be implemented
        
        var filetransfer: String = "disabled"
        
        var laserpointer: Bool = true
        
        var whiteboard: Bool = false
        
        var reboot: Bool = false
        
        var remotecontrol: Bool = false
        
        var run: Bool = false
        
        var uac: Bool = false
        
        var windowstools: Bool = false
        
        var androidtools: Bool = false
        
        var mactools:  Bool = false
    }
    
    var displays: [Display] = [Display()]

    struct Display: Encodable {
        var id: Int = 1
        var scale: CGFloat = 1.0
        var rect: DisplayRest = DisplayRest()
    }
    
    struct DisplayRest: Encodable {
        var width: CGFloat = UIScreen.main.bounds.width
        var height: CGFloat = UIScreen.main.bounds.height
        var right: CGFloat = UIScreen.main.bounds.width
        var bottom: CGFloat = UIScreen.main.bounds.height
        var top: CGFloat = 0.0
        var left: CGFloat = 0.0
    }

    var dynamicStream: DynamicStream = DynamicStream()

    struct DynamicStream: Encodable {
        var platform: String = "ios"
        var res: DynamicStreamRes = DynamicStreamRes()
    }
    
    struct DynamicStreamRes: Encodable {
        var width: CGFloat = UIScreen.main.bounds.width
        var height: CGFloat = UIScreen.main.bounds.height
        var density: CGFloat = 1.0
    }
}
