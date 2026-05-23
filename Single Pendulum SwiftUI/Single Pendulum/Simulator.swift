//
//  Simulator.swift
//  Pendulum Simulation2
//
//  Created by Magdi Laoun on 30.09.2025.
//

import Foundation
import MLValue
struct Simulator {
  private var g: Double = 9.81 // gravity
  private var c: Double = 0.02 // friction
  var l: Double = 0.3 // length of pendulum
  private var m: Double = 0.1 // mass of pendulum
  private var dt: Double = 0 // time step
  var xMax: Double = 0.24
  private var aMax: Double = 3.5 //max acceleration
  private var stepsCount: Int = 5000 // count of iteration
  private var initialAngle: Double = 0 //initial angle of the pendulum
  private var initialPosition: Double = 0
  private var ka: Double = 0 //Coefficient angle
  private var kad: Double = 0 //Coefficient angle velocity
  private var kx: Double = 0 //Coefficient position
  private var kxd: Double = 0 //Coefficient velocity
  private var kickMagnitude: Double = 0.0
  private var kickAcceleration: Double = 0.0
  private var threshold: Double = 0.0 // Threshold
  private var loopingPulse: Double = 0
  private var balanceDownPulse: Double = 0
  private var balanceDownThreshold: Double = 0
  private var counter: Int = 0
  private var profile: Profile = .init()
  private var angle: Double = 0
  private var direction: Direction = .cw
  private var ea: Double = 0 //coefficient energy angle
  private var ex: Double = 0 //coefficient energy cart position
  private var exd: Double = 0 //coefficient energy cart speed
  private var sw: [Double] = []
  private var timeThreshold: Double = 0
  //private var thresholdSW: Double = 0
  var phase: Phase = .swingUp
  private var lastPhase: Phase = .stop
  private var lastState: State_ = .init()
  mutating func resetState(data: MyData) -> State_ {
    updateData(data: data)
    counter = 0
    var state = State_()
    self.phase = .swingUp
    state.x = initialPosition
    state.xd = 0
    state.xdd = 0
    state.a = initialAngle
    state.ad = 0
    state.add = 0
    state.t = 0
    if phase == .swingUp {profile = .init(state: state, x: sw[0], a: sw[1])}
    return state
  }
  
  mutating func updateData(data: MyData) {
    let s = data.s
    let k = data.k
    let li = data.li
    let lo = data.lo
    
    
    g = s.values[0].dble()
    c = s.values[1].dble()
    l = s.values[2].dble()
    m = s.values[3].dble()
    dt = s.values[4].dble()
    
    stepsCount = Int(s.values[5].dble())
    initialAngle = s.values[6].dble()
    ka = k.values[0].dble()
    kad = k.values[1].dble()
    kx = k.values[2].dble()
    kxd = k.values[3].dble()
    xMax = li.values[1].dble()
    aMax = li.values[3].dble()
    
    
    
    loopingPulse = lo.values[0].dble()
    balanceDownPulse = lo.values[1].dble()
    balanceDownThreshold = lo.values[2].dble()
    sw.removeAll()
    for s in data.sw.values {sw.append(s.dble())}
    
    /*
    let sw = data.sw
    kickMagnitude = sw.values[0].dble()
    kickAcceleration = sw.values[1].dble()
    ea = sw.values[2].dble()
    ex = sw.values[3].dble()
    exd = sw.values[4].dble()
    threshold = sw.values[5].dble()
    */
  }
  
  
  private func computeEnergy(state: State_) -> Double {
    let Ep = -m * g * l * (1 + cos(state.a))
    let Ec = 0.5 * m * l * l * state.ad * state.ad
    return Ep + Ec
  }
  mutating func simulate(_ state: State_) -> State_ {
    if phase == .swingUp {
      
      if counter == 0 && state.a < 0 {counter = 1; profile = .init(state: state, x: sw[2], a: sw[3])}
      if counter == 1 && state.ad > 0 {counter = 2; profile = .init(state: state, x: sw[4], a: sw[5])}
      if cos(state.a) < cos(sw[6]) {phase = .balanceUp}
    }
    
    //if phase == .kick && abs(state.x - kickMagnitude) < 0.001 {phase = .swingUp}
    //if phase == .kick && state.ad < 0 {phase = .swingUp}
    //if phase == .swingUp && cos(state.a) < -cos(threshold) {phase = .balanceUp}
    if lastPhase != phase {
      lastPhase = phase
      lastState = state
    }
    return state.rk4(dt: dt, dynamic: dynamic)
  }

