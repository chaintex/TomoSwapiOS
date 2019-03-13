// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import APIKit
import JSONRPCKit
import JavaScriptKit
import Result
import BigInt
import TrustKeystore
import TrustCore
import Moya

class KNTransactionCoordinator {

  let transactionStorage: TransactionsStorage
  let tokenStorage: KNTokenStorage
  let externalProvider: KNExternalProvider
  let wallet: Wallet
  fileprivate var isLoadingEnabled: Bool = false

  fileprivate var pendingTxTimer: Timer?
  fileprivate var tokenTxTimer: Timer?

  deinit { self.stop() }

  init(
    transactionStorage: TransactionsStorage,
    tokenStorage: KNTokenStorage,
    externalProvider: KNExternalProvider,
    wallet: Wallet
    ) {
    self.transactionStorage = transactionStorage
    self.tokenStorage = tokenStorage
    self.externalProvider = externalProvider
    self.wallet = wallet
  }

  func start() {
    self.isLoadingEnabled = true
    self.startUpdatingCompletedTransactions()
    self.startUpdatingPendingTransactions()
  }

  func stop() {
    self.isLoadingEnabled = false
    self.stopUpdatingPendingTransactions()
    self.stopUpdatingCompletedTransaction()
  }

  func forceUpdateNewTransactionsWhenPendingTxCompleted() {
//    self.isLoadingEnabled = true
//    DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
//      if self.isLoadingEnabled {
//        self.forceFetchTokenTransactions()
//      }
//    }
  }
}

// MARK: ETH/ERC20 Token transactions
extension KNTransactionCoordinator {
  func startUpdatingCompletedTransactions() {
//    self.tokenTxTimer?.invalidate()
//    if KNAppTracker.transactionLoadState(for: self.wallet.address) != .done {
//      self.initialFetchERC20TokenTransactions(
//        forAddress: self.wallet.address,
//        page: 1,
//        completion: nil
//      )
//    }
//    self.forceFetchTokenTransactions()
//    self.tokenTxTimer = Timer.scheduledTimer(
//      withTimeInterval: KNLoadingInterval.loadingListTransactions,
//      repeats: true,
//      block: { [weak self] _ in
//        guard let `self` = self else { return }
//        if self.isLoadingEnabled {
//          self.forceFetchTokenTransactions()
//        }
//      }
//    )
  }

  func stopUpdatingCompletedTransaction() {
    self.tokenTxTimer?.invalidate()
    self.tokenTxTimer = nil
  }

  func forceFetchTokenTransactions() {
    // Load token transaction
//    let startBlock: Int = {
//      guard let transaction = self.transactionStorage.objects.first(where: { !$0.isTOMOTransfer }) else {
//        return 0
//      }
//      return max(0, transaction.blockNumber - 200)
//    }()
//    self.fetchListERC20TokenTransactions(
//      forAddress: self.wallet.address.description,
//      startBlock: startBlock,
//      page: 1,
//      sort: "asc",
//      completion: nil
//    )
//
//    // load internal transaction
//    let lastBlockInternalTx: Int = KNAppTracker.lastBlockLoadInternalTransaction(for: self.wallet.address)
//    self.fetchInternalTransactions(
//      forAddress: self.wallet.address.description,
//      startBlock: max(0, lastBlockInternalTx - 10),
//      completion: nil
//    )
//
//    // load all tx
//    let lastBlockAllTx: Int = KNAppTracker.lastBlockLoadAllTransaction(for: self.wallet.address)
//    self.fetchAllTransactions(
//      forAddress: self.wallet.address.description,
//      startBlock: max(0, lastBlockAllTx - 10),
//      completion: nil
//    )
  }

