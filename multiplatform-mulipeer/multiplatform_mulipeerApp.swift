//
//  multiplatform_mulipeerApp.swift
//  multiplatform-mulipeer
//
//  Created by blueken on 2024/12/07.
//

import SwiftUI

@main
struct multiplatform_mulipeerApp: App {
    @ObservedObject private var peerManager = PeerManager()

    var body: some Scene {
        WindowGroup {
            ContentView(peerManager:peerManager)
        }
    }
}
