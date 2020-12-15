//
//  ScreenMeet.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 26.08.2020.
//

import Foundation

// MARK: Main
/// Main class to work with ScreenMeet SDK
public final class ScreenMeet {
    
    private var presenter: SessionPresenterIn
    
    private lazy var lifecycleListeners = [WeakLifecycleListener]()
    
    private lazy var sessionEventListeners = [WeakSessionEventListener]()
    
    private var isSessionPaused: Bool = false
    
    private init() {
        let presenter = SessionPresenter()
        self.presenter = presenter
        let interactor = SessionInteractor()
        presenter.interactor = interactor
        interactor.presenter = presenter
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func applicationDidEnterBackground() {
        isSessionPaused = session?.lifecycleState == .pause
        session?.pause()
    }
    
    @objc private func applicationWillEnterForeground() {
        guard isSessionPaused == false else { return }
        session?.resume()
    }
    
    /// Returns singleton instance of ScreenMeet
    public static let shared = ScreenMeet()
    
    /// Allow to configure ScreenMeet framework
    public let config = Config()

    /// Implement ScreenMeetUI protocol to use own UI elements
    public var interface: ScreenMeetUIProtocol {
        get {
            presenter as! ScreenMeetUIProtocol
        }
        set {
            presenter.interface = newValue
        }
    }
    
    /// Local video source
    public var localVideoSource: LocalVideoSource = AppStreamVideoSource()
    
    /// Allow to manage session
    public var session: Session?
    
    /// Starts ScreenMeet session. No code specified, user will be asked to enter code value
    /// - Parameter code: Identify session created by agent
    /// - Parameter completion: Session if success. Error if fails (see `ScreenMeet.Session.SessionError`)
    public func connect(code: String, completion: @escaping (Result<Session, Session.SessionError>) -> Void) {
        if let session = session {
            completion(.success(session))
            return
        }
        
        let session = Session()
        self.session = session
        presenter.connectSession(sessionCode: code, success: {
            session.lifecycleState = .streaming
            completion(.success(session))
        }, failure: { [weak self] (error) in
            self?.session = nil
            completion(.failure(error))
        })
    }
    
    /// Stops ScreenMeet session.
    public func disconnect() {
        presenter.disconnectSession()
    }
    
    /// Allow to register lifecycle listener
    public func registerLifecycleListener<T: LifecycleListener>(_ lifecycleListener: T) {
        guard self.lifecycleListeners.contains(where: { $0.value?.lid == lifecycleListener.lid }) == false else {
            return
        }
        
        self.lifecycleListeners.append(WeakLifecycleListener(lifecycleListener))
    }
    
    /// Allow to unregister lifecycle listener
    public func unregisterLifecycleListener<T: LifecycleListener>(_ lifecycleListener: T) {
        guard let index = self.lifecycleListeners.firstIndex(where: { $0.value?.lid == lifecycleListener.lid }) else {
            return
        }
        self.lifecycleListeners.remove(at: index)
    }
    
    /// Allow to register session event listener
    public func registerSessionEventListener<T: SessionEventListener>(_ sessionEventListener: T) {
        guard self.sessionEventListeners.contains(where: { $0.value?.sid == sessionEventListener.sid }) == false else {
            return
        }
        
        self.sessionEventListeners.append(WeakSessionEventListener(sessionEventListener))
    }
    
    /// Allow to unregister session event listener
    public func unregisterSessionEventListener<T: SessionEventListener>(_ sessionEventListener: T) {
        guard let index = self.sessionEventListeners.firstIndex(where: { $0.value?.sid == sessionEventListener.sid }) else {
            return
        }
        self.sessionEventListeners.remove(at: index)
    }
}

// MARK: Session
extension ScreenMeet {
    
    /// Represents a session with the ScreenMeet backend services.
    public final class Session {
        
        fileprivate init() { }
        
        /// Retrieve the current state of the session.
        public var lifecycleState: State = .inactive
        
        /// The owner of this session.  The owner may or may not ultimately join this session as a participant.
        public var ownerName: String?
        
        /// Return the set of other participants in this session.
        public var participants = [Participant]()
        
        /// Pauses any streaming on the current session
        public func pause() {
            guard lifecycleState == .streaming else { return }
            ScreenMeet.shared.presenter.pauseStream()
        }
        
        /// Resumes streaming on the current session
        public func resume() {
            guard lifecycleState == .pause else { return }
            ScreenMeet.shared.presenter.resumeStream()
        }
        
        /// Represents the state of a session
        public enum State {
            case streaming /// Session stream is acvive
            case inactive  /// Session stream is not started or already stopped
            case pause     /// Session is active but stream is paused

            public enum StreamingReason {
                case sessionResumed
            }
            
            public enum InactiveReason {
                case terminatedLocal
                case terminatedServer
            }

            public enum PauseReason {
                case sessionPaused
            }
        }
        
        /// Describes session participant
        public struct Participant: Equatable {
            
            /// UID of participant
            public var id: String
            
            /// Participant name
            public var name: String
            
            /// Equatable by participant UID
            public static func == (lhs: Self, rhs: Self) -> Bool {
                return lhs.id == rhs.id
            }
        }
        
        /// The actions that may happen for a participant
        public enum ParticipantAction {
            /// The participant was added
            case added
            /// The participant was removed
            case removed
            /// The audio was muted for the participant
            case audioMuted
            /// The audio was unmuted for the participant
            case audioUnmuted
        }

        /// Describes reason why session can't be started
        public enum SessionError: Error {
            
            /// Incorrect session code or expired session code
            case incorrectSessionCode
            
