// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNEnvironment: Int {

  case testnet = 0
  case mainnet = 1

  var displayName: String {
    switch self {
    case .mainnet: return "Tomo Mainnet"
    case .testnet: return "Tomo Testnet"
    }
  }

  static func allEnvironments() -> [KNEnvironment] {
    return [
      KNEnvironment.testnet,
      KNEnvironment.mainnet,
    ]
  }

  static let internalBaseEndpoint: String = {
    return KNAppTracker.internalCachedEnpoint()
  }()

  static let internalTrackerEndpoint: String = {
    return KNAppTracker.internalTrackerEndpoint()
  }()

  static var `default`: KNEnvironment {
    return .testnet
  }

  var isMainnet: Bool {
    return KNEnvironment.default == .mainnet
  }

  var chainID: Int {
    return self.customRPC?.chainID ?? 0
  }

  var etherScanIOURLString: String {
    return self.knCustomRPC?.etherScanEndpoint ?? ""
  }

  var customRPC: CustomRPC? {
    return self.knCustomRPC?.customRPC
  }

  var knCustomRPC: KNCustomRPC? {
    guard let json = KNJSONLoaderUtil.jsonDataFromFile(with: self.configFileName) else {
      return nil
    }
    return KNCustomRPC(dictionary: json)
  }

  var configFileName: String {
    switch self {
    case .testnet: return "config_env_tomo_testnet"
    case .mainnet: return "config_env_tomo_mainnet"
    }
  }

  var apiEtherScanEndpoint: String {
    switch self {
    case .testnet: return "http://api.etherscan.io/"
    case .mainnet: return "http://api.etherscan.io/"
    }
  }

  var supportedTokenEndpoint: String { return "" }
}
