//
//  TableView.swift
//  QSS
//
//  Created by Denis Beloshitskiy
//

import SwiftUI

struct TableView: View {
  @EnvironmentObject var appState: AppState

  var body: some View {
    VStack {
      Table(appState.simulation.simulationResult.generatorResults) {
        TableColumn("Generators") {
          Text("№\($0.generator + 1)")
        }
        TableColumn("Handled orders") {
          Text($0.handledOrdersCount, format: .number)
        }
        TableColumn("Processing time (average)") {
          Text($0.avProcessingTime, format: .number)
        }
        TableColumn("In-buffer time (average)") {
          Text($0.avInBufferTime, format: .number)
        }
        TableColumn("Reject %") {
          Text($0.rejectPercent, format: .number)
        }
      }

      Table(appState.simulation.simulationResult.handlerResults) {
        TableColumn("Handler") {
          Text("№\($0.handler + 1)")
        }
        TableColumn("Usage coefficient") {
          Text($0.usageCoefficient, format: .number)
        }
      }

      ControlView()
    }
  }
}

struct TableView_Previews: PreviewProvider {
  static var previews: some View {
    TableView()
      .environmentObject(AppState())
  }
}
