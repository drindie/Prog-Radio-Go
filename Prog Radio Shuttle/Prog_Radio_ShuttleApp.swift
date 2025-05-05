//
//  Prog_Radio_ShuttleApp.swift
//  Prog Radio Shuttle
//
//  Created by Kevin Carmony on 5/4/25.
//

import SwiftUI

@main
struct Prog_Radio_ShuttleApp: App {

    init() {
        // TEMPORARY DELAY to show LaunchScreen
        /// Thread.sleep(forTimeInterval: 3)
        
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = UIColor.systemBlue
        appearance.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3) // light gray for unselected background

        let whiteTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white
        ]

        appearance.setTitleTextAttributes(whiteTextAttributes, for: .normal)
        appearance.setTitleTextAttributes(whiteTextAttributes, for: .selected)
    }





    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
