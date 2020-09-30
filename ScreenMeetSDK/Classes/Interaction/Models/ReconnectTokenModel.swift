//
//  ReconnectTokenModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 17.07.2020.
//

import Foundation

struct ReconnectTokenModel: Decodable {
    
    var id: String
    
    var overrideToken: String
    
    var reconnectToken: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case overrideToken = "override_token"
        case reconnectToken = "reconnect_token"
    }
}
