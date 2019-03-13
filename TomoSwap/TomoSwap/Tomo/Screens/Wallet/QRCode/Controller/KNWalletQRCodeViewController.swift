// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MBProgressHUD

class KNWalletQRCodeViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var qrcodeImageView: UIImageView!
  @IBOutlet weak var addressLabel: UILabel!

  @IBOutlet weak var copyWalletButton: UIButton!
  @IBOutlet weak var shareButton: UIButton!
  @IBOutlet weak var bottomPaddingConstraintForButton: NSLayoutConstraint!

  fileprivate var viewModel: KNWalletQRCodeViewModel

  fileprivate let style = KNAppStyleType.current

  init(viewModel: KNWalletQRCodeViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNWalletQRCodeViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.bottomPaddingConstraintForButton.constant = 32.0 + self.bottomPaddingSafeArea()
    self.setupWalletData()
    self.setupButtons()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.copyWalletButton.removeSublayer(at: 0)
    self.copyWalletButton.applyGradient()
  }

  fileprivate func setupWalletData() {
    self.titleLabel.text = self.viewModel.wallet.name
    self.addressLabel.text = self.viewModel.displayedAddress
    let text = self.viewModel.address
    DispatchQueue.global(qos: .background).async {
      let image = UIImage.generateQRCode(from: text)
      DispatchQueue.main.async {
        self.qrcodeImageView.image = image
      }
    }
  }

  fileprivate func setupButtons() {
    self.copyWalletButton.rounded(radius: self.style.buttonRadius(for: self.copyWalletButton.frame.height))
    self.copyWalletButton.backgroundColor = style.walletFlowHeaderColor
    self.shareButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: self.style.buttonRadius(for: self.shareButton.frame.height)
    )
    self.copyWalletButton.setTitle(
      NSLocalizedString("copy", value: "Copy", comment: ""),
      for: .normal
    )
    self.shareButton.setTitle(
      NSLocalizedString("share", value: "Share", comment: ""),
      for: .normal
    )
    self.copyWalletButton.applyGradient()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func copyWalletButtonPressed(_ sender: Any) {
    UIPasteboard.general.string = self.viewModel.address

    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = NSLocalizedString("address.copied", value: "Address copied", comment: "")
    hud.hide(animated: true, afterDelay: 1.5)
  }

  @IBAction func shareButtonPressed(_ sender: UIButton) {
    let activityItems: [Any] = {
      var items: [Any] = []
      items.append(self.viewModel.shareText)
      if let image = self.qrcodeImageView.image { items.append(image) }
      return items
    }()
    let activityViewController = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: nil
    )
    activityViewController.popoverPresentationController?.sourceView = sender
    self.present(activityViewController, animated: true, completion: nil)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.navigationController?.popViewController(animated: true)
    }
  }
}
