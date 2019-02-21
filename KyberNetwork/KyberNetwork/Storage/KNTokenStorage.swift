// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt

class KNTokenStorage {

  private(set) var realm: Realm

  init(realm: Realm) {
    self.realm = realm
    self.addKyberSupportedTokens()
  }

  func addKyberSupportedTokens() {
    // update balance
    let supportedTokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens
    let tokenObjects = supportedTokens.map({ return $0.clone() })
    tokenObjects.forEach { tokenObject in
      if let token = self.tokens.first(where: { $0.contract == tokenObject.contract }) {
        tokenObject.value = token.value
      }
    }
    self.add(tokens: tokenObjects)
    // new list of supported has been updated, update list of tokens in the wallet
    for token in self.tokens {
      if token.isSupported, supportedTokens.first(where: { $0.contract == token.contract }) == nil {
        try! self.realm.write {
          token.isSupported = false
        }
      }
    }
  }

  var tokens: [TokenObject] {
    return self.realm.objects(TokenObject.self)
      .sorted(byKeyPath: "contract", ascending: true)
      .filter { !$0.contract.isEmpty }
  }

  var ethToken: TokenObject {
   return self.tokens.first(where: { $0.isETH }) ?? KNSupportedTokenStorage.shared.ethToken
  }

  var kncToken: TokenObject {
    return self.tokens.first(where: { $0.isKNC }) ?? KNSupportedTokenStorage.shared.kncToken
  }

  func get(forPrimaryKey key: String) -> TokenObject? {
    return self.realm.object(ofType: TokenObject.self, forPrimaryKey: key)
  }

  func addCustom(token: ERC20Token) {
    // Don't add custom token if it is existed
    if self.tokens.first(where: { $0.contract == token.contract.description.lowercased() }) != nil { return }
    let newToken = TokenObject(
      contract: token.contract.description.lowercased(),
      name: token.name,
      symbol: token.symbol.uppercased(),
      decimals: token.decimals,
      value: "0",
      isCustom: true
    )
    add(tokens: [newToken])
  }

  func add(tokens: [TokenObject]) {
    self.realm.beginWrite()
    self.realm.add(tokens, update: true)
    try! self.realm.commitWrite()
  }

  func updateBalance(for token: TokenObject, balance: BigInt) {
    try! self.realm.write {
      token.value = balance.description
    }
  }

  func updateBalance(for address: Address, balance: BigInt) {
    if let token = self.tokens.first(where: { $0.contract == address.description.lowercased() }) {
      try! self.realm.write {
        token.value = balance.description
      }
    }
  }

  func delete(tokens: [TokenObject]) {
    realm.beginWrite()
    realm.delete(tokens)
    try! realm.commitWrite()
  }

  func deleteAll() {
    try! realm.write {
      realm.delete(realm.objects(TokenObject.self))
    }
  }
}
