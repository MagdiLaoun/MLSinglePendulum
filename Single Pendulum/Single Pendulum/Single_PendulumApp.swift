//
//  Single_PendulumApp.swift
//  Single Pendulum
//
//  Created by Magdi Laoun on 27.02.2026.
//

import SwiftUI

@main
struct Single_PendulumApp: App {
  private var viewModel: ViewModel = .init()
  var body: some Scene {
    WindowGroup {
      ContentView(viewModel: viewModel)
        .frame(width: 1920, height: 1044)
    }
  }
}