  func fetchListERC20TokenTransactions(
    forAddress address: String,
    startBlock: Int,
    page: Int,
    sort: String,
    completion: ((Result<[Transaction], AnyError>) -> Void)?
    ) {
//    print("---- ERC20 Token Transactions: Fetching ----")
//    let provider = MoyaProvider<KNEtherScanService>()
//    let service = KNEtherScanService.getListTokenTransactions(
//      address: address,
//      startBlock: startBlock,
//      page: page,
//      sort: sort
//    )
//    DispatchQueue.global(qos: .background).async {
//      provider.request(service) { [weak self] result in
//        guard let `self` = self else { return }
//        DispatchQueue.main.async {
//          switch result {
//          case .success(let response):
//            do {
//              let json: JSONDictionary = try response.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
//              let data: [JSONDictionary] = json["result"] as? [JSONDictionary] ?? []
//              let transactions = data.map({ return KNTokenTransaction(dictionary: $0).toTransaction() }).filter({ self.transactionStorage.get(forPrimaryKey: $0.id) == nil })
//              self.updateListTokenTransactions(transactions)
//              print("---- ERC20 Token Transactions: Loaded \(transactions.count) transactions ----")
//              completion?(.success(transactions))
//            } catch let error {
//              print("---- ERC20 Token Transactions: Parse result failed with error: \(error.prettyError) ----")
//              completion?(.failure(AnyError(error)))
//            }
//          case .failure(let error):
//            print("---- ERC20 Token Transactions: Failed with error: \(error.errorDescription ?? "") ----")
//            completion?(.failure(AnyError(error)))
//          }
//        }
//      }
//    }
  }

