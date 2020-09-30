//
//  SocketServiceManager.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 17.07.2020.
//

import Foundation

protocol NetworkEventListener {
    
    func disconnect()
    
    func reconnect()
}

final class NetworkManager {
    
    private init() { }
    
    static var shared = NetworkManager()
    
    var eventListener: NetworkEventListener?
    
    private var socketService: SocketService?
    
    private var restService = RestService()
    
    private var timeoutTimer: Timer?
    
    private var timeoutRetry: Int = 0
    
    private var reconnectRetries: Int = 0
    
    private var isReconnectionAllow: Bool {
        if ScreenMeet.shared.config.socketReconnectNumRetries == -1 {
            return true
        }
        
        if self.reconnectRetries < ScreenMeet.shared.config.socketReconnectNumRetries {
            return true
        }
        
        return false
    }
    
    private var isReconnectionStart: Bool {
        return reconnectRetries != 0
    }
    
    func supportConnect(sessionCode: String, completion: @escaping (Result<SessionModel, NetworkServiceError>) -> Void) {
        invalidateTimer()
        reconnectRetries = 0
        self.restService.send(endpoint: .supportConnect(code: sessionCode)) { [unowned self] (result: Result<SessionModel, NetworkServiceError>) in
            switch result {
            case .success(let session):
                self.socketService = nil
                self.restService.send(endpoint: .supportStartStreem(url: session.socketUrl, sessionId: session.id, authToken: session.hostAuthToken)) { (result: Result<SessionModel, NetworkServiceError>) in
                    switch result {
                    case .success(let session):
                        completion(.success(session))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func socketConnect(socketUrl: URL, sessionId: String, success: @escaping () -> Void, failure: @escaping () -> Void) {
        self.initiateSocketConnect(socketUrl: socketUrl, sessionId: sessionId, success: success, failure: failure)
        self.initiateTimeoutCounter(socketUrl: socketUrl, sessionId: sessionId, success: success, failure: failure)
    }
    
    private func initiateSocketConnect(socketUrl: URL, sessionId: String, success: @escaping () -> Void, failure: @escaping () -> Void) {
        self.socketService = SocketService(socketUrl: socketUrl, sessionId: sessionId)
        
        self.socketService?.socketConnect { [weak self] in
            self?.invalidateTimer()
            success()
        }
        
        self.socketService?.terminateEvent { [weak self] in
            self?.socketDisconnect()
            Logger.log.debug("Socket terminate")
            failure()
        }
        
        self.socketService?.disconnectEvent { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + ScreenMeet.shared.config.socketReconnectDelay + 1) {
                if self?.isReconnectionStart == false {
                    Logger.log.debug("Socket disconnected")
                    self?.eventListener?.disconnect()
                }
                
                guard self?.isReconnectionAllow ?? false else {
                    Logger.log.debug("Socket reconnection failed")
                    failure()
                    return
                }
                
                self?.reconnectRetries += 1
                self?.socketDisconnect()
                
                self?.initiateSocketConnect(socketUrl: socketUrl, sessionId: sessionId, success: { [weak self] in
                    if self?.isReconnectionStart == true {
                        Logger.log.debug("Socket reconnected")
                        self?.eventListener?.reconnect()
                    }
                    self?.reconnectRetries = 0
                }, failure: failure)
            }
        }
        
        self.socketService?.errorEvent(completion: { [weak self] (error) in
            if error == .invalidNamespace {
                self?.socketDisconnect()
                Logger.log.debug("Socket terminate")
                failure()
            }
        })
    }
    
    private func initiateTimeoutCounter(socketUrl: URL, sessionId: String, success: @escaping () -> Void, failure: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.timeoutTimer = Timer.scheduledTimer(withTimeInterval: ScreenMeet.shared.config.socketConnectionTimeout, repeats: true) { [weak self] (timer) in
                guard let timeoutRetry = self?.timeoutRetry, timeoutRetry < ScreenMeet.shared.config.socketConnectionNumRetries else {
                    self?.invalidateTimer()
                    self?.socketDisconnect()
                    Logger.log.debug("Socket connection timeout")
                    failure()
                    return
                }
                
                self?.timeoutRetry += 1
                self?.socketDisconnect()
                
                self?.initiateSocketConnect(socketUrl: socketUrl, sessionId: sessionId, success: success, failure: failure)
            }
        }
    }
    
    private func invalidateTimer() {
        self.timeoutTimer?.invalidate()
        self.timeoutTimer = nil
        self.timeoutRetry = 0
    }
    
    func childConnect(authToken: String, reconnectToken: ReconnectTokenModel?, completion: @escaping (ReconnectTokenModel) -> Void) {
        self.socketService?.childConnect(authToken: authToken, reconnectToken: reconnectToken, completion: { (result: Result<ReconnectTokenModel, NetworkServiceError>) in
            switch result {
            case .success(let model):
                completion(model)
            case .failure:
                break
            }
        })
    }
    
    func subscribeChannels(completion: @escaping () -> Void) {
        var subscribedChannels = 0
        ChannelManager.shared.channels.forEach { [weak self] (channel) in
            self?.socketService?.childSubscribe(channelName: channel.name.rawValue) { (data) in
                subscribedChannels += 1
                channel.subscribeHandler(data: data)
                
                if subscribedChannels == ChannelManager.shared.channels.count {
                    completion()
                }
            }
        }
        
        self.socketService?.pubEvent { (data) in
            guard let channel = data[0] as? String, let channelName = ChannelName(rawValue: channel) else { return }
            
            ChannelManager.shared.getChannel(channelName)?.pubEventHandler(data: data)
        }
        
        self.socketService?.removedEvent { (data) in
            guard let channel = data[0] as? String, let channelName = ChannelName(rawValue: channel) else { return }
           
            ChannelManager.shared.getChannel(channelName)?.removedEventHandler(data: data)
        }
    }
    
    func requestSet(for channelName: ChannelName, data: RequestSetModel, completion: @escaping () -> Void) {
        self.socketService?.requestSet(for: channelName.rawValue, data: data, completion: completion)
    }
    
    func command(for channelName: ChannelName, access: String, permission: Any, completion: @escaping ([Any]) -> ()) {
        self.socketService?.command(for: channelName, access: access, permission: permission, completion: completion)
    }
    
    func pauseStream(completion: @escaping () -> Void) {
        let stateChannel = ChannelManager.shared.getChannel(.state) as? StateChannel
        stateChannel?.pauseStream(completion: completion)
    }
    
    func resumeStream(completion: @escaping () -> Void) {
        let stateChannel = ChannelManager.shared.getChannel(.state) as? StateChannel
        stateChannel?.resumeStream(completion: completion)
    }
    
    func socketTerminate() {
        let data = RequestSetModel(key: "endMeeting", value: true)
        self.socketService?.requestSet(for: ChannelName.hostCommands.rawValue, data: data) { [weak self] in
            self?.socketDisconnect()
        }
    }
    
    func socketDisconnect() {
        socketService?.socketDisconnect()
        socketService = nil
    }
}
