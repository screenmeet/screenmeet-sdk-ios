//
//  ScreenmeetWebRtcClient.swift
//  iOS-Prototype-SDK
//
//  Created by Vasyl Morarash on 20.05.2020.
//

import Foundation

class ScreenmeetWebRtcClient: NSObject {
    public var lCapturer: ScreenVideoCapturer! = nil
    var rtcVideoSource: RTCVideoSource! = nil
    public var peerClients:[String:ScreenmeetWebRtcPeerClient] = [:]
    public var localVideoTrack: RTCVideoTrack! = nil
    public var factory: RTCPeerConnectionFactory! = nil
    public var config: RTCConfiguration! = nil
    //public var currentWebRTCConfig = MainConfig.getWebRTCConfig()
    public var onDisconnect: (() -> Void)! = nil

    public let WebRTCSessionID = String(UUID().uuidString.prefix(4))

    let kARDMediaStreamId = "ScreenMeet"
    let kARDVideoTrackId = "ScreenMeetv0"

    public init(iceServersConfig: [[String: Any]]) {
        super.init()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        let encoderFactory = ScreenMeetVideoEncoderFactory()
        
        factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
        
        var iceServers = [RTCIceServer]()
        for iceServerConfig in iceServersConfig {
            let urls = iceServerConfig["urls"] as! String
            if let username = iceServerConfig["username"] as? String {
                iceServers.append(RTCIceServer(urlStrings: [urls], username: username, credential: iceServerConfig["credential"] as? String))
            } else {
                iceServers.append(RTCIceServer(urlStrings: [urls]))
            }
        }
        config = RTCConfiguration()
        config.iceServers = iceServers
        config.sdpSemantics = .unifiedPlan
        
        let pcert = RTCCertificate.generate(withParams: ["expires" : 100000, "name" : "RSASSA-PKCS1-v1_5"])
        config.certificate = pcert

        rtcVideoSource = factory.videoSource()
        
        rtcVideoSource.adaptOutputFormat(
            toWidth:    Int32(UIScreen.main.bounds.width),
            height:     Int32(UIScreen.main.bounds.height),
            fps:        Int32(60)
        )

        let capturer = ScreenVideoCapturer(delegate: rtcVideoSource, client: self)
        if capturer.captureSession.canSetSessionPreset(AVCaptureSession.Preset.high) {
            capturer.captureSession.sessionPreset = AVCaptureSession.Preset.high
        }

        lCapturer = capturer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.startCapture(capturer: capturer) {
                Logger.log.info("Capturer started")
            }
        }

        localVideoTrack = factory.videoTrack(with: rtcVideoSource, trackId: kARDVideoTrackId)
    }
    
    public func newViewer(remoteID: String, callback: @escaping (_ rtcSessionDescription: RTCSessionDescription?)->Void){
        let peerClient = ScreenmeetWebRtcPeerClient(mainClient: self,remoteId: remoteID)
        self.peerClients[remoteID] = peerClient
        peerClient.doOffer(callback: callback)
    }
    
    public func setRemoteDescription(remoteID: String, remoteSDP: String) {
        self.peerClients[remoteID]!.setRemoteDescription(remoteSDP: remoteSDP)
    }
    
    public func addIceCandidate(remoteID: String, sdp: String, sdpMLineIndex: Int, sdpMid: String?) {
        self.peerClients[remoteID]!.addIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
    
    func startCapture(capturer: ScreenVideoCapturer, callback: @escaping () -> Void) {
        capturer.startCaptureScreen({
            DispatchQueue.main.async {
                callback()
            }
        })
    }
    
    func updateCaptureSettings() {
        lCapturer.reconfigureCaptureSessionInput()
    }
    
    func stopCapture(completionHandler: (() -> Void)?) {
        if let capturer = self.lCapturer {
            capturer.stopCapture(completionHandler: completionHandler)
        } else {
            if let onComplete = completionHandler {
                onComplete()
            }
        }
    }
    
    var lastFrameSentTime: TimeInterval! = nil

    public func isConnected() -> Bool {
        for pc in self.peerClients.values {
            if pc.peerConnection != nil && pc.peerConnection.iceConnectionState == RTCIceConnectionState.connected {
                return true
            }
        }
        return false
    }
    
    public func isWebRTCActive() -> Bool {
        if isConnected() {
            if let lfsTime = self.lastFrameSentTime {
                let cTime = Date().timeIntervalSince1970
                return cTime < lfsTime + 1
            }
        }
        return false
    }
    
    public func onWebRTCFrameSent() {
        self.lastFrameSentTime = Date().timeIntervalSince1970
    }
    
    public func onWebRTCFailed(_ error: Error!, turnOffWebRTC: Bool = true) {
        if let e = error {
            Logger.log.error("WebRTC Failed: \(e.localizedDescription)")
        }
    }
}

class ScreenmeetWebRtcPeerClient: NSObject,RTCPeerConnectionDelegate {

