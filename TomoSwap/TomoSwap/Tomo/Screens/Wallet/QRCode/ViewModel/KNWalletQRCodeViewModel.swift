// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNWalletQRCodeViewModel {
  let wallet: KNWalletObject

  init(wallet: KNWalletObject) {
    self.wallet = wallet
  }

  var displayedAddress: String {
    return self.address
  }

  var address: String { return self.wallet.address }

  var shareText: String {
    return "\(self.displayedAddress)"
  }

  var copyAddressBtnTitle: String {
    return NSLocalizedString("copy", value: "Copy", comment: "")
  }

  var shareBtnTitle: String {
    return NSLocalizedString("share", value: "Share", comment: "")
  }

  var navigationTitle: String {
    return self.wallet.name
  }
}
