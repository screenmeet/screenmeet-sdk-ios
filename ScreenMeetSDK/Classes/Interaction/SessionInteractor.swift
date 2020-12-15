//
//  SessionInteractor.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 23.07.2020.
//

import Foundation

class SessionInteractor {
    
    var presenter: SessionPresenterOut?
    
    private var session: SessionModel?
    
    private var reconnectToken: ReconnectTokenModel?
    
    private var lastOperation: Operation? = nil
    
    private enum Operation {
        case pause
        case resume
    }
    
    private func childConnect(completion: @escaping () -> Void) {
        guard let session = session else { return }
        
        NetworkManager.shared.childConnect(authToken: session.hostAuthToken, reconnectToken: reconnectToken) { [weak self] reconnectToken in
            self?.reconnectToken = reconnectToken
            NetworkManager.shared.subscribeChannels() {
                completion()
            }
        }
    }
    
    func supportConnect(sessionCode: String, success: @escaping () -> Void, failure: @escaping (ScreenMeet.Session.SessionError) -> Void) {
        guard let organizationKey = ScreenMeet.shared.config.organizationKey, !organizationKey.isEmpty else {
            Logger.log.debug("Organization Key is not set")
            failure(.incorrectOrganizationKey)
            return
        }
        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: sessionCode)), sessionCode.count == 6 else {
            Logger.log.debug("REST incorrect session code")
            failure(.incorrectSessionCode)
            return
        }
        
        ChannelManager.shared.eventListener = self
        NetworkManager.shared.eventListener = self
        NetworkManager.shared.supportConnect(sessionCode: sessionCode) { [weak self] (result) in
            switch result {
            case .success(let session):
                self?.session = session
                success()
            case .failure(let error):
                switch error {
                case .clientError:
                    Logger.log.debug("REST connection timeout")
                    failure(.connectionTimeout)
                case .serverError(let code):
                    if let organizationKey = ScreenMeet.shared.config.organizationKey, !organizationKey.isEmpty {
                        Logger.log.debug("REST incorrect organization key")
                        failure(.incorrectOrganizationKey)
                    } else if code == 403 {
                        Logger.log.debug("REST session already connected")
                        failure(.sessionAlreadyConnected)
                    } else {
                        Logger.log.debug("REST session not fount")
                        failure(.sessionNotFound)
                    }
                default:
                    Logger.log.debug("REST session not fount")
                    failure(.sessionNotFound)
                }
            }
        }
    }
    
    func socketConnect(success: @escaping () -> Void) {
        guard let session = session else { return }
        
        NetworkManager.shared.socketConnect(socketUrl: session.socketUrl, sessionId: session.id, success: { [weak self] in
            self?.childConnect(completion: success)
        }) { [weak self] in
            ChannelManager.shared.eventListener = nil
            NetworkManager.shared.eventListener = nil
            ScreenVideoCapturer.webRTCClient?.stopWebRTCSession(completionHandler: { })
            self?.session = nil
            self?.reconnectToken = nil
            self?.presenter?.sessionTerminateEvent()
        }
    }
    
    func terminateSession() {
        NetworkManager.shared.socketTerminate()
    }
    
    func disconnectSession() {
        NetworkManager.shared.socketDisconnect()
    }
    
    func pauseStream() {
        guard ScreenVideoCapturer.webRTCClient?.webRTCStarted == true else { return }
        
        lastOperation = .pause
        NetworkManager.shared.pauseStream() { [weak self] in
            self?.lastOperation = nil
            self?.presenter?.pauseStreamEvent()
        }
    }
    
    func resumeStream() {
        guard ScreenVideoCapturer.webRTCClient?.webRTCStarted == true else { return }
        
        lastOperation = .resume
        NetworkManager.shared.resumeStream() { [weak self] in
            self?.lastOperation = nil
            self?.presenter?.resumeStreamEvent()
        }
    }
    
    func startWebRTCStream() {
        ScreenVideoCapturer.webRTCClient = ScreenmeetWebRtcSocketClient()
        ScreenVideoCapturer.webRTCClient?.startWebRTCSession()
    }
    
    func sendImageToWebRTC(image: CGImage) {
        if let client = ScreenVideoCapturer.webRTCClient?.rtcClient, let capturer = client.lCapturer {
            capturer.sendImageToWebRTC(image: image)
        }
    }
    
    func sendPixelBufferToWebRTC(pixelBuffer: CVImageBuffer) {
        let capturer = ScreenVideoCapturer.webRTCClient?.rtcClient?.lCapturer
        capturer?.sendPixelBufferToWebRTC(pixelBuffer: pixelBuffer)
    }
    
    func sendSampleBufferToWebRTC(sampleBuffer: CMSampleBuffer) {
        if let client = ScreenVideoCapturer.webRTCClient?.rtcClient, let capturer = client.lCapturer {
            capturer.sendScreenshot(sampleBuffer, ._0)
        }
    }
    
    func grantLaserPointerPermission(_ agree: Bool) {
        ChannelManager.shared.grantLaserPointerPermission(agree)
    }
}

extension SessionInteractor: NetworkEventListener {
    
    func disconnect() {
        presenter?.disconnectStreamEvent()
    }
    
    func reconnect() {
        childConnect(completion: { [weak self] in
            self?.presenter?.reconnectStreamEvent()
            
            switch self?.lastOperation {
            case .pause:
                self?.pauseStream()
            case .resume:
                self?.resumeStream()
            default:
                break
            }
        })
    }
}

extension SessionInteractor: ChannelEventListener {
    
    func join(viewer: ViewerModel) {
        presenter?.joinViewerEvent(viewer: viewer)
    }
    
    func left(viewer: ViewerModel) {
        presenter?.leftViewerEvent(viewer: viewer)
    }
    
    func laserPointerPermissionRequest() {
        presenter?.laserPointerPermissionRequest()
    }
    
    func laserPointerCancelRequest() {
        presenter?.laserPointerCancelRequest()
    }
    
    func startLaserPointerSession() {
        presenter?.startLaserPointerSession()
    }
    
    func updateLaserPointerCoordinates(_ x: CGFloat, _ y: CGFloat, withTap: Bool) {
        presenter?.updateLaserPointerCoordinates(x, y, withTap: withTap)
    }
    
    func stopLaserPointerSession() {
        presenter?.stopLaserPointerSession()
    }
}
