//
//  ViewersChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 15.07.2020.
//

import Foundation

class ViewersChannel: Channel {
    
    var name: ChannelName = .viewers
    
    private var viewers = [ViewerModel]()
    
    func subscribeHandler(data: [Any]) {
        guard data.count > 1, let data = data[1] as? [String: Any] else { return }
        
        guard let serializedData = try? JSONSerialization.data(withJSONObject: data),
              let decodedObject = try? JSONDecoder().decode(ViewersListModel.self, from: serializedData) else { return }
        
        let viewerList = decodedObject.value
        viewers.append(contentsOf: viewerList)
        
        viewerList.forEach { ChannelManager.shared.eventListener?.join(viewer: $0) }
    }
    
    func pubEventHandler(data: [Any]) {
        guard data.count > 1, let data = data[1] as? [String: Any] else { return }
        
        guard let serializedData = try? JSONSerialization.data(withJSONObject: data),
              let decodedObject = try? JSONDecoder().decode(ViewerWrapperModel.self, from: serializedData) else { return }
        
        let viewer = decodedObject.value
        
        guard !viewers.contains(where: { $0.cid == viewer.cid }) else { return }
        viewers.append(viewer)
        ChannelManager.shared.eventListener?.join(viewer: viewer)
    }
    
    func removedEventHandler(data: [Any]) {
        guard data.count > 1, let cid = data[1] as? String, let index = viewers.firstIndex(where: { $0.cid == cid }) else { return }
        
        let viewer = viewers.remove(at: index)
        ChannelManager.shared.eventListener?.left(viewer: viewer)
    }
}
