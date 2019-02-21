// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

protocol KNHistoryCoordinatorDelegate: class {
  func historyCoordinatorDidClose()
}

class KNHistoryCoordinator: Coordinator {

  fileprivate lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy MMM dd"
    return formatter
  }()
  let navigationController: UINavigationController
  private(set) var session: KNSession

  var currentWallet: KNWalletObject

  var coordinators: [Coordinator] = []
  weak var delegate: KNHistoryCoordinatorDelegate?

  lazy var rootViewController: KNHistoryViewController = {
    let viewModel = KNHistoryViewModel(
      completedTxData: [:],
      completedTxHeaders: [],
      pendingTxData: [:],
      pendingTxHeaders: [],
      currentWallet: self.currentWallet
    )
    let controller = KNHistoryViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var txDetailsCoordinator: KNTransactionDetailsCoordinator = {
    return KNTransactionDetailsCoordinator(
      navigationController: self.navigationController,
      transaction: nil,
      currentWallet: self.currentWallet
    )
  }()

  init(
    navigationController: UINavigationController,
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.session = session
    let address = self.session.wallet.address.description
    self.currentWallet = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }

  func start() {
    self.appCoordinatorTokensTransactionsDidUpdate()
    self.navigationController.pushViewController(self.rootViewController, animated: true) {
      let pendingTrans = self.session.transactionStorage.kyberPendingTransactions
      self.appCoordinatorPendingTransactionDidUpdate(pendingTrans)
    }
    self.session.transacionCoordinator?.forceFetchTokenTransactions()
  }

  func stop() {
    self.navigationController.popViewController(animated: true) {
      self.delegate?.historyCoordinatorDidClose()
    }
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    let address = self.session.wallet.address.description
    self.currentWallet = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
    self.appCoordinatorTokensTransactionsDidUpdate()
  }

  func appCoordinatorDidUpdateWalletObjects() {
    self.rootViewController.coordinatorUpdateWalletObjects()
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    let transactions: [Transaction] = self.session.transactionStorage.transferNonePendingObjects

    let dates: [String] = {
      let dates = transactions.map { return self.dateFormatter.string(from: $0.date) }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      return uniqueDates
    }()

    let sectionData: [String: [Transaction]] = {
      var data: [String: [Transaction]] = [:]
      transactions.forEach { tx in
        var trans = data[self.dateFormatter.string(from: tx.date)] ?? []
        trans.append(tx)
        data[self.dateFormatter.string(from: tx.date)] = trans
      }
      return data
    }()
    self.rootViewController.coordinatorUpdateCompletedTransactions(
      data: sectionData,
      dates: dates,
      currentWallet: self.currentWallet
    )
  }

  func appCoordinatorPendingTransactionDidUpdate(_ transactions: [KNTransaction]) {
    let dates: [String] = {
      let dates = transactions.map { return self.dateFormatter.string(from: $0.date) }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      return uniqueDates
    }()

    let sectionData: [String: [Transaction]] = {
      var data: [String: [Transaction]] = [:]
      transactions.forEach { tx in
        var trans = data[self.dateFormatter.string(from: tx.date)] ?? []
        trans.append(tx.toTransaction())
        data[self.dateFormatter.string(from: tx.date)] = trans
      }
      return data
    }()

    self.rootViewController.coordinatorUpdatePendingTransaction(
      data: sectionData,
      dates: dates,
      currentWallet: self.currentWallet
    )
    self.txDetailsCoordinator.updatePendingTransactions(transactions, currentWallet: self.currentWallet)
  }
}

extension KNHistoryCoordinator: KNHistoryViewControllerDelegate {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent) {
    switch event {
    case .selectTransaction(let transaction):
      self.txDetailsCoordinator.update(
        transaction: transaction,
        currentWallet: self.currentWallet
      )
      self.txDetailsCoordinator.start()
    case .dismiss:
      self.stop()
    }
  }

  fileprivate func openEtherScanForTransaction(with hash: String) {
    if let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint, let url = URL(string: "\(etherScanEndpoint)tx/\(hash)") {
      self.rootViewController.openSafari(with: url)
    }
  }
}
