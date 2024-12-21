//
//  TransformationMatrixPreparationView.swift
//  multiplatform-mulipeer
//
//  Created by blueken on 2024/12/18.
//

import SwiftUI

enum TransformationMatrixPreparationState {
    case initial
    case searching
    case selecting
    case HMDCoordinate
    case bothIndexFingerCoordinate
    case prepared
}

struct TransformationMatrixPreparationView: View {
    @ObservedObject var peerManager = PeerManager()
    
    @State private var state: TransformationMatrixPreparationState = .initial
    
    var body: some View {
        Text("MyId:\(peerManager.peerID.hash)").font(.title)
        Divider()
        NavigationView{
            switch state {
            case .initial:
                initialView(peerManager: peerManager, state: $state)
            case .searching:
                searchingPeerView(peerManager: peerManager, state: $state)
            case .selecting:
                if peerManager.isHost {
                    selectingPeerHostView(peerManager: peerManager, state: $state)
                } else {
                    selectingPeerHostClientView(peerManager: peerManager, state: $state)
                }
            case .HMDCoordinate:
                if peerManager.isHost {
                    HMDCoordinateHostView(peerManager: peerManager, state: $state)
                } else {
                    HMDCoordinateClientView(peerManager: peerManager, state: $state)
                }
            case .bothIndexFingerCoordinate:
                if peerManager.isHost {
                    BothIndexFingerCoordinateHostView(peerManager: peerManager, state: $state)
                } else {
                    BothIndexFingerCoordinateClientView(peerManager: peerManager, state: $state)
                }
            case .prepared:
                PreparedView()
            }
        }
        .navigationViewStyle(.stack)
        Spacer()
        Divider()
        Text("Received Messages:\(peerManager.receivedMessage)")
            .font(.headline)
    }
}

struct initialView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var state: TransformationMatrixPreparationState
    
    var body: some View {
        VStack {
            if peerManager.peerID != nil {
                Button(action: {
                    state = .searching
                }){
                    Text("初期設定を開始します")
                }
            } else {
                Text("端末のIDが認識できません")
            }
        }
    }
}

struct searchingPeerView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var state: TransformationMatrixPreparationState
    
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            Text("1. 近くにいる人を探す").font(.title)
            Divider()
            Button(action:{
                peerManager.firstSendMessage()
                let peers = peerManager.session.connectedPeers
                // 自分のhash値が一番大きいか
                let isHost = peers.allSatisfy { peer in
                    peerManager.peerID.hash > peer.hash
                }
                
                peerManager.decisionHost(isHost: isHost)
                
                if peerManager.isHost != nil {
                    peerManager.sendMessageForAll("searched")
                    state = .selecting
                } else {
                    errorMessage = "ホストを決定できませんでした"
                }
            }){
                Text("探す").font(.title2)
            }
            
            Spacer()
            
            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red)
                Button(action: {
                    state = .initial
                }){
                    Text("設定の最初に戻る")
                }
            }
            
        }
    }
}

struct selectingPeerHostView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var state: TransformationMatrixPreparationState
    @State private var peerIDHash: Int!
    
    var body: some View {
        VStack {
            if (peerManager.receivedMessage != "searched"){
                Text("選択する相手を待っています")
            } else {
                Text("2. 近くにいる人を選択").font(.title)
                Divider()
                Picker("", selection: $peerIDHash) {
                    Text("選ぶ").tag(nil as Int?)
                    ForEach(peerManager.session.connectedPeers, id: \.hash) { peerId in
                        Text(String(peerId.hash)).tag(peerId.hash)
                    }
                }
                Spacer()
                Button(action: {
                    if peerIDHash != nil {
                        peerManager.addSendMessagePeer(peerIDHash: peerIDHash)
                        let peerIDHashStr = String(peerManager.peerID.hash)
                        peerManager.sendMessage("select:\(peerIDHashStr)")
                    }
                }){
                    Text("選択した相手を確定")
                }
            }
        }
        .onChange(of: peerManager.receivedMessage){
            if peerManager.receivedMessage == "receivedSelect" {
                state = .HMDCoordinate
            }
        }
    }
}

struct selectingPeerHostClientView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var state: TransformationMatrixPreparationState
    
    var body: some View {
        VStack {
            Text("2. 近くにいる人を選択").font(.title)
            Divider()
            Text("ホストからの選択を待っています")
            
            Spacer()
            
            Button(action: {
                state = .searching
            }){
                Text("設定の最初に戻る")
            }
        }
        .onChange(of: peerManager.receivedMessage){
            if peerManager.receivedMessage.hasPrefix("select:") {
                let peerIDHash = peerManager.receivedMessage.replacingOccurrences(of: "select:", with: "")
                let peerIDHashInt = Int(peerIDHash) ?? 0
                peerManager.addSendMessagePeer(peerIDHash: peerIDHashInt)
                peerManager.sendMessage("receivedSelect")
                state = .HMDCoordinate
            }
        }
    }
}

/*
{
    "unixTime": 1234567890,
    "hmdPosition": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
}
 */

struct HMDCoordinate:Codable {
    var unixTime: Int
    var HMDPosition: [Float]
}

