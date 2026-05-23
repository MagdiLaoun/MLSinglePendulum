//
//  State_.swift
//  Pendulum Simulation2
//
//  Created by Magdi Laoun on 01.09.2025.
//

import Foundation
struct State_: Hashable {
  var a: Double = 0  //angle
  var ad: Double = 0 //angular velocity
  var add: Double = 0 //angular acceleration
  var x: Double = 0 //position
  var xd: Double = 0 //velocity
  var xdd: Double = 0 //acceleration
  var t: Double = 0 //time
  
  func rk1(k: State_, dt: Double) -> State_ {
    State_(
      a: self.a + dt * k.ad,
      ad: self.ad + dt * k.add,
      add: k.add,
      x: self.x + dt * k.xd,
      xd: self.xd + dt * k.xdd,
      xdd: k.xdd,
      t: self.t
    )
  }
  func rk2(k1: State_, k2: State_, k3: State_, k4: State_, dt: Double) -> State_ {
    let state = State_(
      a: self.a + dt/6 * (k1.ad + 2*k2.ad + 2*k3.ad + k4.ad),
      ad: self.ad + dt/6 * (k1.add + 2*k2.add + 2*k3.add + k4.add),
      add: k4.add,
      x: self.x + dt/6 * (k1.xd + 2*k2.xd + 2*k3.xd + k4.xd),
      xd: self.xd + dt/6 * (k1.xdd + 2*k2.xdd + 2*k3.xdd + k4.xdd),
      xdd: k4.xdd,
      t: self.t + dt
    )
    return state
  }
  func rk4(dt: Double, dynamic: (State_) -> State_) -> State_ {
    //Runge-Kutta order 4
    let k1 = dynamic(self)
    let state1 = self.rk1(k: k1, dt: dt/2)
    let k2 = dynamic(state1)
    let state2 = self.rk1(k: k2, dt: dt/2)
    let k3 = dynamic(state2)
    let state3 = self.rk1(k: k3, dt: dt)
    let k4 = dynamic(state3)
    let state4 = self.rk2(k1: k1, k2: k2, k3: k3, k4: k4, dt: dt)
    return state4
  }
  func addPi() -> State_ {
    var state = self
    state.a += .pi
    return state
  }
}

