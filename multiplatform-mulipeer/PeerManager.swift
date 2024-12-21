//
//  PeerManager.swift
//  Multipeer-Connectivity-demo
//
//  Created by blueken on 2024/12/02.
//

import MultipeerConnectivity

class PeerManager: NSObject, ObservableObject {
    @Published var receivedMessage: String = ""
    
    @Published var sendMessagePeerList: [MCPeerID] = []
    @Published var isHost: Bool!
    
    private let serviceType = "example-chat"
    @Published var peerID: MCPeerID!
    @Published var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    override init() {
        super.init()
        peerID = MCPeerID(displayName: ProcessInfo.processInfo.hostName)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
    }
    
    func start() {
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func firstSendMessage() {
        sendMessageForAll("Hello")
    }
    
    func sendMessageForAll(_ message: String) {
        guard !session.connectedPeers.isEmpty else { return }
        guard let messageData = message.data(using: .utf8) else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.session.send(messageData, toPeers: self.session.connectedPeers, with: .unreliable)
            } catch {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    func sendMessage(_ message: String) {
        guard let messageData = message.data(using: .utf8) else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.session.send(messageData, toPeers: self.sendMessagePeerList, with: .unreliable)
            } catch {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    func addSendMessagePeer(peerIDHash: Int) {
        for peer in session.connectedPeers {
            if peer.hash == peerIDHash {
                sendMessagePeerList.append(peer)
                break
            }
        }
        print("Error Not found peerID")
    }
    
    func decisionHost(isHost: Bool) {
        self.isHost = isHost
    }
}

extension PeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("Peer \(peerID.displayName) changed state to \(state)")
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            print("Received: \(message)")
            DispatchQueue.main.async {
                self.receivedMessage = message
            }
        }
    }
    
    // Unused delegate methods
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension PeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start advertising: \(error.localizedDescription)")
    }
}

extension PeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
}
