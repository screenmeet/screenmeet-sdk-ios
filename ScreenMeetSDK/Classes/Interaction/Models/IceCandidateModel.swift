//
//  IceCandidateModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 17.07.2020.
//

import Foundation

struct IceCandidateModel: Encodable {
    
    var candidate: String
    
    var sdpMLineIndex: Int32
    
    var sdpMid: String
}
