//
//  NewsAppApp.swift
//  NewsApp
//
//  Created by Mob_04 on 18/09/26.
//

import SwiftUI

@main
struct NewsAppApp: App {
    init() {
        FontRegistrar.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            NewsFeedView()
        }
    }
}