    var remoteID:String = ""
    var mainClient:ScreenmeetWebRtcClient! = nil


    var peerConnection: RTCPeerConnection! = nil
    
    init(mainClient: ScreenmeetWebRtcClient,remoteId: String) {
        self.mainClient = mainClient
        self.remoteID = remoteId
    }
    
    public func doOffer(callback: @escaping (_ rtcSessionDescription: RTCSessionDescription?)->Void) {
        let mandatoryConstraints = [
            kRTCMediaConstraintsOfferToReceiveAudio : kRTCMediaConstraintsValueFalse,
            kRTCMediaConstraintsOfferToReceiveVideo : kRTCMediaConstraintsValueTrue,
            kRTCMediaConstraintsIceRestart : kRTCMediaConstraintsValueTrue,
        ]
        
        let optionalConstraints = [
            "DtlsSrtpKeyAgreement" : "true"
        ]
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: optionalConstraints)
        peerConnection = mainClient.factory.peerConnection(with: self.mainClient.config, constraints: constraints, delegate: self)
        self.peerConnection.add(mainClient.localVideoTrack, streamIds: [mainClient.kARDMediaStreamId])
        var _: RTCRtpTransceiver = self.peerConnection.addTransceiver(with: mainClient.localVideoTrack)
        
        
        peerConnection.offer(for: RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: optionalConstraints), completionHandler: {rtcSessionDescription, error in
            if (error == nil) {
                DispatchQueue.main.async {
                    self.peerConnection.setLocalDescription(rtcSessionDescription!, completionHandler: { error in
                        if let e = error {
                            Logger.log.error("Set local description Error: \(error?.localizedDescription ?? "")")
                            self.mainClient.onWebRTCFailed(e)
                        }
                    })
                }
                DispatchQueue.main.async {
                    callback(rtcSessionDescription)
                }
            } else {
                self.mainClient.onWebRTCFailed(error)
            }
        })
    }

    func setRemoteDescription(remoteSDP: String) {
        peerConnection.setRemoteDescription(RTCSessionDescription(type: .answer, sdp: remoteSDP), completionHandler: { error in
            if let e = error {
                Logger.log.error("Remote descriptor setting error: \(String(describing: error))")
                self.mainClient.onWebRTCFailed(e)
            }
        })
    }
    
    func addIceCandidate(sdp: String, sdpMLineIndex: Int, sdpMid: String?) {
        peerConnection.add(RTCIceCandidate(sdp: sdp,sdpMLineIndex: Int32(sdpMLineIndex),sdpMid: sdpMid))
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
    }
    
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
        if newState == .disconnected || newState == .failed {
            self.mainClient.onDisconnect?()
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {

    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        DispatchQueue.main.async {
            if let janusChannel = ChannelManager.shared.getChannel(ChannelName.janus) as? JanusChannel {
                janusChannel.addIceCandidate(candidate: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid)
            }
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
    }
}

@objc class ScreenMeetVideoEncoderFactory: NSObject, RTCVideoEncoderFactory {
    
    public func supportedCodecs() -> [RTCVideoCodecInfo] {
        
        let constrainedHighParams = [
            "profile-level-id" : kRTCMaxSupportedH264ProfileLevelConstrainedHigh,
            "level-asymmetry-allowed" : "1",
            "packetization-mode" : "1"]
        
        let constrainedBaselineParams = [
            "profile-level-id" : kRTCMaxSupportedH264ProfileLevelConstrainedBaseline,
            "level-asymmetry-allowed" : "1",
            "packetization-mode" : "1"]
        
        Logger.log.debug("Constrained High Params: \(constrainedHighParams)")
        Logger.log.debug("Constrained Baseline Params: \(constrainedBaselineParams)")
        
        var selectedCodec: RTCVideoCodecInfo


            selectedCodec  = RTCVideoCodecInfo(name: kRTCVp8CodecName)
            return [selectedCodec]
    }
    
    @objc public func createEncoder(_ info: RTCVideoCodecInfo) -> RTCVideoEncoder? {
        var encoder: RTCVideoEncoder? = nil
        
        switch info.name {
        case kRTCVideoCodecH264Name:
            encoder = ScreenMeetVideoEncoderH264(codecInfo: info)
        case kRTCVp9CodecName:
            encoder = RTCVideoEncoderVP9.vp9Encoder()
        default:
            encoder = RTCVideoEncoderVP8.vp8Encoder()
        }
        
        return encoder
    }
}

@objc class ScreenMeetVideoEncoderH264: RTCVideoEncoderH264 {
    
    public override func startEncode(with settings: RTCVideoEncoderSettings, numberOfCores: Int32) -> Int {
        
        let mySettings = settings
        mySettings.mode = RTCVideoCodecMode.screensharing
        mySettings.qpMax = 0
        
        return super.startEncode(with: mySettings, numberOfCores: numberOfCores)
    }
    
    @objc public override func scalingSettings() -> RTCVideoEncoderQpThresholds? {
        return nil//super.scalingSettings()
    }
    
    
}

