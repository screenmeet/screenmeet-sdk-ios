//
//  PermissionGrantsModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 08.09.2020.
//

import Foundation

struct PermissionGrantsModelWrapper {
    
    var permission: PermissionGrantsModel?
}

extension PermissionGrantsModelWrapper: Decodable {
    
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
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        var permissionGrants: [PermissionGrantsModel] = []

        for key in container.allKeys {
            if var permissionGrant: PermissionGrantsModel = try? container.decode(PermissionGrantsModel.self, forKey: CodingKeys(value: key.stringValue)) {
                permissionGrant.id = key.stringValue
                if permissionGrant.value != .unknown {
                    permissionGrants.append(permissionGrant)
                }
            }
        }
        
        permissionGrants.sort { $0.ts > $1.ts }
        
        self.permission = permissionGrants.first
    }
}

// MARK: PermissionGrantsModel
struct PermissionGrantsModel {
    
    var id: String
    
    var ts: Int64
    
    var value: Value
    
    enum Value: String {
        case remoteControl = "remote-control"
        case laserPointer = "laser-pointer"
        case unknown
    }
}

extension PermissionGrantsModel: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case ts
        case value = "value"
    }
    
    public init(from decoder: Decoder) throws {
        let container       = try decoder.container(keyedBy: CodingKeys.self)
        let ts              = try? container.decode(Int64.self, forKey: .ts)
        let value           = try? container.decode([String: Bool].self, forKey: .value)
        
        self.ts = ts ?? 0
        if value?.first?.value == true {
            self.value = Value(rawValue: value?.first?.key ?? "") ?? .unknown
        } else {
            self.value = .unknown
        }
        self.id = ""
    }
}
