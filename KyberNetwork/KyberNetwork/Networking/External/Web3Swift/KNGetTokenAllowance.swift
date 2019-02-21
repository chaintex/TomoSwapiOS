// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import TrustKeystore
import TrustCore

struct KNGetTokenAllowanceEndcode: Web3Request {
  typealias Response = String

  //swiftlint:disable line_length
  static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"_owner\",\"type\":\"address\"},{\"name\":\"_spender\",\"type\":\"address\"}],\"name\":\"allowance\",\"outputs\":[{\"name\":\"o_remaining\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"}"

  let ownerAddress: Address
  let spenderAddress: Address

  var type: Web3RequestType {
    let run = "web3.eth.abi.encodeFunctionCall(\(KNGetTokenAllowanceEndcode.abi), [\"\(ownerAddress.description)\", \"\(spenderAddress.description)\"])"
    return .script(command: run)
  }
}

struct KNGetTokenAllowanceDecode: Web3Request {
  typealias Response = String

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameter('uint', '\(data)')"
    return .script(command: run)
  }
}
