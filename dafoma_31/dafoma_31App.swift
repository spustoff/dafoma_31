//
//  dafoma_31App.swift
//  PixelAvi Play
//
//  Created by Вячеслав on 8/26/25.
//

import SwiftUI
import CoreData

@main
struct PixelAviPlayApp: App {
    let persistenceController = DataService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.context)
        }
    }
}
