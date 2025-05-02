import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {

    @State private var chat: ChatModel?
    @State private var showChatSheet: Bool = false
    @State private var cameraIsActive: Bool = true
    @State private var showHistory: Bool = false

    var body: some View {

        ZStack (alignment: .top) {
            CameraView(isActive: $cameraIsActive, onCaptureImage: { image in

                //initialise the chat module first
                chat = ChatModel()

                //wait a moment and then send the first prompt 
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if chat!.messages.count == 0 {
                        // Corrected parameter name from 'message' to 'content'
                        chat!.sendMessage(content: "What is this?", image: image)
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    cameraIsActive = false
                }

                showChatSheet = true

            }, showHistory: $showHistory)
            .sheet(isPresented: $showHistory) {
                HistoryView(isPresented: $showHistory)
            }
            .sheet(item: $chat, onDismiss: {
                withAnimation {
                    cameraIsActive = true
                }
            }) { chat in
                NavigationView {
                    ChatView(isPresented: $showChatSheet, chat: chat)
                        .onChange(of: showChatSheet) { oldValue, newValue in
                            if !newValue {
                                self.chat = nil
                            }
                        }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.black)
    }
}
