// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNCreatePasswordViewControllerDelegate: class {
  func createPasswordUserDidFinish(_ password: String)
  func createPasswordDidCancel(sender: KNCreatePasswordViewController)
}

class KNCreatePasswordViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var confirmPasswordTextField: UITextField!

  @IBOutlet weak var errorPasswordLabel: UILabel!
  @IBOutlet weak var errorConfirmPasswordLabel: UILabel!
  @IBOutlet weak var doneButton: UIButton!

  fileprivate weak var delegate: KNCreatePasswordViewControllerDelegate?

  init(delegate: KNCreatePasswordViewControllerDelegate) {
    self.delegate = delegate
    super.init(nibName: "KNCreatePasswordViewController", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.passwordTextField.becomeFirstResponder()
  }

  fileprivate func setupUI() {
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    self.containerView.rounded(radius: 5.0)

    self.passwordTextField.text = ""
    self.confirmPasswordTextField.text = ""
    self.passwordTextField.delegate = self
    self.confirmPasswordTextField.delegate = self

    self.errorPasswordLabel.text = NSLocalizedString("field.required", value: "Field required", comment: "")
    self.errorPasswordLabel.isHidden = true
    self.errorConfirmPasswordLabel.text = NSLocalizedString("passwords.mismatch", value: "Passwords mismatch", comment: "")
    self.errorConfirmPasswordLabel.isHidden = true

    self.doneButton.rounded(color: .clear, width: 0, radius: KNAppStyleType.current.buttonRadius(for: self.doneButton.frame.height))

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  @objc func tapOutSideToDismiss(_ sender: UITapGestureRecognizer) {
    let touchedPoint = sender.location(in: self.view)
    if touchedPoint.x < self.containerView.frame.minX
      || touchedPoint.x > self.containerView.frame.maxX
      || touchedPoint.y < self.containerView.frame.minY
      || touchedPoint.y > self.containerView.frame.maxY {
      self.delegate?.createPasswordDidCancel(sender: self)
    }
  }

  @IBAction func doneButtonPressed(_ sender: Any) {
    guard let password = self.passwordTextField.text, let confirmPassword = self.confirmPasswordTextField.text, password == confirmPassword,
        !password.isEmpty else {
      self.errorPasswordLabel.isHidden = false
      self.errorConfirmPasswordLabel.isHidden = false
      return
    }
    self.dismiss(animated: true) {
      self.delegate?.createPasswordUserDidFinish(password)
    }
  }
}

extension KNCreatePasswordViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.view.endEditing(true)
    return true
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    self.errorConfirmPasswordLabel.isHidden = true
    self.errorPasswordLabel.isHidden = true
    return true
  }
}
