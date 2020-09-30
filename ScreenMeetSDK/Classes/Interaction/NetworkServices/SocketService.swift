//
//  SocketService.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 16.07.2020.
//

import Foundation
import SocketIO

enum SocketError: Error, CaseIterable {
    case operationTimeOut
    case networkDown
    case socketNotConnected
    case disconnect
    case writeTimeoutError
    case invalidNamespace
    case other
    
    private var message: String? {
        switch self {
        case .operationTimeOut:
            return "Operation timed out"
        case .networkDown:
            return "Network is down"
        case .socketNotConnected:
            return "Socket is not connected"
        case .disconnect:
            return "Got Disconnect"
        case .writeTimeoutError:
            return "writeTimeoutError"
        case .invalidNamespace:
            return "Invalid namespace"
        default:
            return nil
        }
    }
    
    static func getError(for message: String) -> SocketError {
        var error: SocketError = .other
        SocketError.allCases.forEach { (socketError) in
            guard let socketMessage = socketError.message else { return }
            if message.contains(socketMessage) {
                error = socketError
            }
        }
        return error
    }
}

class SocketService {
    
    private var socket: SocketIOClient
    
    private var manager: SocketManager
    
    init(socketUrl: URL, sessionId: String) {
        self.manager = SocketManager(socketURL: socketUrl, config: [.log(false), .forceWebsockets(true), .forceNew(false), .reconnects(false)])
        
        self.socket = self.manager.socket(forNamespace: "/\(sessionId)")
    }
    
    private func pingPongEvent() {
        self.socket.on("_ping") { data, ack in
            ack.with("pong")
        }
    }
    
    func socketConnect(completion: @escaping () -> Void) {
        self.socket.on("connect") { [unowned self] (data, ack) in
            guard self.socket.status == .connected else { return }
            completion()
        }
        
        self.pingPongEvent()
        self.socket.connect()
    }
    
    func childConnect<T: Decodable>(authToken: String, reconnectToken: ReconnectTokenModel?, completion: @escaping (Result<T, NetworkServiceError>) -> Void) {
        var identityObject: [String: Any] = ["host" : true, "host_auth_token": authToken]
        
        if let token = reconnectToken {
            identityObject["reconnect_token"] = token.reconnectToken
            identityObject["override_token"] = token.overrideToken
        }
        
        self.socket.emitWithAck("child-connect", identityObject).timingOut(after: 0) { (response) in
            guard response.count > 0, let data = response[0] as? [String: Any] else {
                completion(.failure(.dataMissing))
                return
            }
            
            do {
                let serializedData = try JSONSerialization.data(withJSONObject: data)
                let decodedObject = try JSONDecoder().decode(T.self, from: serializedData)
                completion(.success(decodedObject))
            } catch {
                completion(.failure(.decodeError(message: error.localizedDescription)))
            }
        }
    }
    
    func childSubscribe(channelName: String, completion: @escaping ([Any]) -> Void) {
        self.socket.emitWithAck("child-subscribe", channelName).timingOut(after: 0) { (data) in
            completion(data)
        }
    }
    
    func pubEvent(completion: @escaping ([Any]) -> Void) {
        self.socket.on("pub", callback: { (data, ack) in
            completion(data)
        })
    }
    
    func removedEvent(completion: @escaping ([Any]) -> Void) {
        self.socket.on("removed", callback: { (data, ack) in
            completion(data)
        })
    }
    
    func requestSet(for channelName: String, data: RequestSetModel, completion: @escaping () -> Void) {
        self.socket.emitWithAck("request-set", channelName, data).timingOut(after: 0) { (data) in
            completion()
        }
    }
    
    func command(for channelName: ChannelName, access: String, permission: Any, completion: @escaping ([Any]) -> ()) {
        self.socket.emitWithAck("command", channelName.rawValue, access, permission as! SocketData).timingOut(after: 0, callback: completion)
    }

    
    func terminateEvent(completion: @escaping () -> Void) {
        self.socket.on("terminate") { data, ack in
            completion()
        }
    }
    
    func disconnectEvent(completion: @escaping () -> Void) {
        self.socket.on("disconnect") { data, ack in
            completion()
        }
    }
    
    func errorEvent(completion: @escaping (SocketError) -> Void) {
        self.socket.on("error") { data, ack in
            guard data.count > 0, let message = data[0] as? String else { return }
            completion(SocketError.getError(for: message))
        }
    }
    
    func socketDisconnect() {
        socket.removeAllHandlers()
        socket.disconnect()
    }
}
