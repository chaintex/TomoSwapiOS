// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Crashlytics

protocol KNBackUpWalletViewControllerDelegate: class {
  func backupWalletViewControllerDidFinish()
  func backupWalletViewControllerDidConfirmSkipWallet()
}

class KNBackUpWalletViewController: KNBaseViewController {

  weak var delegate: KNBackUpWalletViewControllerDelegate?
  fileprivate var viewModel: KNBackUpWalletViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var backupWalletLabel: UILabel!
  @IBOutlet weak var titlelabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var writeDownWordsTextLabel: UILabel!

  @IBOutlet var wordLabels: [UILabel]!

  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var firstWordTextField: UITextField!
  @IBOutlet weak var firstSeparatorView: UIView!
  @IBOutlet weak var secondWordTextField: UITextField!
  @IBOutlet weak var secondSeparatorView: UIView!
  @IBOutlet weak var completeButton: UIButton!

  @IBOutlet weak var skipWalletButton: UIButton!

  var isCompleteButtonEnabled: Bool {
    return self.firstWordTextField.text?.isEmpty == false && self.secondWordTextField.text?.isEmpty == false
  }

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  init(viewModel: KNBackUpWalletViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNBackUpWalletViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.skipWalletButton.setTitle(NSLocalizedString("skip", value: "Skip", comment: ""), for: .normal)
    let style = KNAppStyleType.current
    self.view.backgroundColor = style.mainBackgroundColor
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)

    self.nextButton.rounded(radius: style.buttonRadius(for: self.nextButton.frame.height))
    self.nextButton.setTitle(
      NSLocalizedString("next", value: "Next", comment: ""),
      for: .normal
    )
    self.completeButton.rounded(radius: style.buttonRadius(for: self.completeButton.frame.height))
    self.completeButton.setTitle(
      NSLocalizedString("complete", value: "Complete", comment: ""),
      for: .normal
    )
    self.backupWalletLabel.text = self.viewModel.headerText
    self.backupWalletLabel.addLetterSpacing()

    self.firstWordTextField.placeholder = self.viewModel.firstWordTextFieldPlaceholder
    self.firstWordTextField.isHidden = self.viewModel.isTestWordsTextFieldHidden
    self.firstWordTextField.delegate = self
    self.firstWordTextField.addPlaceholderSpacing()
    self.firstSeparatorView.isHidden = self.viewModel.isTestWordsTextFieldHidden

    self.secondWordTextField.placeholder = self.viewModel.secondWordTextFieldPlaceholder
    self.secondWordTextField.isHidden = self.viewModel.isTestWordsTextFieldHidden
    self.secondWordTextField.delegate = self
    self.secondWordTextField.addPlaceholderSpacing()
    self.secondSeparatorView.isHidden = self.viewModel.isTestWordsTextFieldHidden

    self.completeButton.isHidden = self.viewModel.isCompleteButtonHidden
    self.completeButton.setBackgroundColor(
      style.createWalletButtonDisabledColor,
      forState: .disabled
    )
    self.completeButton.isEnabled = self.isCompleteButtonEnabled
    if self.isCompleteButtonEnabled {
      self.completeButton.applyGradient()
    }
    self.nextButton.applyGradient()

