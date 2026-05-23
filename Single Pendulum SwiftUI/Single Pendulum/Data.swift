//
//  Data.swift
//  Single Pendulum
//
//  Created by Magdi Laoun on 27.02.2026.
//

import Foundation
import MLValue
import MLUnit
import SwiftUI
struct MyData: Codable, Equatable {
  var k: ValuesManager = .init(title: "Regulation coefficients", color: .brown) //
  var q: ValuesManager = .init(title: "coefficients of regulation", color: .red) //coefficients of Ricatti ponderation
  var m: ValuesManager = .init(title: "title", color: .red) //machine parameters
  var s: ValuesManager = .init(title: "Simulation parameters", color: .red) //simulation
  var e: ValuesManager = .init(title: "title", color: .red)  //initial parameters
  var li: ValuesManager = .init(title: "Limits parameters", color: .red)  //limits parameters
  var lo: ValuesManager = .init(title: "Looping parameters", color: .purple)  //Looping parameters
  var sw: ValuesManager = .init(title: "swing up parameters", color: .yellow)  //Swing-up parameters
  init() {
    k.values = [
      .init("kpa [m/rad/s^2]", 0x20, double: 220, min: 0, max: 500),
      .init("kda [m/rad/s]", 0x21, double: 22, min: 0, max: 100),
      .init("kpx [1/s^2]", 0x22, double: 177, min: 0, max: 500),
      .init("kdx [1/s]", 0x23, double: 62, min: 0, max: 100)
    ]
    q.values = [
      .init("q0", double: 1, min: 0, max: 10),
      .init("q1", double: 1, min: 0, max: 10),
      .init("q2", double: 1, min: 0, max: 10),
      .init("q3", double: 1, min: 0, max: 10),
      .init("r", double: 1, min: 0, max: 10)
    ]
    m.values = [
      .init("Encoder resolution", double: 10000), //0
      .init("Motor steps/rev", double: 200), //1
      .init("Motor microsteps/step", double: 16), //2
      .init("distance per rev.", double: 0.08), //3
      .init("Motor accel ratio", double: 0.15) //4
    ]
    s.values = [
      .init("Gravity [m/s^2]", double: 9.81), //0
      .init("Friction coefficient", double: 0.04), //1
      .init("Length of pendulum", 0x31, double: 305, min: 0, max: 400, unit: .mm), //2
      .init("Mass of pendulum", 0x30, double: 100, min: 0, max: 200, unit: .g), //3
      .init("Time step [s]", double: 0.001, unit: .s), //4
      .init("Duration of sim", double: 4, unit: .s), //5
      .init("Initial angle [degree]", double:  0, unit: .deg), //6
    ]
    li.values = [
      .init("Current", 0x03, double: 0.65, min: 0, max: 1, unit: .A),
      .init("Max magnitude (rail)", 0x05, double: 245, min: 0, max: 300, unit: .mm), //0
      .init("Max speed", 0x06, double: 3000, min: 0, max: 3000, unit: .mm_s), //1
      .init("Max acceleration", 0x07, double: 18, min: 0, max: 20, unit: .m_s2), //2
      ]
    lo.values = [
      .init("Looping pulse", 0x32, double: 8, min: 0, max: 20, unit: .mm),
      .init("Balance down pulse", 0x33, double: 10, min: 0, max: 100, unit: .mm),
      .init("Balance down threshold", 0x34, double: 150, min: 0, max: 180, unit: .deg),
      .init("Position", 0x35, double: 0, min: -300, max: 300, unit: .mm)
    ]
    sw.values = [
      .init("position 1", 0x11, double: 131, min: -200, max: 200, unit: .mm),
      .init("Acceleration 1", 0x12, double: 2.7, min: 0, max: 20, unit: .m_s2),
      .init("position 2", 0x13, double: -210, min: -300, max: 200, unit: .mm),
      .init("Acceleration 2", 0x14, double: 18, min: 0, max: 20, unit: .m_s2),
      .init("position 3", 0x15, double: 0, min: -300, max: 200, unit: .mm),
      .init("Acceleration 3", 0x16, double: 18, min: 0, max: 20, unit: .m_s2),
      .init("threshold", 0x17, double: 112, min: 0, max: 180, unit: .deg),
    ]
    /*
    sw.values = [
      .init("Kick magnitude", 0x11, double: 120, min: 0, max: 300, unit: .mm),
      .init("Kick acceleration", 0x12, double: 3, min: 0, max: 20, unit: .m_s2),
      .init("angle energy coefficient", 0x13, double: 30.8, min: 0, max: 200),
      .init("position energy coefficient", 0x14, double: 0, min: 0, max: 50),
      .init("speed energy coefficient", 0x15, double: 0, min: 0, max: 10),
      .init("threshold", 0x16, double: 160, min: 0, max: 168, unit: .deg),
    ]
     */
  }
  
  func array() -> [Value] {
    return k.values + q.values + m.values + e.values + li.values + lo.values + sw.values + s.values
  }
  
}
