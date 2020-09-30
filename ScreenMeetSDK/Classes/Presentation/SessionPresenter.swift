//
//  SessionPresenter.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 23.07.2020.
//

import Foundation

protocol SessionPresenterIn: class {
    
    var interface: ScreenMeetUIProtocol { get set }
    
    func connectSession(sessionCode: String, success: @escaping () -> Void, failure: @escaping (ScreenMeet.Session.SessionError) -> Void)
    
    func disconnectSession()
    
    func pauseStream()
    
    func resumeStream()
}

protocol SessionPresenterOut: class {
    
    func sessionTerminateEvent()
    
    func sessionTerminateLocalEvent()
    
    func disconnectStreamEvent()
    
    func reconnectStreamEvent()
    
    func pauseStreamEvent()
    
    func resumeStreamEvent()
    
    func joinViewerEvent(viewer: ViewerModel)
    
    func leftViewerEvent(viewer: ViewerModel)
    
    func laserPointerPermissionRequest()
    
    func laserPointerCancelRequest()
    
    func startLaserPointerSession()
    
    func updateLaserPointerCoordinates(_ x: CGFloat, _ y: CGFloat, withTap: Bool)
    
    func stopLaserPointerSession()
}

class SessionPresenter {
    
    var interactor: SessionInteractor?
    
    var interface: ScreenMeetUIProtocol = ScreenMeetUI()
    
    private var laserPointer: LaserPointer?
    
    private var sessionQueue = DispatchQueue(label: "com.screenmeet.session", qos: .userInitiated)
    
    private var mainQueue = DispatchQueue.main
    
    private var timer: Timer?
    
    private func startWebRTCStream(success: @escaping () -> Void, failure: @escaping (ScreenMeet.Session.SessionError) -> Void) {
        mainQueue.async { [weak self] in
            #if targetEnvironment(simulator)
            guard let image = UIImage(color: .darkGray).cgImage else { return }
            
            self?.interactor?.startWebRTCStream()
            self?.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
                self?.interactor?.sendImageToWebRTC(image: image)
            }
            success()
            #else
            self?.interactor?.startWebRTCStream()
            
            var startWebRTC = true
            (ScreenMeet.shared.localVideoSource as? AppStreamVideoSource)?.startCapture(success: { (sampleBuffer) in
                if startWebRTC {
                    startWebRTC = false
                    success()
                }
                self?.interactor?.sendSampleBufferToWebRTC(sampleBuffer: sampleBuffer)
            }, failure: {
                failure(.captureFailed)
            })
            #endif
        }
    }
    
    private func stopWebRTCStream() {
        mainQueue.async { [weak self] in
            self?.invalidateTimer()
            (ScreenMeet.shared.localVideoSource as? AppStreamVideoSource)?.stopCapture { }
        }
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func terminatedLocal() {
        mainQueue.async {
            ScreenMeet.shared.terminatedLocalEvent()
            (ScreenMeet.shared.localVideoSource as? AppStreamVideoSource)?.stopCapture { }
        }
    }
    
    private func askAppMirrorPermission(success: @escaping () -> Void, failure: @escaping (ScreenMeet.Session.SessionError) -> Void) {
        showAppMirrorPermissionDialog(completion: { (agreed) in
            if agreed {
                success()
            } else {
                failure(.captureFailed)
            }
        })
    }
    
    private func askDisconnectSessionPermission(success: @escaping () -> Void) {
        showDisconnectSessionDialog(completion: { (agreed) in
            if agreed {
                success()
            }
        })
    }
    
    private func askLaserPointerPermission(completion: @escaping (Bool) -> Void) {
        showLaserPointerPermissionDialog(completion: completion)
    }
    
    private func startSession(sessionCode: String, success: @escaping () -> Void, failure: @escaping (ScreenMeet.Session.SessionError) -> Void) {
        sessionQueue.async { [weak self] in
            self?.interactor?.socketConnect {
                self?.startWebRTCStream(success: {
                    self?.mainQueue.async {
                        success()
                    }
                }, failure: { (error) in
                    self?.mainQueue.async {
                        self?.stopSession()
                        failure(error)
                    }
                })
            }
        }
    }
    
    private func stopSession() {
        sessionQueue.async { [weak self] in
            self?.interactor?.disconnectSession()
        }
    }
    
    private func terminateSession() {
        sessionQueue.async { [weak self] in
            self?.interactor?.terminateSession()
            self?.invalidateTimer()
            (ScreenMeet.shared.localVideoSource as? AppStreamVideoSource)?.stopCapture { }
        }
    }
}

extension SessionPresenter: SessionPresenterIn {
    
