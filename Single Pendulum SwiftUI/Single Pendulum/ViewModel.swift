//
//  ViewModel.swift
//  Pendulum Simulation
//
//  Created by Magdi Laoun on 14.08.2025.
//

import Foundation
import Combine
import ORSSerial
import SwiftUI
import UniformTypeIdentifiers
import MLValue
import MLGraph
import MLUnit
@Observable class ViewModel: NSObject, ORSSerialPortDelegate {
  func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
    closePort()
  }
  let saveName: String = "myData"
  var data: MyData = MyData()
  //var states: [State_] = []
  var firstState: State_ = .init(a: 0.2, ad: 0, add: 0, x: 0, xd: 0, xdd: 0, t: 0)
  var serialPort: ORSSerialPort?
  var read: ValuesManager = .init(title: "Read parameters", color: .green, style: .read) //read value
  var phase: Phase = .stop
  var phaseESP: Phase = .stop
  var time: DispatchTime = .now()
  var simulator: Simulator = .init()
  var pendulum: Pendulum = .init()
  var angleGraph: Graph = .init(width: 400, height: 250)
  var angleSpeedGraph: Graph = .init(width: 400, height: 250)
  var positionGraph: Graph = .init(width: 400, height: 250)
  var speedGraph: Graph = .init(width: 400, height: 250)
  var accelGraph: Graph = .init(width: 400, height: 250)
  private var state: State_ = .init()
  private var states: [State_] = []
  private var computeTimer: DispatchSourceTimer?
  private var publishTimer: AnyCancellable?
  override init() {
    super.init()
    read.values = [
      .init("Encoder Pos", 0x00, double: 0, unit: .deg),
      .init("Encoder Speed", 0x01, double: 0, unit: .rad_s),
      .init("Motor Position [mm]", 0x02, double: 0, unit: .mm),
      .init("Motor Speed", 0x03, double: 0, unit: .mm),
      .init("Cycle Time", 0x04, double: 0, unit: .s)
      //.init("Custom 1", 0x04, double: 0),
      //.init("Custom 2", 0x06, double: 0)
    ]
    reset()
    load()
    
    openPort()
    update(all: true, data)
    updatePhase()
  }
  func openPort() {
    serialPort = ORSSerialPort.openSerialPort()
    if let port = serialPort {
      port.delegate = self
    }
    
  }
  func closePort() {
    serialPort?.close()
    serialPort = nil
    print("port is closed")
  }
  func reset() {
   
  }
  func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
    guard data.count == 25 else {
      return
    }
    guard data[0] == 0xAA else {
      print("Octet de synchronisation invalide: \(data[0])")
      return
    }
    for i in 0..<read.values.count {
      let data = data.subdata(in: 4*i+1..<4*i+5)
      read.values[i].update(with: data)
    }
    let data = data.subdata(in: 21..<25)
    let indexPhase = Float(data.withUnsafeBytes { $0.load(as: Float.self) })
    phaseESP.set(index: indexPhase)
    if Float(DispatchTime.now().uptimeNanoseconds - time.uptimeNanoseconds)*1e-9 > 0.1 {
      phase = phaseESP
    }
  }
  func simulatePendulum() {
    if computeTimer == nil {
      startSimulation()
    }else{
      stopSimulation()
    }
  }
  func startSimulation() {
    state = simulator.resetState(data: data)
    let dt = data.s.values[4].dble()
    computeTimer = DispatchSource.makeTimerSource(queue: .global())
    computeTimer?.schedule(deadline: .now(), repeating: .microseconds(Int(dt*1000000)))
    computeTimer?.setEventHandler {
      self.state = self.simulator.simulate(self.state)  //compute the movement
    }
    computeTimer?.resume()
    publishTimer = Timer.publish(every: 0.016, on: .main, in: .common)
      .autoconnect()
      .sink {t in
        self.pendulum.update(self.state)
      }
  }
  func stopSimulation() {
    computeTimer?.cancel()
    computeTimer = nil
    publishTimer?.cancel()
    publishTimer = nil
    
  }
  func save() {
    let defaults = UserDefaults.standard
    if let encodedData = try? JSONEncoder().encode(data) {
      defaults.set(encodedData, forKey: saveName)
    }
  }
  func load() {
    let defaults = UserDefaults.standard
    if let savedData = defaults.data(forKey: saveName) {
      let decoder = JSONDecoder()
      if let loadedData = try? decoder.decode(MyData.self, from: savedData) {
        data = loadedData
      }else{
        reset()
      }
    }else{
      reset()
    }
  }
  func update(all: Bool = false, _ old: MyData) {
    var values: [Value] = []
    for i in 0..<data.array().count {
      if old.array()[i] != data.array()[i] || all {
        values.append(data.array()[i])
      }
    }
    for value in values.filter({$0.address != 0xFF}) {
      serialPort?.sendFloatData(instruction: value.address, value: Float(value.dble()))
    }
    updateGraph()
    state = simulator.resetState(data: data)
    pendulum.setDimensions(sim: simulator)
    pendulum.update(state)
  }
  
  func updatePhase() {
    time = DispatchTime.now()
    serialPort?.sendFloatData(instruction: 0x00, value: self.phase.value())
  }
  func updateGraph(){
    
    state = simulator.resetState(data: data)
    simulate()
    let T = data.s.values[5].dble()
    let timeAxis:MLGraph.Axis = .init(label: "Time", min: 0, max: T, count: 9, unit: .ms)
    angleGraph.xAxis = timeAxis
    angleSpeedGraph.xAxis = timeAxis
    positionGraph.xAxis = timeAxis
    speedGraph.xAxis = timeAxis
    accelGraph.xAxis = timeAxis
    let a = Angle(degrees: 200).radians
    angleGraph.yAxis = .init(label: "Angle", min: -a, max: a, count: 11, unit: .deg)
    angleSpeedGraph.yAxis = .init(label: "Angular Speed", min: -20, max: 20, count: 11, unit: .rad_s)
    positionGraph.yAxis = .init(label: "Position", min: -0.3, max: 0.3, count: 11, unit: .mm)
    speedGraph.yAxis = .init(label: "Speed", min: -3, max: 3, count: 11, unit: .mm_s)
    accelGraph.yAxis = .init(label: "Acceleration", min: -20, max: 20, count: 11, unit: .rad_s2)
    var curve: Curve = .init(color: .blue)
    curve.ys = states.map{CGFloat($0.a)}
    curve.xs = states.map{CGFloat($0.t)}
    angleGraph.curves = [curve]
    angleGraph.updateGrid()
    angleGraph.updateElements()
    curve.ys = states.map{CGFloat($0.ad)}
    angleSpeedGraph.curves = [curve]
    angleSpeedGraph.updateGrid()
    angleSpeedGraph.updateElements()
    curve.ys = states.map{CGFloat($0.xdd)}
    accelGraph.curves = [curve]
    accelGraph.updateGrid()
    accelGraph.updateElements()
    curve.ys = states.map{CGFloat($0.x)}
    positionGraph.curves = [curve]
    positionGraph.updateGrid()
    positionGraph.updateElements()
    curve.ys = states.map{CGFloat($0.xd)}
    speedGraph.curves = [curve]
    speedGraph.updateGrid()
    speedGraph.updateElements()
    
  }
  func simulate(){
    states.removeAll()
    let dt = data.s.values[4].dble()
    let T = data.s.values[5].dble()
    var state:State_ = state
    for _ in 0..<Int(T/dt) {
      state = simulator.simulate(state)
      states.append(state)
    }
  }
  func initDriver(){
    serialPort?.sendFloatData(instruction: 0x01, value: 0)
  }
  func stop() {
    phase = .stop
  }
  func start() {
    if phase == .balanceDown {phase = .stop; return}
    if phase == .stop {phase = .swingUp} else {phase = .balanceDown}
  }
  func initEncoder() {
    serialPort?.sendFloatData(instruction: 0x02, value: 0)
  }
  func balanceDown() {
    phase = .balanceDown
  }
  
  func looping(_ direction: Direction) {
    switch direction {
    case .cw: phase = .loopingCW
    case .ccw: phase = .loopingCCW
    }
  }
}

enum Phase: String, CaseIterable {
  case stop = "Stop"
  case kick = "Kick"
  case swingUp = "Swing Up"
  case balanceUp = "Balance Up"
  case balanceDown = "Balance Down"
  case loopingCW = "Looping CW"
  case loopingCCW = "Looping CCW"
  func value() -> Float {
    Float(Self.allCases.firstIndex(of: self)!)
  }
  mutating func set(index: Float) {
    self = Self.allCases.first(where: { $0.value() == index }) ?? .stop
  }
}
