// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNSettingsTabViewEvent {
  case manageWallet
  case contact
  case support
  case changePIN
  case about
  case community
  case shareWithFriends
  case telegram
  case telegramDev
  case github
  case twitter
  case facebook
  case medium
  case reddit
  case linkedIn
  case reportBugs
  case rateOurApp
}

protocol KNSettingsTabViewControllerDelegate: class {
  func settingsTabViewController(_ controller: KNSettingsTabViewController, run event: KNSettingsTabViewEvent)
}

class KNSettingsTabViewController: KNBaseViewController {

  weak var delegate: KNSettingsTabViewControllerDelegate?

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var manageWalletButton: UIButton!
  @IBOutlet weak var contactButton: UIButton!
  @IBOutlet weak var supportButton: UIButton!
  @IBOutlet weak var changePINButton: UIButton!
  @IBOutlet weak var aboutButton: UIButton!
  @IBOutlet weak var community: UIButton!
  @IBOutlet weak var shareWithFriendsButton: UIButton!
  @IBOutlet weak var reportBugsButton: UIButton!
  @IBOutlet weak var rateOurAppButton: UIButton!
  @IBOutlet weak var versionLabel: UILabel!
  @IBOutlet weak var bottomPaddingVersionLabelConstraint: NSLayoutConstraint!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.navTitleLabel.text = NSLocalizedString("settings", value: "Settings", comment: "")
    self.manageWalletButton.setTitle(
      NSLocalizedString("manage.wallet", value: "Manage Wallet", comment: ""),
      for: .normal
    )
    self.manageWalletButton.addTextSpacing()
    self.contactButton.setTitle(
      NSLocalizedString("contact", value: "Contact", comment: ""),
      for: .normal
    )
    self.contactButton.addTextSpacing()
    self.supportButton.setTitle(
      NSLocalizedString("support", value: "Support", comment: ""),
      for: .normal
    )
    self.supportButton.addTextSpacing()
    self.changePINButton.setTitle(
      NSLocalizedString("change.pin", value: "Change PIN", comment: ""),
      for: .normal
    )
    self.changePINButton.addTextSpacing()
    self.aboutButton.setTitle(
      NSLocalizedString("about", value: "About", comment: ""),
      for: .normal
    )
    self.aboutButton.addTextSpacing()
    self.community.setTitle(
      NSLocalizedString("community", value: "Community", comment: ""),
      for: .normal
    )
    self.community.addTextSpacing()
    self.shareWithFriendsButton.setTitle(
      NSLocalizedString("share.with.friends", value: "Share with friends", comment: ""),
      for: .normal
    )
    self.reportBugsButton.setTitle(
      NSLocalizedString("report.bugs", value: "Report Bugs", comment: ""),
      for: .normal
    )
    self.rateOurAppButton.setTitle(
      NSLocalizedString("rate.our.app", value: "Rate our App", comment: ""),
      for: .normal
    )
    self.shareWithFriendsButton.addTextSpacing()
    var version = Bundle.main.versionNumber ?? ""
    version += " - \(Bundle.main.buildNumber ?? "")"
    version += " - \(KNEnvironment.default.displayName)"
    self.versionLabel.text = "\(NSLocalizedString("version", value: "Version", comment: "")) \(version)"
    self.bottomPaddingVersionLabelConstraint.constant = 24.0 + self.bottomPaddingSafeArea()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  @IBAction func manageWalletButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .manageWallet)
  }

  @IBAction func contactButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .contact)
  }

  @IBAction func supportButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .support)
  }

  @IBAction func changePasscodeButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .changePIN)
  }

  @IBAction func aboutButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .about)
  }

  @IBAction func communityButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .community)
  }

  @IBAction func shareWithFriendButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .shareWithFriends)
  }

  @IBAction func telegramButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .telegram)
  }

  @IBAction func telegramDevButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .telegramDev)
  }

  @IBAction func githubButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .github)
  }

  @IBAction func twitterButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .twitter)
  }

  @IBAction func facebookButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .facebook)
  }

  @IBAction func mediumButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .medium)
  }

  @IBAction func redditButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .reddit)
  }

  @IBAction func linkedInButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .linkedIn)
  }

  @IBAction func reportBugsButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .reportBugs)
  }

  @IBAction func rateOurAppButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .rateOurApp)
  }
}
