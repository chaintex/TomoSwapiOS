// Copyright SIX DAY LLC. All rights reserved.

import Moya
import Result

class KNInternalProvider {

  static let shared = KNInternalProvider()

  let provider = MoyaProvider<KyberNetworkService>()

  // MARK: Gas
  func getKNCachedMaxGasPrice(completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    self.performFetchRequest(service: .getMaxGasPrice, completion: completion)
  }

  func getKNCachedGasPrice(completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    self.performFetchRequest(service: .getGasPrice, completion: completion)
  }

  // MARK: Rate
  func getKNExchangeTokenRate(completion: @escaping (Result<[KNRate], AnyError>) -> Void) {
    self.performFetchRequest(service: .getRate) { [weak self] result in
      guard let _ = `self` else { return }
      switch result {
      case .success(let object):
        let jsonArr: [JSONDictionary] = object["data"] as? [JSONDictionary] ?? []
        if isDebug { print("Load KN exchange rates successfully: \(jsonArr)") }
        var rates: [KNRate] = []
        for json in jsonArr {
          do {
            let rate = try KNRate(dictionary: json, isUSDRate: false)
            rates.append(rate)
          } catch {}
        }
        completion(.success(rates))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getKNExchangeRateUSD(completion: @escaping (Result<[KNRate], AnyError>) -> Void) {
    self.performFetchRequest(service: .getRateUSD) { [weak self] (result) in
      guard let _ = `self` else { return }
      switch result {
      case .success(let object):
        do {
          let jsonArr: [JSONDictionary] = object["data"] as? [JSONDictionary] ?? []
          if isDebug { print("Load KN USD exchange rates successfully: \(jsonArr)") }
          let rates = try jsonArr.map({ return try KNRate(dictionary: $0, isUSDRate: true) })
          completion(.success(rates))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  // MARK: History trade
//  func getKNRecentTrades(completion: @escaping (Result<[KNTransaction], AnyError>) -> Void) {
//    self.performFetchRequest(service: .getHistoryOneColumn) { (result) in
//      switch result {
//      case .success(let json):
//        do {
//          if isDebug { print("Load recent trades successfully: \(json)") }
//          let jsonArray: [JSONDictionary] = try kn_cast(json["data"])
//          let transactions = try jsonArray.map({ return try KNTransaction(dictionary: $0) })
//          completion(.success(transactions))
//        } catch let error {
//          completion(.failure(AnyError(error)))
//        }
//      case .failure(let error):
//        completion(.failure(error))
//      }
//    }
//  }

  // MARK: Latest block
  func getKNLatestBlock(completion: @escaping (Result<String, AnyError>) -> Void) {
    self.performFetchRequest(service: .getLatestBlock) { [weak self] (result) in
      guard let _ = `self` else { return }
      switch result {
      case .success(let json):
        if isDebug { print("Load recent trades successfully: \(json)") }
        let latestBlock: String = json["data"] as? String ?? ""
        completion(.success(latestBlock))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getKNEnabled(completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.performFetchRequest(service: .getKyberEnabled) { [weak self] (result) in
      guard let _ = `self` else { return }
      switch result {
      case .success(let json):
        if isDebug { print("Load recent trades successfully: \(json)") }
        let isEnabled: Bool = json["data"] as? Bool ?? false
        completion(.success(isEnabled))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  private func performFetchRequest(service: KyberNetworkService, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(service) { [weak self] (result) in
        guard let _ = `self` else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            do {
              _ = try response.filterSuccessfulStatusCodes()
              let json: JSONDictionary = try response.mapJSON() as? JSONDictionary ?? [:]
              completion(.success(json))
            } catch let error {
              completion(.failure(AnyError(error)))
            }
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }
}
