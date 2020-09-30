//
//  SessionModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 15.07.2020.
//

import Foundation

struct SessionModel: Decodable {
    
    var id: String
    
    var pin: Int
    
    var label: String
    
    var userDescription: String
    
    var hostAuthToken: String
    
    var socketUrl: URL {
        servers.support.endpoint
    }
    
    var servers: Servers
    
    var settings: Settings
    
    struct Servers: Decodable {
        
        var support: Support
        
        struct Support: Decodable {
            
            var id: Int
            
            var serverInstanceId: String
            
            var endpoint: URL
            
            var region: String
        }
    }
    
    struct Settings: Decodable {
        
        var recording: Bool
        
        var startwithrc: Bool
        
        var startwithadmin: Bool
    }
}
