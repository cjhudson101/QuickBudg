//
//  QuickBudgApp.swift
//  QuickBudg
//
//  Created by Chris Hudson on 10/21/24.
//

import SwiftUI
import RealmSwift

@main
struct QuickBudgApp: SwiftUI.App {
    
    init() {
            if let realmFilePath = Realm.Configuration.defaultConfiguration.fileURL {
                print("Realm file path: \(realmFilePath)")
            }
        }
        
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