  func initialFetchERC20TokenTransactions(forAddress address: Address, page: Int = 1, completion: ((Result<[Transaction], AnyError>) -> Void)?) {
//    self.fetchListERC20TokenTransactions(
//      forAddress: address.description,
//      startBlock: 1,
//      page: page,
//      sort: "desc") { [weak self] result in
//      guard let `self` = self else { return }
//      if address != self.wallet.address { return }
//      switch result {
//      case .success(let transactions):
//        if transactions.isEmpty || self.transactionStorage.tokenTransactions.count >= 1000 {
//          // done loading or too many transactions
//          KNAppTracker.updateTransactionLoadState(.done, for: address)
//        } else {
//          DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25, execute: {
//            self.initialFetchERC20TokenTransactions(
//              forAddress: address,
//              page: page + 1,
//              completion: nil
//            )
//          })
//        }
//        completion?(.success(transactions))
//      case .failure(let error):
//        KNAppTracker.updateTransactionLoadState(.failed, for: address)
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0, execute: {
//          self.initialFetchERC20TokenTransactions(
//            forAddress: address,
//            page: page + 1,
//            completion: nil
//          )
//        })
//        completion?(.failure(AnyError(error)))
//      }
//    }
  }

  // Fetch all transactions, but extract only send ETH transactions
  fileprivate func fetchAllTransactions(forAddress address: String, startBlock: Int, completion: ((Result<[Transaction], AnyError>) -> Void)?) {
//    print("---- All Token Transactions: Fetching ----")
//    let provider = MoyaProvider<KNEtherScanService>()
//    let service = KNEtherScanService.getListTransactions(address: address, startBlock: startBlock)
//    DispatchQueue.global(qos: .background).async {
//      provider.request(service) { [weak self] result in
//        guard let `self` = self else { return }
//        DispatchQueue.main.async {
//          switch result {
//          case .success(let response):
//            do {
//              let json: JSONDictionary = try response.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
//              let data: [JSONDictionary] = json["result"] as? [JSONDictionary] ?? []
//              // Update last block loaded
//              let lastBlockLoaded: Int = {
//                let lastBlock = KNAppTracker.lastBlockLoadAllTransaction(for: self.wallet.address)
//                if !data.isEmpty {
//                  let blockNumber = data[0]["blockNumber"] as? String ?? ""
//                  return Int(blockNumber) ?? lastBlock
//                }
//                return lastBlock
//              }()
//              KNAppTracker.updateAllTransactionLastBlockLoad(lastBlockLoaded, for: self.wallet.address)
//              let transactions = self.updateAllTransactions(address: address, data: data)
//              print("---- All Token Transactions: Loaded \(transactions.count) transactions ----")
//              completion?(.success(transactions))
//            } catch let error {
//              print("---- All Token Transactions: Parse result failed with error: \(error.prettyError) ----")
//              completion?(.failure(AnyError(error)))
//            }
//          case .failure(let error):
//            print("---- All Token Transactions: Failed with error: \(error.errorDescription ?? "") ----")
//            completion?(.failure(AnyError(error)))
//          }
//        }
//      }
//    }
  }

  // Load internal transaction for receiving ETH only
  fileprivate func fetchInternalTransactions(forAddress address: String, startBlock: Int, completion: ((Result<[Transaction], AnyError>) -> Void)?) {
//    print("---- Internal Token Transactions: Fetching ----")
//    let provider = MoyaProvider<KNEtherScanService>()
//    let service = KNEtherScanService.getListInternalTransactions(address: address, startBlock: startBlock)
//    DispatchQueue.global(qos: .background).async {
//      provider.request(service) { [weak self] result in
//        guard let `self` = self else { return }
//        DispatchQueue.main.async {
//          switch result {
//          case .success(let response):
//            do {
//              let json: JSONDictionary = try response.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
//              let data: [JSONDictionary] = json["result"] as? [JSONDictionary] ?? []
//              let lastBlockLoaded: Int = {
//                let lastBlock = KNAppTracker.lastBlockLoadInternalTransaction(for: self.wallet.address)
//                if !data.isEmpty {
//                  let blockNumber = data[0]["blockNumber"] as? String ?? ""
//                  return Int(blockNumber) ?? lastBlock
//                }
//                return lastBlock
//              }()
//              KNAppTracker.updateInternalTransactionLastBlockLoad(lastBlockLoaded, for: self.wallet.address)
//              let eth = KNSupportedTokenStorage.shared.tomoToken
//              let transactions = data.map({ KNTokenTransaction(internalDict: $0, eth: eth).toTransaction() })
//              self.transactionStorage.add(transactions)
//              KNNotificationUtil.postNotification(for: kTokenTransactionListDidUpdateNotificationKey)
//              print("---- Internal Token Transactions: Loaded \(transactions.count) transactions ----")
//              completion?(.success(transactions))
//            } catch let error {
//              print("---- Internal Token Transactions: Parse result failed with error: \(error.prettyError) ----")
//              completion?(.failure(AnyError(error)))
//            }
//          case .failure(let error):
//            print("---- Internal Token Transactions: Failed with error: \(error.errorDescription ?? "") ----")
//            completion?(.failure(AnyError(error)))
//          }
//        }
//      }
//    }
  }

  fileprivate func updateAllTransactions(address: String, data: [JSONDictionary]) -> [Transaction] {
    let eth = KNSupportedTokenStorage.shared.tomoToken

    let completedTransactions: [Transaction] = data.filter({ ($0["isError"] as? String ?? "") == "0" })
      .map({ return KNTokenTransaction(internalDict: $0, eth: eth) })
      .filter({ $0.tokenSymbol.lowercased() == eth.symbol.lowercased() })
      .map({ return $0.toTransaction() })
    let failedTransactions: [Transaction] = data.filter({ ($0["isError"] as? String ?? "") == "1"
    }).map({
      let transaction = KNTokenTransaction(internalDict: $0, eth: eth).toTransaction()
      transaction.internalState = TransactionState.error.rawValue
      return transaction
    })
    var transactions = completedTransactions
    transactions.append(contentsOf: failedTransactions)
    self.updateListTokenTransactions(transactions)
    return transactions
  }

  func updateListTokenTransactions(_ transactions: [Transaction]) {
    if transactions.isEmpty { return }
    self.transactionStorage.add(transactions)
    KNNotificationUtil.postNotification(for: kTokenTransactionListDidUpdateNotificationKey)
    var tokenObjects: [TokenObject] = []
    let savedTokens: [TokenObject] = self.tokenStorage.tokens
    transactions.forEach { tx in
      if let token = tx.getTokenObject(), !tokenObjects.contains(token),
        !savedTokens.contains(token) { tokenObjects.append(token) }
    }
    if !tokenObjects.isEmpty {
      self.tokenStorage.add(tokens: tokenObjects)
      KNNotificationUtil.postNotification(for: kTokenObjectListDidUpdateNotificationKey)
    }
  }
}

// MARK: Pending transactions
extension KNTransactionCoordinator {
  func startUpdatingPendingTransactions() {
    self.pendingTxTimer?.invalidate()
    self.pendingTxTimer = nil
    self.shouldUpdatePendingTransaction(nil)
    self.pendingTxTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
        guard let `self` = self else { return }
        if self.isLoadingEnabled {
          self.shouldUpdatePendingTransaction(timer)
        }
      }
    )
  }

  @objc func shouldUpdatePendingTransaction(_ sender: Any?) {
    let objects = self.transactionStorage.kyberPendingTransactions
    objects.forEach {
      if self.isLoadingEnabled { self.updatePendingTransaction($0) }
    }
  }

  func updatePendingTransaction(_ transaction: KNTransaction) {
    self.checkTransactionReceipt(transaction) { [weak self] error in
      if error == nil { return }
      guard let `self` = self else { return }
      self.externalProvider.getTransactionByHash(transaction.id, completion: { [weak self] sessionError in
        guard let `self` = self else { return }
        guard let trans = self.transactionStorage.get(forPrimaryKey: transaction.id) else { return }
        if trans.state != .pending {
          // Prevent the notification is called multiple time due to timer runs
          return
        }
        if let error = sessionError {
          // Failure
          if case .responseError(let err) = error, let respError = err as? JSONRPCError {
            switch respError {
            case .responseError(let code, let message, _):
              NSLog("Fetch pending transaction with hash \(transaction.id) failed with error code \(code) and message \(message)")
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: respError,
                userInfo: nil
              )
              self.transactionStorage.delete([trans])
              KNNotificationUtil.postNotification(for: kTokenTransactionListDidUpdateNotificationKey)
            case .resultObjectParseError:
              // transaction seems to be removed
              if transaction.date.addingTimeInterval(60) < Date() {
                self.updateTransactionStateIfNeeded(transaction, state: .failed)
              }
            default: break
            }
          }
        }
      })
    }
  }

  fileprivate func checkTransactionReceipt(_ transaction: KNTransaction, completion: @escaping (Error?) -> Void) {
    self.externalProvider.getReceipt(for: transaction) { [weak self] result in
      switch result {
      case .success(let newTx):
        if let trans = self?.transactionStorage.getKyberTransaction(forPrimaryKey: transaction.id), trans.state != .pending {
          // Prevent the notification is called multiple time due to timer runs
          return
        }
        self?.transactionStorage.addKyberTransactions([newTx])
        self?.transactionStorage.add([newTx.toTransaction()])
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: newTx.id,
          userInfo: nil
        )
        KNNotificationUtil.postNotification(for: kTokenTransactionListDidUpdateNotificationKey)
        self?.transactionStorage.delete([transaction])
        completion(nil)
      case .failure(let error):
        completion(error)
      }
    }
  }

  fileprivate func updateTransactionStateIfNeeded(_ transaction: KNTransaction, state: TransactionState) {
    if let trans = self.transactionStorage.getKyberTransaction(forPrimaryKey: transaction.id), trans.state != .pending { return }
    let tx = self.transactionStorage.update(state: state, for: transaction)
    if tx.state == .error || tx.state == .failed {
      self.transactionStorage.add([tx.toTransaction()])
    }
    KNNotificationUtil.postNotification(
      for: kTransactionDidUpdateNotificationKey,
      object: transaction.id,
      userInfo: nil
    )
    KNNotificationUtil.postNotification(for: kTokenTransactionListDidUpdateNotificationKey)
  }

  func stopUpdatingPendingTransactions() {
    self.pendingTxTimer?.invalidate()
    self.pendingTxTimer = nil
  }
}