struct HMDCoordinateHostView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var state: TransformationMatrixPreparationState
    @State var isCommunication = false
    
    var body: some View {
        VStack {
            Text("3. ヘッドセットの位置を確認").font(.title)
            Divider()
            
            Text("開始ボタンを押してから3秒後に右手の人差し指で相手のヘッドセットに触れてください")
            
            Button(action: {
                peerManager.sendMessage("reqHMDPosition")
            }){
                Text("開始")
            }
            .disabled(isCommunication)
            
            Spacer()
            
            if isCommunication {
                Text("ヘッドセットに右手の人差し指で触れられていましたか？").font(.title2)
                HStack{
                    Button(action: {
                        peerManager.sendMessage("successHMDPosition")
                    }){
                        Text("はい")
                    }
                    Button(action: {
                        peerManager.sendMessage("reset")
                        isCommunication = false
                    }){
                        Text("いいえ")
                    }
                }
            }
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            let messagePrefix = "resHMDPosition"
            if peerManager.receivedMessage.hasPrefix(messagePrefix) {
                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: messagePrefix, with: "")
                let data = receivedMessage.data(using: .utf8)!
                let hmdCoordinate = try! JSONDecoder().decode(HMDCoordinate.self, from: data)
                print(hmdCoordinate)
                isCommunication = true
            } else if peerManager.receivedMessage == "receivedSuccessHMDPosition" {
                state = .bothIndexFingerCoordinate
            }
        }
    }
}

struct HMDCoordinateClientView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var state: TransformationMatrixPreparationState
    
    var body: some View {
        VStack {
            Text("3. ヘッドセットの位置を確認").font(.title)
            Divider()
            
            Text("相手が開始ボタンを押してから3秒後に、相手の右手の人差し指で自分のヘッドセットに触れてもらいます")
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            if peerManager.receivedMessage == "reqHMDPosition" {
                let hmdCoordinate = HMDCoordinate(unixTime: Int(Date().timeIntervalSince1970), HMDPosition: [0.0,0.0,0.0,0.0,0.0,0.0])
                let json = try! JSONEncoder().encode(hmdCoordinate)
                let jsonStr = String(data: json, encoding: .utf8) ?? ""
                peerManager.sendMessage("resHMDPosition\(jsonStr)")
            } else if peerManager.receivedMessage == "successHMDPosition" {
                peerManager.sendMessage("receivedSuccessHMDPosition")
                state = .bothIndexFingerCoordinate
            }
        }
    }
}

/*
{
    "unixtime": 1734511201805,
    "indexFingerPosition":{
        "left":[0.0 0.0 0.0 0.0 0.0],
        "right":[0.0 0.0 0.0 0.0 0.0]
    }
}
 */

struct IndexFingerPosition:Codable {
    var left: [Float]
    var right: [Float]
}

struct BothIndexFingerCoordinate:Codable {
    var unixTime: Int
    var indexFingerPosition: IndexFingerPosition
}

struct BothIndexFingerCoordinateHostView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var state: TransformationMatrixPreparationState
    @State var isCommunication = false
    
    var body: some View {
        VStack {
            Text("4. 両手の人差し指の位置を確認").font(.title)
            Divider()
            
            Text("開始ボタンを押してから3秒後に両手の人差し指で相手の人差し指に触れてください")
            
            Button(action: {
                peerManager.sendMessage("reqBothIndexFingerCoordinate")
            }){
                Text("開始")
            }
            .disabled(isCommunication)
            
            Spacer()
            
            if isCommunication {
                Text("両手の人差し指に触れられていましたか？").font(.title2)
                HStack{
                    Button(action: {
                        peerManager.sendMessage("successBothIndexFingerCoordinate")
                    }){
                        Text("はい")
                    }
                    Button(action: {
                        peerManager.sendMessage("reset")
                        isCommunication = false
                    }){
                        Text("いいえ")
                    }
                }
            }
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            let messagePrefix = "resBothIndexFingerCoordinate"
            if peerManager.receivedMessage.hasPrefix(messagePrefix) {
                let receivedMessage = peerManager.receivedMessage.replacingOccurrences(of: messagePrefix, with: "")
                let data = receivedMessage.data(using: .utf8)!
                let bothIndexFingerCoordinate = try! JSONDecoder().decode(BothIndexFingerCoordinate.self, from: data)
                print(bothIndexFingerCoordinate)
                isCommunication = true
            } else if peerManager.receivedMessage == "receivedSuccessBothIndexFingerCoordinate" {
                state = .prepared
            }
        }
    }
}

struct BothIndexFingerCoordinateClientView: View {
    @ObservedObject var peerManager = PeerManager()
    @Binding var state: TransformationMatrixPreparationState
    
    var body: some View {
        VStack {
            Text("4. 両手の人差し指の位置を確認").font(.title)
            Divider()
            
            Text("相手が開始ボタンを押してから3秒後に両手の人差し指で相手の人差し指に触れてください")
            
            Spacer()
        }
        .onChange(of: peerManager.receivedMessage){
            if peerManager.receivedMessage == "reqBothIndexFingerCoordinate" {
                let bothIndexFingerCoordinate = BothIndexFingerCoordinate(unixTime: Int(Date().timeIntervalSince1970), indexFingerPosition: IndexFingerPosition(left: [0.0,0.0,0.0,0.0], right: [0.0,0.0,0.0,0.0]))
                let json = try! JSONEncoder().encode(bothIndexFingerCoordinate)
                let jsonStr = String(data: json, encoding: .utf8) ?? ""
                peerManager.sendMessage("resBothIndexFingerCoordinate\(jsonStr)")
            } else if peerManager.receivedMessage == "successBothIndexFingerCoordinate" {
                peerManager.sendMessage("receivedSuccessBothIndexFingerCoordinate")
                state = .prepared
            }
        }
    }
}

struct PreparedView: View {
    var body: some View {
        VStack {
            Text("設定は完了しました！").font(.title)
            
            Spacer()
        }
    }
}