    func connectSession(sessionCode: String, success: @escaping () -> Void, failure: @escaping (ScreenMeet.Session.SessionError) -> Void) {
        sessionQueue.async { [weak self] in
            self?.interactor?.supportConnect(sessionCode: sessionCode, success: {
                self?.askAppMirrorPermission(success: { [weak self] in
                    self?.startSession(sessionCode: sessionCode, success: success, failure: failure)
                }, failure: { [weak self] (error) in
                    self?.mainQueue.async {
                        self?.terminateSession()
                        failure(error)
                    }
                })
            }) { (error) in
                self?.mainQueue.async {
                    self?.terminateSession()
                    failure(error)
                }
            }
        }
    }
    
    func disconnectSession() {
        askDisconnectSessionPermission { [weak self] in
            self?.sessionTerminateLocalEvent()
            self?.terminateSession()
        }
    }
    
    func pauseStream() {
        sessionQueue.async { [weak self] in
            self?.interactor?.pauseStream()
        }
    }
    
    func resumeStream() {
        sessionQueue.async { [weak self] in
            self?.interactor?.resumeStream()
        }
    }
}

extension SessionPresenter: SessionPresenterOut {
    
    func sessionTerminateEvent() {
        mainQueue.async { [weak self] in
            ScreenMeet.shared.terminateEvent()
            self?.invalidateTimer()
            (ScreenMeet.shared.localVideoSource as? AppStreamVideoSource)?.stopCapture { }
        }
    }
    
    func sessionTerminateLocalEvent() {
        mainQueue.async {
            ScreenMeet.shared.terminatedLocalEvent()
        }
    }
    
    func disconnectStreamEvent() {
        mainQueue.async { [weak self] in
            self?.stopWebRTCStream()
            ScreenMeet.shared.disconnectStreamEvent()
        }
    }
    
    func reconnectStreamEvent() {
        mainQueue.async { [weak self] in
            self?.startWebRTCStream(success: { }, failure: { (error) in })
            ScreenMeet.shared.reconnectStreamEvent()
        }
    }
    
    func pauseStreamEvent() {
        mainQueue.async {
            ScreenMeet.shared.pauseStreamEvent()
        }
    }
    
    func resumeStreamEvent() {
        mainQueue.async {
            ScreenMeet.shared.resumeStreamEvent()
        }
    }
    
    func joinViewerEvent(viewer: ViewerModel) {
        mainQueue.async {
            let participant = ScreenMeet.Session.Participant(id: viewer.cid, name: viewer.name)
            ScreenMeet.shared.joinParticipantEvent(participant: participant)
        }
    }
    
    func leftViewerEvent(viewer: ViewerModel) {
        mainQueue.async {
            let participant = ScreenMeet.Session.Participant(id: viewer.cid, name: viewer.name)
            ScreenMeet.shared.leftParticipantEvent(participant: participant)
        }
    }
    
    func laserPointerPermissionRequest() {
        askLaserPointerPermission() { [weak self] (agreed) in
            self?.sessionQueue.async {
                self?.interactor?.grantLaserPointerPermission(agreed)
            }
        }
    }
    
    func laserPointerCancelRequest() {
        dismissLaserPointerPermissionDialog()
    }
    
    func startLaserPointerSession() {
        mainQueue.async { [weak self] in
            self?.laserPointer = LaserPointer()
            self?.laserPointer?.startLaserPointerSession()
        }
    }
    
    func updateLaserPointerCoordinates(_ x: CGFloat, _ y: CGFloat, withTap: Bool) {
        mainQueue.async { [weak self] in
            if withTap {
                self?.laserPointer?.updateLaserPointerCoorsWithTap(x, y)
            } else {
                self?.laserPointer?.updateLaserPointerCoors(x, y)
            }
        }
    }
    
    func stopLaserPointerSession() {
        mainQueue.async { [weak self] in
            self?.laserPointer?.stopLaserPointerSession()
            self?.laserPointer = nil
        }
    }
}

extension SessionPresenter: ScreenMeetUIProtocol {
    
    func showSessionCodeDialog(completion: @escaping (String) -> Void) {
        mainQueue.async { [weak self] in
            self?.interface.showSessionCodeDialog(completion: completion)
        }
    }
    
    func showAppMirrorPermissionDialog(completion: @escaping (Bool) -> Void) {
        mainQueue.async { [weak self] in
            self?.interface.showAppMirrorPermissionDialog(completion: completion)
        }
    }
    
    func showDisconnectSessionDialog(completion: @escaping (Bool) -> Void) {
        mainQueue.async { [weak self] in
            self?.interface.showDisconnectSessionDialog(completion: completion)
        }
    }
    
    func showLaserPointerPermissionDialog(completion: @escaping (Bool) -> Void) {
        mainQueue.async { [weak self] in
            self?.interface.showLaserPointerPermissionDialog(completion: completion)
        }
    }
    
    func dismissLaserPointerPermissionDialog() {
        mainQueue.async { [weak self] in
            self?.interface.dismissLaserPointerPermissionDialog()
        }
    }
}
