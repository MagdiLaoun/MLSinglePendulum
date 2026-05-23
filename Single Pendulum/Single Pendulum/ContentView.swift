//
//  ContentView.swift
//  Single Pendulum
//
//  Created by Magdi Laoun on 27.02.2026.
//

import SwiftUI

struct ContentView: View {
  @State var viewModel: ViewModel
  var body: some View {
    VStack {
      HStack(alignment: .top){
        DeviceView(viewModel: viewModel).fixedSize()
        Divider().background(Color.blue)
        SimulatorView(viewModel: viewModel)
        Spacer()
      }
      Spacer()
    }.padding(20)
    .onDisappear {
      viewModel.closePort()
      exit(0)
    }
  }
}

#Preview {
  ContentView(viewModel: .init())
}
