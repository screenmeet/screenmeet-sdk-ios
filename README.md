# ScreenMeetSDK

[![Version](https://img.shields.io/cocoapods/v/ScreenMeetSDK.svg?style=flat)](https://cocoapods.org/pods/ScreenMeetSDK)
[![License](https://img.shields.io/cocoapods/l/ScreenMeetSDK.svg?style=flat)](https://cocoapods.org/pods/ScreenMeetSDK)
[![Platform](https://img.shields.io/cocoapods/p/ScreenMeetSDK.svg?style=flat)](https://cocoapods.org/pods/ScreenMeetSDK)

[![ScreenMeet](https://screenmeet.com/wp-content/uploads/Logo-1.svg)](https://screenmeet.com) 

[ScreenMeet.com](https://screenmeet.com)


## Quick start

Start ScreenMeet session
```swift
let sessionCode = "123456" // session code provided by support agent
ScreenMeet.shared.connect(code: sessionCode) { result in
    switch result {
        case .success:
            print("Session started!")
        case .failure(let error): 
            //error describes the reason why session is not started
            print("Session start failed: \(error)")
    }
}
```

Stop ScreenMeet session
```swift
ScreenMeet.shared.disconnect()
```

Pause | Resume ScreenMeet session
```swift
ScreenMeet.shared.session?.pause() //pause

ScreenMeet.shared.session?.resume() //resume
```



## Example

To run the example project, clone the repo, and run `pod install` from the [Example](Example/) directory first.
More advanced sample with SwiftUI see in [FullExample](Example/FullExample) application.

## Requirements

 | | Minimum iOS version
------ | -------
**ScreenMeetSDK** | **iOS 12.0**
[Example](Example/) | iOS 13.0
[FullExample](Example/FullExample) | iOS 13.0

## Installation

ScreenMeetSDK is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ScreenMeetSDK'
```

# Session Lifecycle
## Organization Key
To start work with SDK __organizationKey__ (mobileKey) is required
```swift
//Set organization mobile Key
ScreenMeet.shared.config.organizationKey = yourMobileAPIKey //provided by ScreenMeet
```

## Start session
```swift
let sessionCode = "123456" // session code provided by support agent
ScreenMeet.shared.connect(code: sessionCode) { result in
    switch result {
        case .success(let session):
            print("Session started!")
        case .failure(let error): 
            //error describes the reason why session is not started
            print("Session start failed: \(error)")
    }
}
```
In case ```.success``` session object is returned
Anytime you can get session object by
```swift
ScreenMeet.shared.session
```
if value of ```ScreenMeet.shared.session``` is ```nil``` the session in not started of already finished

In case of ```.failure``` here is the list of posible reasons
```swift
public enum SessionError: Error {
    case incorrectSessionCode      // Incorrect session code or expired session code
    case connectionTimeout         // Can't connect to server
    case sessionNotFound           // Incorrect session code or expired session code
    case sessionAlreadyConnected   // Session with specified code already started
    case incorrectOrganizationKey  // Wrong organization key (mobileKey) value
    case captureFailed             // Can't start capturing or user disallowed screen capturing
}
```
## Stop session
To stop session the following command should be used
```swift
ScreenMeet.shared.disconnect()
```
It will ask user to confirm session stop and after agreement session will be stoped.

## Pause/Resume session

```swift
ScreenMeet.shared.session?.pause() // Pause session

ScreenMeet.shared.session?.resume() // Resume session
```

## Actual session state
```swift
ScreenMeet.shared.session?.lifecycleState
```
Possible values
```swift
public enum State {
    case streaming // Session stream is acvive
    case inactive  // Session stream is not started or already stopped
    case pause     // Session is active but stream is paused
}
```
## Track session state changing
To track session state change LifecycleListener should be registered
```swift
ScreenMeet.shared.registerLifecycleListener<T: LifecycleListener>(_ lifecycleListener: T)
```
The following protocol should be implemented
```swift
/// Listener for lifcycle-related state of for the session
public protocol LifecycleListener: class {
    
    var lid: UUID { get }
    
    /// Sesson stream was started or restored
    /// - Parameter oldState:        Previous state value
    /// - Parameter streamingReason: Reason why state was changed
    func onStreaming(oldState: ScreenMeet.Session.State, streamingReason: ScreenMeet.Session.State.StreamingReason)
        
    /// Sesson stream was started or restored
    /// - Parameter oldState:        Previous state value
    /// - Parameter inactiveReason:  Reason why state was changed
    func onInactive(oldState: ScreenMeet.Session.State, inactiveReason: ScreenMeet.Session.State.InactiveReason)
    
    /// Sesson stream was started or restored
    /// - Parameter oldState:        Previous state value
    /// - Parameter pauseReason:     Reason why state was changed
    func onPause(oldState: ScreenMeet.Session.State, pauseReason: ScreenMeet.Session.State.PauseReason)
    
    /// Is called when application fased with network issues and trys to restore connection
    func networkDisconnect()
    
    /// Is called when application restored network connection
    func networkReconnect()
}
```
## Track participants
To track who joins of leaves the session
```swift
ScreenMeet.shared.registerSessionEventListener<T: SessionEventListener>(_ sessionEventListener: T)
```
and implement
```swift
public protocol SessionEventListener: class {
    
    var sid: UUID { get }
    
    /// Called when a participant-related action occurs
    /// - Parameter participant the participant
    /// - Parameter participantAction the action that occurred
    func onParticipantAction(participant: ScreenMeet.Session.Participant, participantAction: ScreenMeet.Session.ParticipantAction)
}
```
where __ScreenMeet.Session.Participant__ and __ScreenMeet.Session.ParticipantAction__ are
```swift
        public struct Participant: Identifiable, Equatable {
            
            public var id: String
            
            public var name: String
            
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
```
# Custom Dialogs
In case you need to change style of SDK's user interaction, use
```swift
ScreenMeet.shared.interface = MyCustomDialogs()
```
where __MyCustomDialogs()__ should fit protocos __ScreenMeetUIProtocol__
```swift
/// Implement ScreenMeetUI protocol to implement all user interactions in style of your application UI
public protocol ScreenMeetUIProtocol {
    
    /// Display a dialog requesting a session code from the user.
    func showSessionCodeDialog(completion: @escaping (String) -> Void)
    
    /// Display a dialog requesting their approval for screen sharing.
    func showAppMirrorPermissionDialog(completion: @escaping (Bool) -> Void)
    
    /// Display a dialog requesting their approval for disconnect session.
    func showDisconnectSessionDialog(completion: @escaping (Bool) -> Void)
    
    /// Display a dialog requesting their approval for laser pointer.
    func showLaserPointerPermissionDialog(completion: @escaping (Bool) -> Void)
    
    /// Display a dialog requesting approval to stop laser pointer.
    func dismissLaserPointerPermissionDialog()
}
```
for more details see file [CustomDialogs.swift](Example/FullExample/CustomDialogs.swift) in [FullExample](Example/FullExample) app

# Configuration
## Logging level
Represent the severity and importance of log messages ouput
```swift
ScreenMeet.shared.config.loggingLevel = .debug
```
Possible values:
```swift
public enum LogLevel {
    /// Information that may be helpful, but isn’t essential, for troubleshooting errors
    case info
    /// Verbose information that may be useful during development or while troubleshooting a specific problem
    case debug
    /// Designates error events that might still allow the application to continue running
    case error
}
```

## Custom Endpoint URL
Set custom endpoint URL
```swift
ScreenMeet.shared.config.endpoint = yourEndpointURL
```


## License

ScreenMeetSDK is available under the MIT license. See the LICENSE file for more info.
