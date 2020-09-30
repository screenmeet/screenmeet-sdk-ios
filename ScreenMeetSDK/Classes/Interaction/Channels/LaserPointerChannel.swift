//
//  LaserPointerChannel.swift
//  ScreenMeetMacOS
//
//  Copyright © 2017 Screenmeet. All rights reserved.
//

import Foundation

class LaserPointerChannel: Channel {
    
    var name: ChannelName = .laserPointer

    func pubEventHandler(data: [Any]) {
        //Changed this to a boolean test instead since 'objectkey' value was never returned.
        guard data[data.count-1] is String else {
            return
        }
        
        let onlyObjects = data.filter { $0 is NSDictionary }
        
        //Note: Need to investigate this. Why is there a need for a loop
        for jsonObject in onlyObjects {
            let value = ((jsonObject as! NSDictionary)["value"] as! NSDictionary)
            let event = value["ev"] as! String
            
            switch event {
            case "mousemove":
                self.extractCoordinate(value, mode: "LP", callback: { (point) in
                    ChannelManager.shared.eventListener?.updateLaserPointerCoordinates(point.x, point.y, withTap: false)
                })
            case "leftmousedown":
                self.extractCoordinate(value, mode: "LP", callback: { (point) in
                    ChannelManager.shared.eventListener?.updateLaserPointerCoordinates(point.x, point.y, withTap: true)
                })
            default:
                break
            }
        }
    }
    
    func extractCoordinate(_ object: NSDictionary, mode: String, callback: @escaping (_ point: CGPoint) -> ()) {
        // TODO: Move to Laser Pointer UI service
        guard let x = object["x"] as? CGFloat else { return }
        guard let y = object["y"] as? CGFloat else { return }
        
        DispatchQueue.main.async {
            // translation calculation for selected screen
            let scale: CGFloat = 1.0
                
            let selectedScreenBounds = UIScreen.main.bounds
            
            var xTranslated: CGFloat = 0.0
            var yTranslated: CGFloat = 0.0
            
            if mode == "LP" {
                xTranslated = x / (scale)
                yTranslated = (selectedScreenBounds.size.height) - y / (scale)
            } else {
                xTranslated = x / (scale) + (selectedScreenBounds.origin.x)
                yTranslated = y / (scale) + (selectedScreenBounds.origin.y)
            }
            
            callback(CGPoint.init(x: xTranslated, y: yTranslated))
        }
    }
}