    self.updateUI()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.nextButton.applyGradient()
  }

  fileprivate func updateUI() {
    UIView.animate(
      withDuration: 0.25,
      delay: 0,
      options: UIViewAnimationOptions.curveEaseInOut,
      animations: {
        self.backButton.isHidden = self.viewModel.isBackButtonHidden
        self.backupWalletLabel.text = self.viewModel.headerText
        self.backupWalletLabel.addLetterSpacing()
        self.titlelabel.text = self.viewModel.titleText
        self.titlelabel.addLetterSpacing()
        self.descriptionLabel.attributedText = self.viewModel.descriptionAttributedText
        self.writeDownWordsTextLabel.text = self.viewModel.writeDownWordsText
        self.writeDownWordsTextLabel.addLetterSpacing()
        self.writeDownWordsTextLabel.isHidden = self.viewModel.isWriteDownWordsLabelHidden
        self.nextButton.isHidden = self.viewModel.isNextButtonHidden

        for id in 0..<self.viewModel.numberWords {
          let label = self.wordLabels.first(where: { $0.tag == id })
          label?.attributedText = self.viewModel.attributedString(for: id)
          label?.isHidden = self.viewModel.isListWordsLabelsHidden
        }

        self.firstWordTextField.placeholder = self.viewModel.firstWordTextFieldPlaceholder
        self.firstWordTextField.isHidden = self.viewModel.isTestWordsTextFieldHidden
        self.firstSeparatorView.isHidden = self.viewModel.isTestWordsTextFieldHidden

        self.secondWordTextField.placeholder = self.viewModel.secondWordTextFieldPlaceholder
        self.secondSeparatorView.isHidden = self.viewModel.isTestWordsTextFieldHidden
        self.secondWordTextField.isHidden = self.viewModel.isTestWordsTextFieldHidden

        if self.firstWordTextField.isHidden {
          self.view.endEditing(true)
        }

        self.completeButton.isHidden = self.viewModel.isCompleteButtonHidden
        self.completeButton.isEnabled = self.isCompleteButtonEnabled
        if self.isCompleteButtonEnabled {
          self.completeButton.applyGradient()
        }
        self.view.layoutIfNeeded()
      }, completion: nil
    )
  }

  @IBAction func bacButtonPressed(_ sender: Any) {
    self.viewModel.updateModelBackPressed()
    self.updateUI()
  }

  @IBAction func nextButtonPressed(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "back_up_wallet", customAttributes: ["type": "next_button"])
    self.viewModel.updateNextBackUpWords()
    self.updateUI()
  }

  @IBAction func completeButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "back_up_wallet", customAttributes: ["type": "complete_button"])
    guard let firstWord = self.firstWordTextField.text, let secondWord = self.secondWordTextField.text else {
      return
    }
    self.view.endEditing(true)
    var isFirstTime: Bool = false
    var isSuccess: Bool = false
    if self.viewModel.isTestPassed(firstWord: firstWord, secondWord: secondWord) {
      isFirstTime = false
      isSuccess = true
    } else {
      self.firstWordTextField.text = ""
      self.secondWordTextField.text = ""
      self.completeButton.isEnabled = self.isCompleteButtonEnabled
      if self.isCompleteButtonEnabled {
        self.completeButton.applyGradient()
      }
      self.viewModel.numberWrongs += 1
      isFirstTime = self.viewModel.numberWrongs == 1
      isSuccess = false
    }
    let popupVC: KNTestBackUpStatusViewController = {
      let viewModel = KNTestBackUpStatusViewModel(
        isFirstTime: isFirstTime,
        isSuccess: isSuccess
      )
      let controller = KNTestBackUpStatusViewController(viewModel: viewModel)
      controller.delegate = self
      controller.modalPresentationStyle = .overCurrentContext
      controller.modalTransitionStyle = .crossDissolve
      return controller
    }()
    self.present(popupVC, animated: true, completion: nil)
  }

  @IBAction func skipButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "back_up_wallet", customAttributes: ["type": "skip_button"])
    let alert = UIAlertController(
      title: "\(NSLocalizedString("skip", value: "Skip", comment: ""))?",
      message: NSLocalizedString("you.can.backup.your.wallet.later", value: "You can backup your wallet later", comment: ""),
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cacnel", comment: ""), style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: NSLocalizedString("continue", value: "Continue", comment: ""), style: .default, handler: { _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "back_up_wallet", customAttributes: ["type": "skip_button_continue"])
      self.delegate?.backupWalletViewControllerDidConfirmSkipWallet()
    }))
    self.present(alert, animated: true, completion: nil)
  }
}

extension KNBackUpWalletViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    self.completeButton.isEnabled = self.isCompleteButtonEnabled
    if self.isCompleteButtonEnabled {
      self.completeButton.applyGradient()
    }
    self.view.layoutIfNeeded()
    return false
  }

  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.completeButton.isEnabled = self.isCompleteButtonEnabled
    if self.isCompleteButtonEnabled {
      self.completeButton.applyGradient()
    }
    self.view.layoutIfNeeded()
    return false
  }
}

extension KNBackUpWalletViewController: KNTestBackUpStatusViewControllerDelegate {
  func testBackUpStatusViewDidComplete(sender: KNTestBackUpStatusViewController) {
    self.delegate?.backupWalletViewControllerDidFinish()
  }

  func testBackUpStatusViewDidPressSecondButton(sender: KNTestBackUpStatusViewController) {
    // back up again button pressed
    self.viewModel.backupAgain()
    self.updateUI()
  }
}
