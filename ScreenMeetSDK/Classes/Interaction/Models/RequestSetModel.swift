//
//  RequestSetModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 17.07.2020.
//

import Foundation
import SocketIO

struct RequestSetModel: SocketData {
    
    var key: String?
    
    var value: Any
    
    var timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    
    var source: String = "test"
    
    func socketRepresentation() -> SocketData {
        var data = [Any]()
        
        if let key = key {
            data.append(key)
        }
        
        data.append(value)
        data.append(timestamp)
        data.append(source)
        
        return data
    }
}
