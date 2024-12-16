import SwiftUI

struct ContentView: View {
    @StateObject private var peerManager = PeerManager()
    @State private var message = ""
    @State private var timer: Timer?
    
    var body: some View {
        VStack {
            Text("Received Messages:")
                .font(.headline)
            
            Text(peerManager.receivedMessage)
            List(peerManager.receivedMessages.reversed(), id: \.self) { msg in
                Text(msg)
            }
            
            HStack {
                TextField("Enter message", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Send") {
                    sendCurrentTime()
                }
                .disabled(message.isEmpty)
            }
            .padding()
        }
        .padding()
        .onAppear {
            peerManager.start()
            startSendingUnixTime()
        }
        .onDisappear {
            stopSendingUnixTime()
        }
    }
    
    private func sendCurrentTime() {
        // m秒を取得
        peerManager.sendMessage(String(Date().timeIntervalSince1970))
    }
    
    private func startSendingUnixTime() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            sendCurrentTime()
        }
    }
    
    private func stopSendingUnixTime() {
        timer?.invalidate()
    }
}

#Preview {
    ContentView()
}
