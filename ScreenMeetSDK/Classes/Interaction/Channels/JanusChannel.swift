//
//  JanusChannel.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 15.07.2020.
//

import Foundation

class JanusChannel: Channel {
    
    var name: ChannelName = .janus
    
    var sdpAnswerHandler: ((String) -> Void)? = nil
    
    var peerConfigHandler: (([[String: Any]]) -> Void)? = nil
    
    func pubEventHandler(data: [Any]) {
        guard let objectBody = data[1] as? [String: Any], let value = objectBody["value"] as? [String: Any] else { return }
        
        if let sdpAnswer = value["sdpAnswer"] as? [String: Any], let sdp = sdpAnswer["sdp"] as? String {
            self.sdpAnswerHandler?(sdp)
        }
        
        if let iceServers = value["iceServers"] as? [[String: Any]] {
            self.peerConfigHandler?(iceServers)
        }
    }
    
    func startPresenter(sdpOffer: String) {
        requestSet(data: RequestSetModel(key: "presenter", value: sdpOffer)) { }
    }
    
    func addIceCandidate(candidate: String, sdpMLineIndex: Int32, sdpMid: String?) {
        guard let sdpMid = sdpMid else { return }
        
        let iceCandidate = IceCandidateModel(candidate: candidate, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
        
        guard let jsonData = try? JSONEncoder().encode(iceCandidate), let jsonString = String(data: jsonData, encoding: .ascii) else { return }
        
        requestSet(data: RequestSetModel(key: "onIceCandidate", value: jsonString)) { }
    }
    
    func requestPeerConfig() {
        requestSet(data: RequestSetModel(key: "getPeerConfig", value: "")) { }
    }
    
    func stopPresenter() {
        requestSet(data: RequestSetModel(key: "stop", value: "")) { }
    }
}
