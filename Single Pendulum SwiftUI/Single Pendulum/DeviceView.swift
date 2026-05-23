//
//  DeviceView.swift
//  Pendulum Simulation
//
//  Created by Magdi Laoun on 08.10.2025.
//

import SwiftUI
import MLValue
struct DeviceView: View {
  @State var viewModel: ViewModel
  var isOpen: Bool {
    return viewModel.serialPort != nil
  }
  var body: some View {
    VStack {
      Header(title: "Device control")
      
      HStack(alignment: .top){
        VStack{
          ValuesView(valuesManager: $viewModel.data.k)
          ValuesView(valuesManager: $viewModel.data.li)
          ValuesView(valuesManager: $viewModel.data.sw)
          ValuesView(valuesManager: $viewModel.data.lo)
        }
        .onChange(of: viewModel.data) {old, new in
          viewModel.update(old)
        }
        .onChange(of: viewModel.phase) {
          
          viewModel.updatePhase()
        }
        VStack{
          
          IsOpen(isOpen: isOpen)
          ValuesView(valuesManager: $viewModel.read)
          ValuesView(valuesManager: $viewModel.data.s)
          InitButtonsView(viewModel: viewModel)
          ButtonsView(viewModel: viewModel)
          HStack{
            Button(action: {viewModel.data.lo.values[3].setValue(-0.1)}) {Text("Left")}.frame(width: 80, height: 24).coloredBackground(.white)
            Button(action: {viewModel.data.lo.values[3].setValue(0.0)}) {Text("Middle")}.frame(width: 80, height: 24).coloredBackground(.white)
            Button(action: {viewModel.data.lo.values[3].setValue(0.1)}) {Text("Right")}.frame(width: 80, height: 24).coloredBackground(.white)
          }.frame(width: 80, height: 24).coloredBackground(.white).buttonStyle(.plain)
          SaveView(viewModel: viewModel)
          Text(viewModel.phaseESP.rawValue)
          Button(action: viewModel.balanceDown) {
            Text("Balance Down")
          }
          
          //PickerView(phase: $viewModel.simulator.phase)
          //MiscellaneousButtonsView(pendulum: pendulum)
          
        }
      }
       Spacer()
      
    }
    
  }
  
  struct InitButtonsView: View {
    var viewModel: ViewModel
    var body: some View {
      //let flag = pendulum.flag
      HStack {
        Button(action:viewModel.initDriver) {
          Text("Init Driver").frame(width: 80, height: 24)
            .coloredBackground(.white)
        }.buttonStyle(.plain)
        Spacer()
        Button(action: viewModel.stop) {
          Text("Stop").frame(width: 80, height: 24).foregroundColor(.white)
            .coloredBackground(.red, .blue)
        }.buttonStyle(.plain)
          Spacer()
        
        Button(action: viewModel.initEncoder) {
          Text("Init Encoder").frame(width: 80, height: 24)
            .coloredBackground(.white)
        }.buttonStyle(.plain)
      }.padding(10)
        .coloredBackground(.yellow)
    }
  }
  struct SaveView: View {
    let viewModel: ViewModel
    var body: some View {
      HStack{
        Button(action: viewModel.save) {
          Text("Save")
        }
        Spacer()
        Button(action: viewModel.load) {
          Text("Load")
        }
        Spacer()
        Button(action: viewModel.reset) {
          Text("Reset")
        }
      }
      .padding(10)
      .coloredBackground(.brown.opacity(0.2))
      
    }
  }

  
  struct ButtonsView: View {
    var viewModel: ViewModel
    var body: some View {
      HStack {
        Button(action: {viewModel.start()}){
          Text(viewModel.phase != .stop ? "Stop" : "Start").font(.system(size: 30)).frame(width: 100, height: 100).foregroundColor(.white).coloredBackground(.blue, .black)
        }.buttonStyle(.plain)
        Spacer()
        ButtonLoopView(direction: .cw) {viewModel.looping(.cw)}
        Spacer()
        ButtonLoopView(direction: .ccw) {viewModel.looping(.ccw)}
      }
      .padding(10)
      .coloredBackground(.yellow)
    }
  }
  struct ButtonLoopView: View {
    let action: () -> Void
    let direction: Direction
    var icon: String { direction == .ccw ? "arrow.trianglehead.counterclockwise" : "arrow.trianglehead.clockwise" }
    init(direction: Direction, action: @escaping () -> Void) {
      self.direction = direction
      self.action = action
    }
    var body: some View {
      Button(action: action) {
        ZStack {
          let label: String = direction == .cw ? "CW" : "CCW"
          Image(systemName: icon).font(.system(size: 50))   // taille précise en points
            .foregroundColor(.blue)
          Text(label).font(.headline).fontWeight(.heavy).offset(x:0, y: 2)
            .scaleEffect(x: 1, y: 1.5)
        }.frame(width: 80, height: 80)
          .coloredBackground(.white)
      }.buttonStyle(.plain)
    }
  }
  /*
  struct MiscellaneousButtonsView: View {
    let pendulum: Pendulum
    var body: some View {
      HStack {
        Button(action: pendulum.dumping) {
          Text("Dumping").frame(width: 80, height: 24).coloredBackground(.white)
        }.buttonStyle(.plain)
        Spacer()
        Button(action: pendulum.balance) {
          Text("Balance").frame(width: 80, height: 24).coloredBackground(.white)
        }.buttonStyle(.plain).disabled(pendulum.flag.balance)
        
      }
      .padding(10)
      .coloredBackground(.pink.opacity(0.7))
    }
  }
   */
}

#Preview {
  //DeviceView(viewModel: .init(), pendulum: .init())
}

struct IsOpen: View {
  var isOpen: Bool
  var body: some View {
    Text("Port is \(isOpen ? "Open" : "Closed")")
      .frame(width: 300, height: 20)
      .padding(10)
      .coloredBackground(isOpen ? .green : .red)
  }
}

struct Header: View {
  var title: String
  var body: some View {
    VStack(spacing: 0) {
      Text(title)
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.primary)
        .fixedSize()
      Divider().background(Color.blue)
    }
  }
}