  private func dynamic(_ state: State_) -> State_ {
    let xdd = feedback(state)
    let add = -1.5*g/l*sin(state.a)+1.5*xdd/l*cos(state.a) - c*state.ad
    return State_(a: state.a, ad: state.ad, add: add, x: state.x, xd: state.xd, xdd: xdd)
  }
  private func feedback(_ state: State_) -> Double {
    switch phase {
    case .stop:
      return 0
    case .kick:
      let a = getAccel(state0: lastState, state: state, dx: kickMagnitude, a: kickAcceleration)
      return limitAccel(state: state, a: a)
    case .swingUp:
      /*
      let dE = computeEnergy(state: state)
      let signSpeed: Double = state.ad < 0 ? 1 : -1
      let signAngle: Double = cos(state.a) > 0 ? 1 : -1
      let a:Double = ea * dE * signAngle*signSpeed - ex * state.x - exd * state.xd
       */
      let a = profile.getAccel(t: state.t)
      return limitAccel(state: state, a: a)
    case .balanceUp:
      let a = (ka*sin(-state.a)+kad*state.ad+kx*state.x+kxd*state.xd)
      return limitAccel(state: state, a: a)
    case .balanceDown:
      if cos(state.a) < cos(balanceDownThreshold) {return 0}
      let acc = ka*sin(-state.a)/(1+(1-cos(state.a))*5) - kx*state.x - kxd*state.xd
      return acc
    case .loopingCW:
      
      return 0
    case .loopingCCW:
      return 0
    }
    func getAccel(state0: State_, state: State_, dx: Double, a: Double) -> Double {
      let tEnd = pow(dx/a, 0.5)
      if state.t < state0.t + tEnd {return a}
      if state.t < state0.t + 2*tEnd {return -a}
      return 0
    }
    func limitAccel(state: State_, a: Double) -> Double {
      let a = min(max(a, -aMax), aMax)
      if state.xd>0 && state.x + 0.5 * state.xd * state.xd / aMax > xMax {return -aMax}
      if state.xd<0 && state.x + 0.5 * state.xd * state.xd / -aMax < -xMax {return aMax}
      return a
    }
  }
  
}

struct Profile {
  private let t0: Double
  private let t1: Double
  private let t2: Double
  private let t3: Double
  private let x0: Double
  private let v0: Double
  private let a: Double
  init() {
    t0 = 0
    t1 = 0
    t2 = 0
    t3 = 0
    x0 = 0
    v0 = 0
    a = 0
  }
  init(state: State_, x: Double, a: Double) {
    t0 = state.t
    x0 = state.x
    v0 = state.xd
    let sign = x>=x0 ? 1.0 : -1.0
    self.a = sign*abs(a)
    let v02 = v0*v0
    let dt1 = (-2*v0 + sign*sqrt(4*v02 - 4*self.a*(v02/2/self.a - (x-x0))))/(2*self.a)
    t1 = t0 + dt1
    t2 = t1 + dt1
    t3 = t2 + v0/self.a
  }
  func getAccel(t: Double)->Double {
    if t > t3 {return 0}
    if t < t0 {return 0}
    if t<t1 {return a} else {return -a}
  }
  func completed(state: State_) -> Bool {
    return state.t >= t3
  }
}

enum Direction: Double, CaseIterable {
  case cw = 1
  case ccw = -1
}

