// Copyright SIX DAY LLC. All rights reserved.

import UIKit

// MARK: Landing Page Coordinator Delegate
extension KNAppCoordinator: KNLandingPageCoordinatorDelegate {
  func landingPageCoordinator(import wallet: Wallet) {
    if self.tabbarController == nil {
      self.startNewSession(with: wallet)
    } else {
      self.restartNewSession(wallet)
    }
  }

  func landingPageCoordinator(remove wallet: Wallet) {
    self.removeWallet(wallet)
  }
}

// MARK: Session Delegate
extension KNAppCoordinator: KNSessionDelegate {
  func userDidClickExitSession() {
    let alertController = UIAlertController(
      title: NSLocalizedString("exit", value: "Exit", comment: ""),
      message: NSLocalizedString("do.you.want.to.exit.and.remove.all.wallets", value: "Do you want to exit and remove all wallets from the app?", comment: ""),
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
      self.stopAllSessions()
    }))
    self.navigationController.present(alertController, animated: true, completion: nil)
  }
}

// MARK: Exchange Token Coordinator Delegate
extension KNAppCoordinator: KNExchangeTokenCoordinatorDelegate {
  func exchangeTokenCoordinatorDidSelectWallet(_ wallet: KNWalletObject) {
    guard let wallet = self.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else { return }
    if let recentWallet = self.keystore.recentlyUsedWallet, recentWallet == wallet { return }
    self.restartNewSession(wallet)
  }

  func exchangeTokenCoordinatorRemoveWallet(_ wallet: Wallet) {
    self.removeWallet(wallet)
  }

  func exchangeTokenCoordinatorDidSelectAddWallet() {
    self.addNewWallet()
  }

  func exchangeTokenCoordinatorDidSelectPromoCode() {
    self.addPromoCode()
  }
}

// MARK: Settings Coordinator Delegate
extension KNAppCoordinator: KNSettingsCoordinatorDelegate {
  func settingsCoordinatorUserDidUpdateWalletObjects() {
    self.balanceTabCoordinator?.appCoordinatorDidUpdateWalletObjects()
    self.exchangeCoordinator?.appCoordinatorDidUpdateWalletObjects()
    self.profileCoordinator?.appCoordinatorDidUpdateWalletObjects()
  }

  func settingsCoordinatorUserDidSelectExit() {
    self.userDidClickExitSession()
  }

  func settingsCoordinatorUserDidSelectNewWallet(_ wallet: Wallet) {
    self.restartNewSession(wallet)
  }

  func settingsCoordinatorUserDidRemoveWallet(_ wallet: Wallet) {
    self.removeWallet(wallet)
  }

  func settingsCoordinatorUserDidSelectAddWallet() {
    self.addNewWallet()
  }
}

// MARK: Balance Tab Coordinator Delegate
extension KNAppCoordinator: KNBalanceTabCoordinatorDelegate {
  func balanceTabCoordinatorShouldOpenExchange(for tokenObject: TokenObject, isReceived: Bool) {
    self.exchangeCoordinator?.appCoordinatorShouldOpenExchangeForToken(tokenObject, isReceived: isReceived)
    self.tabbarController.selectedIndex = 1
    self.tabbarController.tabBar.tintColor = UIColor.Kyber.enygold
  }

  func balanceTabCoordinatorDidSelect(walletObject: KNWalletObject) {
    guard let wallet = self.keystore.wallets.first(where: { $0.address.description.lowercased() == walletObject.address.lowercased() }) else { return }
    self.restartNewSession(wallet)
  }

  func balanceTabCoordinatorDidSelectAddWallet() {
    self.addNewWallet()
  }

  func balanceTabCoordinatorDidSelectPromoCode() {
    self.addPromoCode()
  }
}

// MARK: Transaction Status Delegate
extension KNAppCoordinator: KNTransactionStatusCoordinatorDelegate {
  func transactionStatusCoordinatorDidClose() {
    self.transactionStatusCoordinator = nil
    let trans = self.session.transactionStorage.kyberTransactions.filter({ $0.state != .pending })
    if !trans.isEmpty { self.session.transactionStorage.delete(trans) }
  }
}

// MARK: Add wallet coordinator delegate
extension KNAppCoordinator: KNAddNewWalletCoordinatorDelegate {
  func addNewWalletCoordinator(add wallet: Wallet) {
    if self.tabbarController == nil {
      self.startNewSession(with: wallet)
    } else {
      self.restartNewSession(wallet)
    }
  }

  func addNewWalletCoordinator(remove wallet: Wallet) {
    self.removeWallet(wallet)
  }
}

extension KNAppCoordinator: KNPromoCodeCoordinatorDelegate {
  func promoCodeCoordinatorDidCreate(_ wallet: Wallet, expiredDate: TimeInterval, destinationToken: String?, name: String?) {
    self.navigationController.popViewController(animated: true) {
      let address = wallet.address.description
      KNWalletPromoInfoStorage.shared.addWalletPromoInfo(
        address: address,
        destinationToken: destinationToken ?? ""
      )
      self.addNewWalletCoordinator(add: wallet)
    }
  }
}

// MARK: Passcode coordinator delegate
extension KNAppCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCancel() {
    self.authenticationCoordinator.stop {}
  }
  func passcodeCoordinatorDidEvaluatePIN() {
    self.authenticationCoordinator.stop {}
  }
  func passcodeCoordinatorDidCreatePasscode() {
    self.authenticationCoordinator.stop {}
  }
}
