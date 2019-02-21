// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

public struct KNGasConfiguration {
  static let digixGasLimitDefault = BigInt(770_000)
  static let exchangeTokensGasLimitDefault = BigInt(660_000)
  static let exchangeETHTokenGasLimitDefault = BigInt(330_000)
  static let approveTokenGasLimitDefault = BigInt(100_000)
  static let transferTokenGasLimitDefault = BigInt(60_000)
  static let transferETHGasLimitDefault = BigInt(21_000)
  static let buytokenSaleByETHGasLimitDefault = BigInt(550_000)
  static let buyTokenSaleByTokenGasLimitDefault = BigInt(700_000)
  static let daiGasLimitDefault = BigInt(450_000)
  static let makerGasLimitDefault = BigInt(400_000)
  static let propyGasLimitDefault = BigInt(500_000)
  static let promotionTokenGasLimitDefault = BigInt(380_000)

  static let gasPriceDefault: BigInt = EtherNumberFormatter.full.number(from: "1", units: UnitConfiguration.gasPriceUnit)!
  static let gasPriceMin: BigInt = EtherNumberFormatter.full.number(from: "0.25", units: UnitConfiguration.gasPriceUnit)!
  static let gasPriceMax: BigInt = EtherNumberFormatter.full.number(from: "5", units: UnitConfiguration.gasPriceUnit)!

  static func calculateDefaultGasLimit(from: TokenObject, to: TokenObject) -> BigInt {
    if from == to {
      // normal transfer
      if from.isTOMO { return transferETHGasLimitDefault }
      return calculateDefaultGasLimitTransfer(token: from)
    }
    let gasSrcToETH: BigInt = {
      if from.isTOMO { return BigInt(0) }
      return exchangeETHTokenGasLimitDefault
    }()
    let gasETHToDest: BigInt = {
      if to.isTOMO { return BigInt(0) }
      return exchangeETHTokenGasLimitDefault
    }()
    return gasSrcToETH + gasETHToDest
  }

  static func calculateDefaultGasLimitTransfer(token: TokenObject) -> BigInt {
    if token.isTOMO { return transferETHGasLimitDefault }
    return transferTokenGasLimitDefault
  }
}
