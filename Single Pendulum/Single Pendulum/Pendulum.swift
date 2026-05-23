//
//  Pendulum.swift
//  DP_Learning
//
//  Created by Magdi Laoun on 25.01.2026.
//

import MLElements
import Foundation
import SwiftUI


struct Pendulum {
  var elements: Elements = .init()
  private var ground: Elements = .init()
  private var l: CGFloat = 0.0 //length of segment
  private var xMax: CGFloat = 0.0 //max of Rail
  private var state: State_ = .init()
  init() {
    drawGround()
  }
  mutating func drawGround() {
    ground.removeAll()
    ground.size = .init(width: 800, height: 350)
    let rect:CGRect = .init(origin: .init(x: 0, y: 0), size: ground.size)
    ground.append(rect: rect, color: .white, fill: true)
    ground.append(rect: rect, clip: true)
    let width = ground.size.width
    let height = ground.size.height
    let margin:CGFloat = 10.0
    ground.append(x0: margin, y0: height/2, x1: width-margin, y1: height/2, color: .black, lineWidth: 1)
    //let h = 25.0
    //ground.append(x0: width/2-xMax, y0: height/2 - h, x1: width/2-xMax, y1: height/2 + h, color: .red, lineWidth: 3)
    //ground.append(x0: width/2+xMax, y0: height/2 - h, x1: width/2+xMax, y1: height/2 + h, color: .red, lineWidth: 3)
    elements = ground
  }
  mutating func setDimensions(sim: Simulator) {
    l = sim.l * 500
    xMax = sim.xMax * 1000
    drawGround()
    update(state)
  }
  mutating func update(_ state: State_) {
    //function calculating the draw of the pendulum
    //the display is done by the struct PendulumView
    self.state = state
    elements = ground
    
    elements.color = .black
    elements.lineWidth = 3
    let x0 = elements.size.width/2
    let y0 = elements.size.height/2
    let p0 = CGPoint(x: x0 + state.x * 1000, y: y0)
    let p1 = CGPoint(x: p0.x - l * _DarwinFoundation1.sin(state.a), y: p0.y - l * cos(state.a))
    let stroke = Stroke(points: [p0, p1], color: .black, lineWidth: 3)
    
    elements.append(stroke)
    elements.append(point: p0, radius: 10, fill: true)
    elements.append(point: p1, radius: 10, color: .red, fill: true)
    
  }
  func width() -> CGFloat {
    elements.size.width
  }
  func height() -> CGFloat {
    elements.size.height
  }
}