extension UnconfirmedTransaction {
  func toTransaction(wallet: Wallet, hash: String, nounce: Int) -> Transaction {
    let token: TokenObject = self.transferType.tokenObject()

    let localObject = LocalizedOperationObject(
      from: token.contract,
      to: "",
      contract: nil,
      type: "transfer",
      value: self.value.string(decimals: token.decimals, minFractionDigits: 0, maxFractionDigits: token.decimals),
      symbol: token.symbol,
      name: token.name,
      decimals: token.decimals
    )
    return Transaction(
      id: hash,
      blockNumber: 0,
      from: wallet.address.description,
      to: self.to?.description ?? "",
      value: self.value.string(decimals: token.decimals, minFractionDigits: 0, maxFractionDigits: token.decimals),
      gas: self.gasLimit?.fullString(units: UnitConfiguration.gasFeeUnit) ?? "",
      gasPrice: self.gasPrice?.fullString(units: UnitConfiguration.gasPriceUnit) ?? "",
      gasUsed: self.gasLimit?.fullString(units: UnitConfiguration.gasFeeUnit) ?? "",
      nonce: "\(nounce)",
      date: Date(),
      localizedOperations: [localObject],
      state: .pending
    )
  }
}

extension RawTransaction {
  static func from(dictionary: JSONDictionary) -> RawTransaction {
    let id: String = dictionary["hash"] as? String ?? ""
    let blockNumber = Int(dictionary["blockNumber"] as? String ?? "0") ?? 0
    let from: String = dictionary["from"] as? String ?? ""
    let to: String = dictionary["to"] as? String ?? ""
    let value: String = dictionary["value"] as? String ?? ""
    let gas: String = dictionary["gas"] as? String ?? ""
    let gasPrice: String = dictionary["gasPrice"] as? String ?? ""
    let gasUsed: String = dictionary["gasUsed"] as? String ?? ""
    let nonce: Int = Int(dictionary["nonce"] as? String ?? "0") ?? 0
    let timeStamp: String = dictionary["timeStamp"] as? String ?? ""
    let input: String = dictionary["input"] as? String ?? ""
    let isError: String? = dictionary["isError"] as? String

    return RawTransaction(
      hash: id,
      blockNumber: blockNumber,
      timeStamp: timeStamp,
      nonce: nonce,
      from: from,
      to: to,
      value: value,
      gas: gas,
      gasPrice: gasPrice,
      input: input,
      gasUsed: gasUsed,
      error: isError == "0" ? nil : isError,
      operations: nil
    )
  }
}

// MARK: Transaction Storage Extension
extension TransactionsStorage {

  var nonePendingObjects: [Transaction] {
    return objects.filter({ $0.state != .pending })
  }

  var transferNonePendingObjects: [Transaction] {
    return objects.filter({ $0.state != .pending && $0.isTransfer })
  }

  func addHistoryTransactions(_ transactions: [KNHistoryTransaction]) {
    self.realm.beginWrite()
    self.realm.add(transactions, update: true)
    try! realm.commitWrite()
  }

  func deleteHistoryTransactions(_ transactions: [KNHistoryTransaction]) {
    try! self.realm.write {
      self.realm.delete(transactions)
    }
  }

  func deleteAllHistoryTransactions() {
    try! self.realm.write {
      self.realm.delete(self.realm.objects(KNHistoryTransaction.self))
    }
  }

  var historyTransactions: [KNHistoryTransaction] {
    return self.realm.objects(KNHistoryTransaction.self)
      .sorted(byKeyPath: "blockTimestamp", ascending: false)
      .filter { !$0.id.isEmpty }
  }
}
