//
//  SystemInfoModel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 21.09.2020.
//

import Foundation
import CoreTelephony

struct SystemInfoModel: Encodable {
    
    var displayInfo: String = "\(UIScreen.main.bounds.width)x\(UIScreen.main.bounds.height)"
    
    var deviceModel: String = UIDevice.current.modelName
    
    var deviceManufacturer: String = "Apple"
    
    var deviceIosVersion: String = UIDevice.current.systemVersion
    
    var buildNumber: String = ScreenMeet.version()
    
    var deviceTotalRam: String = UIDevice.current.totalRamInGB
    
    var deviceTotalStorage: String = UIDevice.current.totalDiskSpaceInGB
    
    var deviceAvailableStorage: String = UIDevice.current.freeDiskSpaceInGB
    
    var deviceBatteryStatus: String = UIDevice.current.batteryStatus
    
    var deviceBatteryLevel: String = UIDevice.current.batteryLevelInPercent
    
    var cellularProviders: String = UIDevice.current.cellularProviders
    
    var carrierType: String = UIDevice.current.carrierType
    
    var localeLanguage: String = Locale.current.languageCode ?? "-"
    
    var localeTime: String = Date().description(with: .current)
    
    private enum CodingKeys: String, CodingKey {
        case displayInfo = "display_info"
        case deviceModel = "device_model"
        case deviceManufacturer = "device_manufacturer"
        case deviceIosVersion = "device_os_version"
        case buildNumber = "build_number"
        case deviceTotalRam = "device_total_ram"
        case deviceTotalStorage = "device_total_storage"
        case deviceAvailableStorage = "device_available_storage"
        case deviceBatteryStatus = "device_battery_status"
        case deviceBatteryLevel = "device_battery_level"
        case cellularProviders = "cellular_providers"
        case carrierType = "carrier_type"
        case localeLanguage = "locale_language"
        case localeTime = "locale_time"
    }
}

fileprivate extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
          guard let value = element.value as? Int8, value != 0 else { return identifier }
          return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }
    
    var batteryStatus: String {
        switch UIDevice.current.batteryState {
        case .unknown:
            return "Unknown"
        case .unplugged:
            return "Unplugged"
        case .charging:
            return "Charging"
        case .full:
            return "Full"
        @unknown default:
            return "Unknown"
        }
    }
    
    var batteryLevelInPercent: String {
        guard batteryLevel != -1 else { return "-" }
        return "\(Int(UIDevice.current.batteryLevel * 100))%"
    }
    
    var cellularProviders: String {
        let carriersNames = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.compactMap { $0.value.carrierName }
        return "[\(carriersNames?.joined(separator: ", ") ?? "-")]"
    }
    
    var carrierType: String {
        let networkInfo = CTTelephonyNetworkInfo()
        let carrierType = networkInfo.serviceCurrentRadioAccessTechnology?.first?.value
        switch carrierType{
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x: return "Edge"
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD : return "3G"
        case CTRadioAccessTechnologyLTE: return "LTE"
        default: return "-"
        }
    }
}


fileprivate extension UIDevice {
    
    var totalRamInGB: String {
        return ByteCountFormatter.string(fromByteCount: totalRamInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var totalDiskSpaceInGB: String {
       return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }

    var freeDiskSpaceInGB: String {
        return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }

    var usedDiskSpaceInGB: String {
        return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var totalRamInMB: String {
        return MBFormatter(totalRamInBytes)
    }

    var totalDiskSpaceInMB: String {
        return MBFormatter(totalDiskSpaceInBytes)
    }

    var freeDiskSpaceInMB: String {
        return MBFormatter(freeDiskSpaceInBytes)
    }

    var usedDiskSpaceInMB: String {
        return MBFormatter(usedDiskSpaceInBytes)
    }
    
    var totalRamInBytes: Int64 {
        return Int64(ProcessInfo.processInfo.physicalMemory)
    }
    
    var totalDiskSpaceInBytes: Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return 0 }
        return space
    }

    /*
     Total available capacity in bytes for "Important" resources, including space expected to be cleared by purging non-essential and cached resources. "Important" means something that the user or application clearly expects to be present on the local system, but is ultimately replaceable. This would include items that the user has explicitly requested via the UI, and resources that an application requires in order to provide functionality.
     Examples: A video that the user has explicitly requested to watch but has not yet finished watching or an audio file that the user has requested to download.
     This value should not be used in determining if there is room for an irreplaceable resource. In the case of irreplaceable resources, always attempt to save the resource regardless of available capacity and handle failure as gracefully as possible.
     */
    var freeDiskSpaceInBytes: Int64 {
        if #available(iOS 11.0, *) {
            if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                return space
            } else {
                return 0
            }
        } else {
            if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                return freeSpace
            } else {
                return 0
            }
        }
    }

    var usedDiskSpaceInBytes: Int64 {
       return totalDiskSpaceInBytes - freeDiskSpaceInBytes
    }
    
    func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }
}
