// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore
import JavaScriptKit

class KNExternalProvider {

  let keystore: Keystore
  fileprivate var account: Account
  let web3Swift: Web3Swift
  let knCustomRPC: KNCustomRPC!
  let networkAddress: Address!

  var minTxCount: Int {
    didSet {
      KNAppTracker.updateTransactionNonce(self.minTxCount, address: self.account.address)
    }
  }

  init(web3: Web3Swift, keystore: Keystore, account: Account) {
    self.keystore = keystore
    self.account = account
    self.web3Swift = web3
    let customRPC: KNCustomRPC = KNEnvironment.default.knCustomRPC!
    self.knCustomRPC = customRPC
    self.networkAddress = Address(string: customRPC.networkAddress)
    self.minTxCount = 0
  }

  func updateNonceWithLastRecordedTxNonce(_ nonce: Int) {
    self.minTxCount = max(self.minTxCount, nonce)
  }

  func updateNewAccount(_ account: Account) {
    self.account = account
    self.minTxCount = 0
  }

  // MARK: Balance
  public func getETHBalance(completion: @escaping (Result<Balance, AnyError>) -> Void) {
    KNGeneralProvider.shared.getETHBalanace(
      for: self.account.address.description,
      completion: completion
    )
  }

  public func getTokenBalance(for contract: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getTokenBalance(
      for: self.account.address,
      contract: contract,
      completion: completion
    )
  }

  // MARK: Transaction
  func getTransactionCount(completion: @escaping (Result<Int, AnyError>) -> Void) {
    KNGeneralProvider.shared.getTransactionCount(
    for: self.account.address.description) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let txCount):
        self.minTxCount = max(self.minTxCount, txCount)
        completion(.success(txCount))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func transfer(transaction: UnconfirmedTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success:
        self.requestDataForTokenTransfer(transaction, completion: { [weak self] dataResult in
          guard let `self` = self else { return }
          switch dataResult {
          case .success(let data):
            self.signTransactionData(from: transaction, nonce: self.minTxCount, data: data, completion: { signResult in
              switch signResult {
              case .success(let signData):
                KNGeneralProvider.shared.sendSignedTransactionData(signData, completion: { [weak self] result in
                  guard let `self` = self else { return }
                  if case .success = result { self.minTxCount += 1 }
                  completion(result)
                })
              case .failure(let error):
                completion(.failure(error))
              }
            })
          case .failure(let error):
            completion(.failure(error))
          }
        })
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func exchange(exchange: KNDraftExchangeTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success:
        self.requestDataForTokenExchange(exchange, completion: { [weak self] dataResult in
          guard let `self` = self else { return }
          switch dataResult {
          case .success(let data):
            self.signTransactionData(from: exchange, nonce: self.minTxCount, data: data, completion: { signResult in
              switch signResult {
              case .success(let signData):
                KNGeneralProvider.shared.sendSignedTransactionData(signData, completion: { [weak self] result in
                  guard let `self` = self else { return }
                  if case .success = result { self.minTxCount += 1 }
                  completion(result)
                })
              case .failure(let error):
                completion(.failure(error))
              }
            })
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        })
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getReceipt(for transaction: KNTransaction, completion: @escaping (Result<KNTransaction, AnyError>) -> Void) {
    let request = KNGetTransactionReceiptRequest(hash: transaction.id)
    Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let receipt):
        self.getExchangeTransactionDecode(receipt.logsData, completion: { decodeResult in
          let dict: JSONDictionary? = {
            if case .success(let json) = decodeResult {
              return json
            }
            return nil
          }()
          let newTransaction = receipt.toTransaction(from: transaction, logsDict: dict)
          completion(.success(newTransaction))
        })
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getTransactionByHash(_ hash: String, completion: @escaping (SessionTaskError?) -> Void) {
    let request = GetTransactionRequest(hash: hash)
    Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { result in
      switch result {
      case .success:
        completion(nil)
      case .failure(let error):
        completion(error)
      }
    }
  }

  // If the value returned > 0 consider as allowed
  // should check with the current send amount, however the limit is likely set as very big
  func getAllowance(token: TokenObject, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getAllowance(
      for: token,
      address: self.account.address,
      networkAddress: self.networkAddress,
      completion: completion
    )
  }

  // Encode function, get transaction count, sign transaction, send signed data
  func sendApproveERC20Token(exchangeTransaction: KNDraftExchangeTransaction, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.sendApproveERCToken(
      for: exchangeTransaction.from,
      value: BigInt(2).power(255),
      completion: completion
    )
  }

  func sendApproveERCToken(for token: TokenObject, value: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    KNGeneralProvider.shared.approve(
      token: token,
      value: value,
      account: self.account,
      keystore: self.keystore,
      currentNonce: self.minTxCount,
      networkAddress: self.networkAddress
    ) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let txCount):
          self.minTxCount = txCount
          completion(.success(true))
        case .failure(let error):
          completion(.failure(error))
        }
    }
  }

  // MARK: Rate
  func getExpectedRate(from: TokenObject, to: TokenObject, amount: BigInt, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    KNGeneralProvider.shared.getExpectedRate(
      from: from,
      to: to,
      amount: amount,
      completion: completion
    )
  }

