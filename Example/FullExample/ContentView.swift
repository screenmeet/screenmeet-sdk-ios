//
//  ContentView.swift
//  FullExample
//
//  Created by Ivan Makhnyk on 01.09.2020.
//

import SwiftUI
import Combine
import ScreenMeetSDK

struct ContentView: View {
    
    @ObservedObject var viewRouter: ViewRouter
    
    var body: some View {
        VStack(alignment: .center) {
            if (self.viewRouter.isStreaming == "stream") {
                StreamView(viewRouter: viewRouter)
            } else if(self.viewRouter.isStreaming == "loading")  {
                LoadingView()
            } else {
                StartView(viewRouter: viewRouter)
            }
        }
    }
}
struct StartView: View {
    
    @State private var endpoint: String = "https://api-v3.screenmeet.com/v3/"
    @State private var mobileAPIKey: String = "[INSERT MOBILE API KEY HERE]"
    @State private var sessionCode: String = ""
    @ObservedObject var viewRouter: ViewRouter

    var body: some View {
        VStack(spacing: 10.0) {
            Group {
                TextFieldWithLabel(label: "Session code", placeholder: "000000", text: $sessionCode).keyboardType(UIKeyboardType.numberPad)
                Button("Start session", action: {
                    //Set custom endpoint URL
                    ScreenMeet.shared.config.endpoint = URL(string: self.endpoint)!
                    //Set organization mobile Key
                    //ScreenMeet.shared.config.organizationKey = self.mobileAPIKey
                    //Set custom dialogs (See CustomDialogs.swift file)
                    ScreenMeet.shared.interface = CustomDialogs()
                    
                    print(self.endpoint)
                    print(self.mobileAPIKey)
                    print(self.sessionCode)
                    self.viewRouter.isStreaming = "loading"
                    ScreenMeet.shared.connect(code: self.sessionCode) { result in
                        switch result {
                        case .success:
                            print("Session started")
                            self.viewRouter.isStreaming = "stream"
                        case .failure(let error):
                            print("Session start failed: \(error)")
                            self.viewRouter.isStreaming = "start"
                        }
                    }
                }).buttonStyle(SMButtonStyle(.orange))
            }
            Group {
                LabelledDivider(label: "Advanced")
                TextFieldWithLabel(label: "Endpoint URL", placeholder: "https://", text: $endpoint).keyboardType(UIKeyboardType.URL)
                TextFieldWithLabel(label: "Mobile API key", placeholder: "apiKey", text: $mobileAPIKey)
            }
            Spacer()
        }
    }
}

struct StreamView: View {
    @ObservedObject var viewRouter: ViewRouter
    @State private var shouldAnimate = false
    @State private var pauseButtonText: String = "Pause"
    @State private var isConnected = true

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Spacer()
            Circle()
                .fill(isConnected ? Color.blue : Color.gray)
                .frame(width: 30, height: 30)
                .overlay(
                    ZStack {
                        Circle()
                            .stroke(isConnected ? Color.blue : Color.gray, lineWidth: 100)
                            .scaleEffect(shouldAnimate ? 1 : 0)
                        Circle()
                            .stroke(isConnected ? Color.blue : Color.gray, lineWidth: 100)
                            .scaleEffect(shouldAnimate ? 1.5 : 0)
                        Circle()
                            .stroke(isConnected ? Color.blue : Color.gray, lineWidth: 100)
                            .scaleEffect(shouldAnimate ? 2 : 0)
                    }
                    .opacity(shouldAnimate ? 0.0 : 0.2)
                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: false))
            )
            Divider()
            Group {
                Button("Stop session", action: {
                    ScreenMeet.shared.disconnect()
                }).buttonStyle(SMButtonStyle(.red))
                Button(pauseButtonText, action: {
                    if (ScreenMeet.shared.session?.lifecycleState == .pause) {
                        ScreenMeet.shared.session?.resume()
                        self.shouldAnimate = true
                        self.pauseButtonText = "Pause"
                    } else {
                        ScreenMeet.shared.session?.pause()
                        self.shouldAnimate = false
                        self.pauseButtonText = "Resume"
                    }
                }).buttonStyle(SMButtonStyle(.green))
            }
            LabelledDivider(label: "Participants")
            List(self.viewRouter.participants) { p in
                ParticipantRow(participant: p)
            }
        }.onAppear {
            self.shouldAnimate = true
            UITableView.appearance().separatorStyle = .none
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewRouter: ViewRouter())
    }
}


class ViewRouter: ObservableObject, LifecycleListener, SessionEventListener {
    
    public var participants: [ScreenMeet.Session.Participant] = [] {
        didSet {
            objectWillChange.send(self)
        }
    }

    func onParticipantAction(participant: ScreenMeet.Session.Participant, participantAction: ScreenMeet.Session.ParticipantAction) {
        switch participantAction {
        case .added:
            self.participants.append(participant)
            print("User \(participant.name) joined session")
        case .removed:
            print("User \(participant.name) left session")
            if let index = self.participants.firstIndex(of: participant) {
                self.participants.remove(at: index)
            }
        default: break
        }
        //objectWillChange.send(self)
    }
    
    
    func networkDisconnect() {
        self.isConnected = false
    }
    
    func networkReconnect() {
        self.isConnected = true
    }
    
    func onStreaming(oldState: ScreenMeet.Session.State, streamingReason: ScreenMeet.Session.State.StreamingReason) {
        isStreaming = "stream"
        self.isConnected = true
        self.participants.removeAll()
    }
    
    func onInactive(oldState: ScreenMeet.Session.State, inactiveReason: ScreenMeet.Session.State.InactiveReason) {
        isStreaming = "start"
        self.participants.removeAll()
    }
    
    func onPause(oldState: ScreenMeet.Session.State, pauseReason: ScreenMeet.Session.State.PauseReason) {
        //TODO
    }
    
    
    let objectWillChange = PassthroughSubject<ViewRouter,Never>()
    
    var isStreaming: String = ScreenMeet.shared.session != nil ? "stream" : "start" {
        didSet {
            objectWillChange.send(self)
        }
    }
    var isPaused: Bool = ScreenMeet.shared.session != nil && ScreenMeet.shared.session?.lifecycleState == ScreenMeet.Session.State.inactive {
            didSet {
                objectWillChange.send(self)
            }
        }
    var isConnected: Bool = true {
        didSet {
            objectWillChange.send(self)
        }
    }
    
    init() {
        ScreenMeet.shared.registerLifecycleListener(self)
        ScreenMeet.shared.registerSessionEventListener(self)
    }
}
