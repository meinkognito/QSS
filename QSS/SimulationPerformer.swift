//
//  ActionHelper.swift
//  QSS
//
//  Created by Denis Beloshitskiy
//

import Foundation
import SwiftPriorityQueue

public class SimulationPerformer: ObservableObject {
  /*
   что должно делать?

   auto -> создаем n генераторов, буфферов и перформеров
   запускаем по нажатию start

   ввод: n
   вывод: OrderContents для таблицы

   manual -> создаем n генераторов, буфферов и перформеров
   запускаем по нажатию start
   делаем шаги по нажатию на кнопку step

   ввод: n
   вывод: пошаговые waveform
   */

  // queue for actions
  @Published private var actions: PriorityQueue<Action>

  // count of actions to be generated
  @Published var ordersCount: Int

  // count of actors of each-type below
  @Published public var actorsCount: Int

  // actors
  @Published public var generators: [Generator]
  @Published public var handlers: [Handler]
  @Published public var buffers: [Buffer]
  @Published public var rejector: Rejector

  // statistics for TableView
  @Published var totalRequestsCount: Int
  @Published var tableResults: [OrderContent]

  // data for WaveformsView
  @Published var chartData: [WaveformPoint]

  // for timestamp graph
  var step: Double

  // MARK: - Inits

  public init(actions: PriorityQueue<Action> = PriorityQueue<Action>(ascending: true), actorsCount: Int = 1) {
    self.actions = actions
    ordersCount = 0

    self.actorsCount = actorsCount
    var generators = [Generator]()
    var handlers = [Handler]()
    var buffers = [Buffer]()

    for _ in 0 ..< actorsCount {
      let gen = Generator()
      let han = Handler()
      let buf = Buffer()

      generators.append(gen)
      handlers.append(han)
      buffers.append(buf)
    }

    self.generators = generators
    self.handlers = handlers
    self.buffers = buffers
    rejector = Rejector()

    step = 0
    totalRequestsCount = 0
    tableResults = []
    chartData = []
  }

  // MARK: - Start

  public func startAuto() {
    fillWithActions()
    guard !actions.isEmpty else {
      return
    }

    while !actions.isEmpty {
      performStep()
    }

    tableResults = getTableResults()
  }

  public func startManual() {
    fillWithActions()
    guard !actions.isEmpty else {
      return
    }
  }

  public func performStep() {
    if let action = actions.pop() {
      step = action.getTimestamp()
      rejector.makeStep(self, actor: .rejector, .straight, stepWidth: step)

      generators.forEach {
        $0.makeStep(self, actor: .generator, .straight, stepWidth: step)
      }
      handlers.forEach {
        $0.makeStep(self, actor: .handler, .straight, stepWidth: step)
      }
      buffers.forEach {
        $0.makeStep(self, actor: .buffer, .straight, stepWidth: step)
      }

      if let act = action.doAction() {
        actions.push(act)
      }
    }
  }

  public func fillWithActions() {
    for _ in 0 ..< ordersCount {
      guard let generator = generators.randomElement() else { return }
      generator.remainingActions += 1
      var timestamp = generator.lastActionTimestamp

      timestamp += Double.generateTimeForAction()
      actions.push(GeneratorAction(timestamp, generator, self))

      generator.lastActionTimestamp = timestamp
    }
  }

  public func reset() {
    step = 0
    totalRequestsCount = 0

    actions.clear()

    generators.removeAll()
    handlers.removeAll()
    buffers.removeAll()
    chartData.removeAll()

    for _ in 0 ..< actorsCount {
      let gen = Generator()
      let han = Handler()
      let buf = Buffer()

      generators.append(gen)
      handlers.append(han)
      buffers.append(buf)
    }
  }

  public func getTableResults() -> [OrderContent] {
    var contents = [OrderContent]()
    OrderContent.totalOrdersCount = ordersCount

    for i in 0 ..< generators.count {
      let currentGen = generators[i]
      let c = OrderContent(generator: i,
                           handledOrdersCount: currentGen.acceptedOrders,
                           avProcessingTime: currentGen.handlingTimes.average,
                           avInBufferTime: currentGen.inBufferTimes.average,
                           rejectCount: currentGen.rejectedRequests)
      contents.append(c)
    }
    return contents
  }
}
