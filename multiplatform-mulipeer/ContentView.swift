import SwiftUI

struct ContentView: View {
    @StateObject private var peerManager = PeerManager()
    @State private var message = ""
    @State private var timer: Timer?
    
    var body: some View {
        VStack {
            Text("Received Messages:")
                .font(.headline)
            List(peerManager.receivedMessages.reversed(), id: \.self) { msg in
                Text(msg)
            }
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
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
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
