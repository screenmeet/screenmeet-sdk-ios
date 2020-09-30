//
//  ViewerModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 27.08.2020.
//

import Foundation

struct ViewerModel: Decodable {
    
    var cid: String
    
    var ip: String
    
    var name: String
}

struct ViewerWrapperModel: Decodable {
    
    var value: ViewerModel
}

struct ViewersListModel: Decodable {
    
    var value: [ViewerModel]
    
    private struct CodingKeys: CodingKey {
            
        var stringValue: String
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        init(value: String) {
            self.stringValue = value
        }
        
        var intValue: Int?
        
        init?(intValue: Int) {
            return nil
        }
        
        static let sharedData = CodingKeys(value: "sharedData")
    }
    
    init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        let sharedData  = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .sharedData)
        
        var viewers = [ViewerModel]()
        
        for key in sharedData.allKeys {
            let viewer: ViewerWrapperModel = try sharedData.decode(ViewerWrapperModel.self, forKey: CodingKeys(value: key.stringValue))
            viewers.append(viewer.value)
        }
        
        self.value = viewers
    }
}
