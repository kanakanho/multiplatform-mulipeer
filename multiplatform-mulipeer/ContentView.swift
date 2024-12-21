import SwiftUI

struct ContentView: View {
    @ObservedObject var peerManager = PeerManager()
    
    var body: some View {
        VStack {
            TransformationMatrixPreparationView(peerManager: peerManager)
        }
        .onAppear {
            peerManager.start()
        }
    }
}

#Preview {
    ContentView()
}