            /// Can't connect to server
            case connectionTimeout
            
            /// Incorrect session code or expired session code
            case sessionNotFound
            
            /// Session with specified code already started
            case sessionAlreadyConnected
            
            /// Wrong organization key (mobileKey) value
            case incorrectOrganizationKey
            
            /// Can't start capturing or user disallowed screen capturing
            case captureFailed
        }

    }
}

/// ScreenMeet Configuration
extension ScreenMeet {

    /// ScreenMeet Configuration
    open class Config {
        
        /// Organization key to access API
        open var organizationKey: String? = nil
        
        /// Initial connection endpoint/port
        open var endpoint: URL = URL(string: "https://api-v3.screenmeet.com/v3/")!
        
        /// Additional parameters to configure framework
        open var parameters: [String: Any] = [:]
        
        /// Represent the severity and importance of log messages ouput (`.info`, `.debug`, `.error`, see `LogLevel`)
        open var loggingLevel: LogLevel = .error {
            didSet {
                switch loggingLevel {
                case .info:
                    Logger.log.level = .info
                case .debug:
                    Logger.log.level = .debug
                case .error:
                    Logger.log.level = .error
                }
            }
        }

        /// Represent the severity and importance of any particular log message.
        public enum LogLevel {
            /// Information that may be helpful, but isn’t essential, for troubleshooting errors
            case info
            /// Verbose information that may be useful during development or while troubleshooting a specific problem
            case debug
            /// Designates error events that might still allow the application to continue running
            case error
        }
        
        /// HTTP connection timeout. Provided in seconds. Default 30s.
        open var httpTimeout: TimeInterval = 30 {
            didSet {
                if httpTimeout < 0 {
                    httpTimeout = 30
                }
            }
        }
        
        /// HTTP connection retry number. Default 5 retries.
        open var httpNumRetry: Int = 5 {
            didSet {
                if httpNumRetry < 0 {
                    httpNumRetry = 5
                }
            }
        }
        
        /// Socket connection timeout. Provided in seconds. Default 20s.
        open var socketConnectionTimeout: TimeInterval = 20 {
            didSet {
                if socketConnectionTimeout < 0 {
                    socketConnectionTimeout = 20
                }
            }
        }
        
        /// Socket connection retry number. Default 5 retries.
        open var socketConnectionNumRetries: Int = 5 {
            didSet {
                if socketConnectionNumRetries < 0 {
                    socketConnectionNumRetries = 5
                }
            }
        }
        
        /// Socket reconnection retry number. Default unlimited retries. For unlimited set -1.
        open var socketReconnectNumRetries: Int = -1 {
            didSet {
                if socketReconnectNumRetries < -1 {
                    socketReconnectNumRetries = -1
                }
            }
        }
        
        /// Socket reconnection delay. Provided in seconds. Default 0s.
        open var socketReconnectDelay: TimeInterval = 0 {
            didSet {
                if socketReconnectDelay < 0 {
                    socketReconnectDelay = 0
                }
            }
        }
        
        /// WebRTC connection timeout. Provided in seconds. Default 60s.
        open var webRtcTimeout: TimeInterval = 60 {
            didSet {
                if webRtcTimeout < 0 {
                    webRtcTimeout = 60
                }
            }
        }
        
        /// WebRTC connection retry number. Default 5 retries.
        open var webRtcNumRetries: Int = 5 {
            didSet {
                if webRtcNumRetries < 0 {
                    webRtcNumRetries = 5
                }
            }
        }
    }
}

// MARK: Events
extension ScreenMeet {
    
    func disconnectStreamEvent() {
        self.lifecycleListeners.networkDisconnect()
    }
    
    func reconnectStreamEvent() {
        self.lifecycleListeners.networkReconnect()
    }
    
    func pauseStreamEvent() {
        guard let session = session else { return }
        self.lifecycleListeners.onPause(oldState: session.lifecycleState, pauseReason: .sessionPaused)
        self.session?.lifecycleState = .pause
    }
    
    func resumeStreamEvent() {
        guard let session = session else { return }
        self.lifecycleListeners.onStreaming(oldState: session.lifecycleState, streamingReason: .sessionResumed)
        self.session?.lifecycleState = .streaming
    }
    
    func terminatedLocalEvent() {
        guard let session = session else { return }
        self.lifecycleListeners.onInactive(oldState: session.lifecycleState, inactiveReason: .terminatedLocal)
        self.session = nil
    }
    
    func terminateEvent() {
        guard let session = session else { return }
        self.lifecycleListeners.onInactive(oldState: session.lifecycleState, inactiveReason: .terminatedServer)
        self.session = nil
    }
    
    func joinParticipantEvent(participant: Session.Participant) {
        self.session?.participants.removeAll(where: { $0.id == participant.id })
        self.session?.participants.append(participant)
        self.sessionEventListeners.onParticipantAction(participant: participant, participantAction: .added)
    }
    
    func leftParticipantEvent(participant: Session.Participant) {
        self.session?.participants.removeAll(where: { $0.id == participant.id })
        self.sessionEventListeners.onParticipantAction(participant: participant, participantAction: .removed)
    }
}

// MARK: Static methods
extension ScreenMeet {
    
    /// ScreenMeet SDK version
    /// - Returns: ScreenMeet SDK version
    public static func version() -> String {
        let bundle = Bundle(identifier: "org.cocoapods.ScreenMeetSDK")
        let version = bundle?.infoDictionary?["CFBundleShortVersionString"] ?? ""
        let build = bundle?.infoDictionary?["CFBundleVersion"] ?? ""
        return "\(version) (\(build))"
    }
}
