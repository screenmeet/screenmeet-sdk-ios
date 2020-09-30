//
//  ScreenmeetWebRtcSocketClient.swift
//  iOS-Prototype-SDK
//
//  Created by Vasyl Morarash on 20.05.2020.
//

import Foundation

enum WebRtcSocketClientState {
    case STOPED
    case STARTING
    case ACTIVE
    case STOPPING
}

class ScreenmeetWebRtcSocketClient {
    
    var webRTCStarted: Bool = false
    
    public static func WebRTCProcessing() -> Bool {
        if ScreenVideoCapturer.isWebRTCEnabled  {
            if let rtcClient = ScreenVideoCapturer.webRTCClient {
                if (rtcClient.state == .STOPED) {
                    rtcClient.startWebRTCSession()
                } else {
                    return rtcClient.rtcClient?.isWebRTCActive() ?? false
                }
            } else {
                ScreenVideoCapturer.webRTCClient = ScreenmeetWebRtcSocketClient()
                ScreenVideoCapturer.webRTCClient?.startWebRTCSession()
            }
        } else {
            if let rtcClient = ScreenVideoCapturer.webRTCClient {
                if (rtcClient.state == .STARTING || rtcClient.state == .ACTIVE) {
                    rtcClient.stopWebRTCSession(completionHandler: {
                    })
                }
            }
            ScreenVideoCapturer.webRTCClient = nil
        }
        return false
    }
    
    public static func changeFPS(newFPSvalue: Int) {
//        if let rtcClient = ScreenVideoCapturer.webRTCClient {
//            if let r = rtcClient.rtcClient {
//                r.currentWebRTCConfig.MaxFrameRate = newFPSvalue
//                MainConfig.currentSessionFPS = newFPSvalue
//                SMLogger.shared().logWebRTC("changeFPS to \(newFPSvalue)")
//            }
//        }
    }
    
    public var rtcClient: ScreenmeetWebRtcClient! = nil
    private var state = WebRtcSocketClientState.STOPED
    public func currentState()->WebRtcSocketClientState {
        return state
    }

    public func startWebRTCSession() {
        self.state = .STARTING
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.startWebRTCSessionInternal()
        }
    }
    
    private func startWebRTCSessionInternal() {
        if let janusChannel = ChannelManager.shared.getChannel(.janus) as? JanusChannel {
            
            janusChannel.peerConfigHandler = { config in
                self.rtcClient = ScreenmeetWebRtcClient(iceServersConfig: config)

                self.rtcClient.newViewer(remoteID: "1", callback: { sdp in
                    janusChannel.sdpAnswerHandler = { sdpAnswer in
                        if let client = self.rtcClient {
                            client.setRemoteDescription(remoteID: "1", remoteSDP: sdpAnswer)
                            self.state = .ACTIVE
                            NetworkManager.shared.requestSet(for: .hostCommands, data: RequestSetModel(key: "streamStarted", value: ["streamType": "webRTC"])) {
                                ScreenVideoCapturer.webRTCClient?.webRTCStarted = true
                                Logger.log.info("WebRTC Stream Started")
                            }
                        }
                    }
                    janusChannel.startPresenter(sdpOffer: sdp?.sdp ?? "")
                })
            }
            
            janusChannel.requestPeerConfig()
        } else {
            Logger.log.error("Error: JanusChannel not initialized")
        }
    }
    
    public func stopWebRTCSession(completionHandler: (() -> Void)!) {

        self.state = .STOPPING
        if let client = self.rtcClient {
            if let janusChannel = ChannelManager.shared.getChannel(ChannelName.janus) as? JanusChannel {
                janusChannel.stopPresenter()
            }
            client.stopCapture(completionHandler: {
                self.state = .STOPED

                if let ch = completionHandler {
                    ch()
                }
            })
            self.rtcClient = nil
        } else {
            self.state = .STOPED
        }
    }
    
}
