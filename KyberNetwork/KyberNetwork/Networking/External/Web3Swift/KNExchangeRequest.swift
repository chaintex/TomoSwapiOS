// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Foundation
import BigInt
import TrustKeystore
import TrustCore

//swiftlint:disable line_length
struct KNExchangeRequestEncode: Web3Request {
  typealias Response = String

  static let abi = "{\"constant\":false,\"inputs\":[{\"name\":\"src\",\"type\":\"address\"},{\"name\":\"srcAmount\",\"type\":\"uint256\"},{\"name\":\"dest\",\"type\":\"address\"},{\"name\":\"destAddress\",\"type\":\"address\"},{\"name\":\"maxDestAmount\",\"type\":\"uint256\"},{\"name\":\"minConversionRate\",\"type\":\"uint256\"},{\"name\":\"walletId\",\"type\":\"address\"},{\"name\":\"hint\",\"type\":\"bytes\"}],\"name\":\"tradeWithHint\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":true,\"stateMutability\":\"payable\",\"type\":\"function\"}"

  let exchange: KNDraftExchangeTransaction
  let address: Address

  var type: Web3RequestType {
    let minRate: BigInt = {
      guard let minRate = exchange.minRate else { return BigInt(0) }
      return minRate * BigInt(10).power(18 - exchange.to.decimals)
    }()
    let walletID: String = "0x9a68f7330A3Fe9869FfAEe4c3cF3E6BBef1189Da"
    let hint = "PERM".hexEncoded
    let run = "web3.eth.abi.encodeFunctionCall(\(KNExchangeRequestEncode.abi), [\"\(exchange.from.address.description)\", \"\(exchange.amount.description)\", \"\(exchange.to.address.description)\", \"\(address.description)\", \"\(exchange.maxDestAmount.description)\", \"\(minRate.description)\", \"\(walletID)\", \"\(hint)\"])"
    return .script(command: run)
  }
}

struct KNExchangeEventDataDecode: Web3Request {
  typealias Response = [String: String]

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameters([{\"name\": \"src\", \"type\": \"address\"}, {\"name\": \"dest\", \"type\": \"address\"}, {\"name\": \"srcAmount\", \"type\": \"uint256\"}, {\"name\": \"destAmount\", \"type\": \"uint256\"}], \"\(data)\")"
    return .script(command: run)
  }
}
