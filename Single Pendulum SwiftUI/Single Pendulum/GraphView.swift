//
//  GraphView.swift
//  DP_Learning
//
//  Created by Magdi Laoun on 21.02.2026.
//

import SwiftUI
import MLElements
import MLGraph
struct GraphView: View {
  var graph: Graph
    var body: some View {
      let size = graph.elements.size
      CoreElementsView(elements: graph.elements)
        .frame(width: size.width, height: size.height)
    }
}
#Preview {
  GraphView(graph: .init(width: 300, height: 200))
}

struct PendulumView: View {
  var pendulum: Pendulum
  var body: some View {
    CoreElementsView(elements: pendulum.elements)
      .frame(width: pendulum.width(), height: pendulum.height())
  }
}
