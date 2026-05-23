//
//  SimulatorView.swift
//  Single Pendulum
//
//  Created by Magdi Laoun on 04.03.2026.
//

import SwiftUI

struct SimulatorView: View {
  @State var viewModel: ViewModel
  var body: some View {
    VStack {
      HStack(alignment: .top) {
        VStack{
          Header(title: "Pendulum")
          GraphView(graph: viewModel.angleGraph)
          //GraphView(graph: viewModel.angleSpeedGraph)
          
        }
        Divider().background(.blue)
        VStack{
          Header(title: "Cart")
          GraphView(graph: viewModel.positionGraph)
          //GraphView(graph: viewModel.speedGraph)
          //GraphView(graph: viewModel.accelGraph)
        }
      }
      Divider().background(.blue)
      PendulumView(pendulum: viewModel.pendulum)
      Button("Start"){
        viewModel.simulatePendulum()
      }
      //Text(viewModel.simulator.phase.rawValue)
    }.fixedSize()
  }
  
  
  
}

#Preview {
  @Previewable @State var viewModel: ViewModel = .init()
  SimulatorView(viewModel: viewModel)
}
struct PickerView: View {
  @Binding var phase: Phase
  var body: some View {
    Picker("Select", selection: $phase) {
      ForEach(Phase.allCases, id: \.self) {type in
        Text(type.rawValue).tag(type)
      }
    }.pickerStyle(.radioGroup)
  }
}
