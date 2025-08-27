//
//  dafoma_31App.swift
//  PixelPlay Avi
//
//  Created by Вячеслав on 8/26/25.
//

import SwiftUI
import CoreData

@main
struct PixelPlayAviApp: App {
    let persistenceController = DataService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
        }
    }
}
