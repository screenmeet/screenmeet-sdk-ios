//
//  UI.swift
//  FullExample
//
//  Created by Ivan Makhnyk on 09.09.2020.
//
import SwiftUI
import Combine
import Foundation
import ScreenMeetSDK

struct LabelledDivider: View {

    let label: String
    let horizontalPadding: CGFloat
    let color: Color

    init(label: String, horizontalPadding: CGFloat = 20, color: Color = .gray) {
        self.label = label
        self.horizontalPadding = horizontalPadding
        self.color = color
    }

    var body: some View {
        HStack {
            line
            Text(label).foregroundColor(color)
            line
        }
    }

    var line: some View {
        VStack { Divider().background(color) }.padding(horizontalPadding)
    }
}

struct LoadingView: View {
    
    @State private var shouldAnimate = false
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever())
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.3))
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(0.6))
        }
        .onAppear {
            self.shouldAnimate = true
        }
    }
    
}

struct TextFieldWithLabel: View {
    var label: String
    var placeholder : String
    @State var text: Binding<String>
    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Text(label).font(.headline)
            TextField(placeholder, text: text)
            .padding(.all)
            .clipShape(RoundedRectangle(cornerRadius: 5.0))
            .background(Color(red: 239.0/255.0, green: 243.0/255, blue: 244.0/255.0, opacity:1.0))
        }.padding(.horizontal,15)
    }
}

struct SMButtonStyle: ButtonStyle {
    private var color: Color
    init(_ color: Color = Color.orange) {
        self.color = color
    }
    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .padding()
            .background(self.color)
            .foregroundColor(Color.white)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.8 : 1)
            .animation(.easeInOut(duration: 0.2))
            .cornerRadius(6)
    }
}

struct ParticipantRow: View {
    var participant: ScreenMeet.Session.Participant

    var body: some View {
        HStack {
            Image(systemName: "person.icloud.fill")
            Text(participant.name)
            Spacer()
        }
    }
}

struct UI_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
//        ParticipantRow(participant: ScreenMeet.Session.Participant(id: "1",name: "test"))
    }
}