  // MARK: Estimate Gas
  func getEstimateGasLimit(for transferTransaction: UnconfirmedTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {

    let defaultGasLimit: BigInt = {
      KNGasConfiguration.calculateDefaultGasLimitTransfer(token: transferTransaction.transferType.tokenObject())
    }()
    self.requestDataForTokenTransfer(transferTransaction) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: self.account.address.description,
          to: self.addressToSend(transferTransaction)?.description,
          gasPrice: transferTransaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
          value: self.valueToSend(transferTransaction),
          data: data,
          defaultGasLimit: defaultGasLimit,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getEstimateGasLimit(for exchangeTransaction: KNDraftExchangeTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let value: BigInt = exchangeTransaction.from.isTOMO ? exchangeTransaction.amount : BigInt(0)

    let defaultGasLimit: BigInt = {
      return KNGasConfiguration.calculateDefaultGasLimit(from: exchangeTransaction.from, to: exchangeTransaction.to)
    }()

    self.requestDataForTokenExchange(exchangeTransaction) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: self.account.address.description,
          to: self.networkAddress.description,
          gasPrice: exchangeTransaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
          value: value,
          data: data,
          defaultGasLimit: defaultGasLimit,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  static func estimateGasLimit(from: String, to: String?, gasPrice: BigInt, value: BigInt, data: Data, defaultGasLimit: BigInt, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let request = KNEstimateGasLimitRequest(
      from: from,
      to: to,
      value: value,
      data: data,
      gasPrice: gasPrice
    )
    NSLog("------ Estimate gas used ------")
    Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { result in
      switch result {
      case .success(let value):
        let gasLimit: BigInt = {
          var limit = BigInt(value.drop0x, radix: 16) ?? BigInt()
          // Used  120% of estimated gas for safer
          limit += (limit * 20 / 100)
          return min(limit, defaultGasLimit)
        }()
        NSLog("------ Estimate gas used: \(gasLimit.fullString(units: .wei)) ------")
        completion(.success(gasLimit))
      case .failure(let error):
        NSLog("------ Estimate gas used failed: \(error.localizedDescription) ------")
        completion(.failure(AnyError(error)))
      }
    }
  }

  // MARK: Sign transaction
  private func signTransactionData(from transaction: UnconfirmedTransaction, nonce: Int, data: Data?, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let defaultGasLimit: BigInt = KNGasConfiguration.calculateDefaultGasLimitTransfer(token: transaction.transferType.tokenObject())
    let signTransaction: SignTransaction = SignTransaction(
      value: self.valueToSend(transaction),
      account: self.account,
      to: self.addressToSend(transaction),
      nonce: nonce,
      data: data ?? Data(),
      gasPrice: transaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
      gasLimit: transaction.gasLimit ?? defaultGasLimit,
      chainID: KNEnvironment.default.chainID
    )
    self.signTransactionData(from: signTransaction, completion: completion)
  }

  private func signTransactionData(from exchange: KNDraftExchangeTransaction, nonce: Int, data: Data, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let signTransaction: SignTransaction = SignTransaction(
      value: exchange.from.isTOMO ? exchange.amount : BigInt(0),
      account: self.account,
      to: self.networkAddress,
      nonce: nonce,
      data: data,
      gasPrice: exchange.gasPrice ?? KNGasConfiguration.gasPriceDefault,
      gasLimit: exchange.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault,
      chainID: KNEnvironment.default.chainID
    )
    self.signTransactionData(from: signTransaction, completion: completion)
  }

  private func signTransactionData(from signTransaction: SignTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let signResult = self.keystore.signTransaction(signTransaction)
    switch signResult {
    case .success(let data):
      completion(.success(data))
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
  }

  // MARK: Web3Swift Encode/Decode data
  func getExchangeTransactionDecode(_ data: String, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = KNExchangeEventDataDecode(data: data)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let json):
        completion(.success(json))
      case .failure(let error):
        if let err = error.error as? JSErrorDomain {
          if case .invalidReturnType(let object) = err, let json = object as? JSONDictionary {
            completion(.success(json))
            return
          }
        }
        completion(.failure(AnyError(error)))
      }
    }
  }

  func requestDataForTokenTransfer(_ transaction: UnconfirmedTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    if transaction.transferType.isTOMOTransfer() {
      completion(.success(Data()))
      return
    }
    self.web3Swift.request(request: ContractERC20Transfer(amount: transaction.value, address: transaction.to?.description ?? "")) { (result) in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func requestDataForTokenExchange(_ exchange: KNDraftExchangeTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = KNExchangeRequestEncode(exchange: exchange, address: self.account.address)
    self.web3Swift.request(request: encodeRequest) { result in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  // MARK: Helper
  private func valueToSend(_ transaction: UnconfirmedTransaction) -> BigInt {
    return transaction.transferType.isTOMOTransfer() ? transaction.value : BigInt(0)
  }

  private func addressToSend(_ transaction: UnconfirmedTransaction) -> Address? {
    let address: Address? = {
      switch transaction.transferType {
      case .ether: return transaction.to
      case .token(let token):
        return token.address
      }
    }()
    return address
  }
}
