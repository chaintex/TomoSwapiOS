// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Result
import Moya
import BigInt

/*

 This coordinator controls the fetching exchange token + usd rates,
 running timer interval to frequently fetch data from /getRate and /getRateUSD APIs

*/

class KNRateCoordinator {

  static let shared = KNRateCoordinator()

//  fileprivate let provider = MoyaProvider<KNTrackerService>()

  fileprivate var cacheRates: [KNRate] = []
  fileprivate var cacheRateTimer: Timer?

  fileprivate var exchangeTokenRatesTimer: Timer?
  fileprivate var isLoadingExchangeTokenRates: Bool = false

  func getRate(from: TokenObject, to: TokenObject) -> KNRate? {
    if let rate = self.cacheRates.first(where: { $0.source == from.symbol && $0.dest == to.symbol }) { return rate }
    if from.isTOMO {
      if let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: to) {
        return KNRate(
          source: from.symbol,
          dest: to.symbol,
          rate: trackerRate.rateETHNow == 0.0 ? 0.0 : 1.0 / trackerRate.rateETHNow,
          decimals: to.decimals
        )
      }
    } else if to.isTOMO {
      if let rate = KNTrackerRateStorage.shared.trackerRate(for: from) {
        return KNRate.rateETH(from: rate)
      }
    }
    guard let rateFrom = KNTrackerRateStorage.shared.trackerRate(for: from),
      let rateTo = KNTrackerRateStorage.shared.trackerRate(for: to) else { return nil }
    if rateTo.rateUSDNow == 0.0 { return nil }
    return KNRate(
      source: from.symbol,
      dest: to.symbol,
      rate: rateFrom.rateUSDNow / rateTo.rateUSDNow,
      decimals: to.decimals
    )
  }

  func getCacheRate(from: String, to: String) -> KNRate? {
    if let rate = self.cacheRates.first(where: { $0.source == from && $0.dest == to }) { return rate }
    return nil
  }

  func usdRate(for token: TokenObject) -> KNRate? {
    if let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: token) {
      return KNRate.rateUSD(from: trackerRate)
    }
    return nil
  }

  func ethRate(for token: TokenObject) -> KNRate? {
    if let rate = self.getCacheRate(from: token.symbol, to: "TOMO") { return rate }
    if let rate = KNTrackerRateStorage.shared.trackerRate(for: token) {
      return KNRate(source: "", dest: "", rate: rate.rateETHNow, decimals: 18)
    }
    return nil
  }

  init() {}

  func resume() {
//    self.fetchCacheRate(nil)
//    self.cacheRateTimer?.invalidate()
//    self.cacheRateTimer = Timer.scheduledTimer(
//      withTimeInterval: KNLoadingInterval.cacheRateLoadingInterval,
//      repeats: true,
//      block: { [weak self] timer in
//        self?.fetchCacheRate(timer)
//      }
//    )
//    // Immediate fetch data from server, then run timers with interview 60 seconds
    self.fetchExchangeTokenRate(nil)
    self.exchangeTokenRatesTimer?.invalidate()

    self.exchangeTokenRatesTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.cacheRateLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
      self?.fetchExchangeTokenRate(timer)
      }
    )
  }

  func pause() {
//    self.cacheRateTimer?.invalidate()
//    self.cacheRateTimer = nil
    self.exchangeTokenRatesTimer?.invalidate()
    self.exchangeTokenRatesTimer = nil
    self.isLoadingExchangeTokenRates = false
  }

  @objc func fetchExchangeTokenRate(_ sender: Any?) {
    if isLoadingExchangeTokenRates { return }
    isLoadingExchangeTokenRates = true
    let tokens = KNSupportedTokenStorage.shared.supportedTokens
    let tomo = tokens.first(where: { $0.isTOMO })!
    var rates: [KNTrackerRate] = []
    let group = DispatchGroup()
    for token in tokens {
      if token.isTOMO {
        let json: JSONDictionary = [
          "timestamp": Date().timeIntervalSince1970,
          "token_name": token.name,
          "token_symbol": token.symbol,
          "token_decimal": token.decimals,
          "token_address": token.address.description,
          "rate_eth_now": 1.0,
          "change_eth_24h": 0.0,
        ]
        let trackerRate = KNTrackerRate(dict: json)
        rates.append(trackerRate)
      } else {
        group.enter()
        KNGeneralProvider.shared.getExpectedRate(
          from: token,
          to: tomo,
          amount: BigInt(0)) { result in
          if case .success(let data) = result {
            let expectedRate = data.0
            let rate = Double(expectedRate) / pow(10.0, 18)
            let json: JSONDictionary = [
              "timestamp": Date().timeIntervalSince1970,
              "token_name": token.name,
              "token_symbol": token.symbol,
              "token_decimal": token.decimals,
              "token_address": token.address.description,
              "rate_eth_now": rate,
              "change_eth_24h": 0.0,
              ]
            let trackerRate = KNTrackerRate(dict: json)
            rates.append(trackerRate)
          }
          group.leave()
        }
      }
    }
    group.notify(queue: .main) {
      KNTrackerRateStorage.shared.update(rates: rates)
      self.isLoadingExchangeTokenRates = false
      KNNotificationUtil.postNotification(for: kExchangeTokenRateNotificationKey, object: nil, userInfo: nil)
    }
  }

  @objc func fetchCacheRate(_ sender: Any?) {
//    KNInternalProvider.shared.getKNExchangeTokenRate { [weak self] result in
//      guard let `self` = self else { return }
//      if case .success(let rates) = result {
//        self.cacheRates = rates
//      }
//    }
  }
}

class KNRateHelper {
  static func displayRate(from rate: BigInt, decimals: Int) -> String {
    /*
     Displaying rate with at most 4 digits after leading zeros
     */
    if rate.isZero {
      return rate.string(decimals: decimals, minFractionDigits: min(decimals, 4), maxFractionDigits: min(decimals, 4))
    }
    var string = rate.string(decimals: decimals, minFractionDigits: decimals, maxFractionDigits: decimals)
    let separator = EtherNumberFormatter.full.decimalSeparator
    if let _ = string.firstIndex(of: separator[separator.startIndex]) { string = string + "0000" }
    var start = false
    var cnt = 0
    var index = string.startIndex
    for id in 0..<string.count {
      if string[index] == separator[separator.startIndex] {
        start = true
      } else if start {
        if cnt > 0 || string[index] != "0" { cnt += 1 }
        if cnt == 4 { return string.substring(to: id + 1) }
      }
      index = string.index(after: index)
    }
    if cnt == 0, let id = string.firstIndex(of: separator[separator.startIndex]) {
      index = string.index(id, offsetBy: 5)
      return String(string[..<index])
    }
    return string
  }

  static func displayRate(from rate: String) -> String {
    var string = rate
    let separator = EtherNumberFormatter.full.decimalSeparator
    if let _ = string.firstIndex(of: separator[separator.startIndex]) { string = string + "0000" }
    var start = false
    var cnt = 0
    var index = string.startIndex
    for id in 0..<string.count {
      if string[index] == separator[separator.startIndex] {
        start = true
      } else if start {
        if cnt > 0 || string[index] != "0" { cnt += 1 }
        if cnt == 4 { return string.substring(to: id + 1) }
      }
      index = string.index(after: index)
    }
    if cnt == 0, let id = string.firstIndex(of: separator[separator.startIndex]) {
      index = string.index(id, offsetBy: 5)
      return String(string[..<index])
    }
    return string
  }
}
