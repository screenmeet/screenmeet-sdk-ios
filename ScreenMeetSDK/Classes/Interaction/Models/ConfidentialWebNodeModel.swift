//
//  ConfidentialWebNodeModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 25.11.2020.
//

import Foundation

struct ConfidentialWebNodeModel: Decodable {
    
    var id: UUID
    
    var left: CGFloat
    
    var top: CGFloat
    
    var width: CGFloat
    
    var height: CGFloat
}
