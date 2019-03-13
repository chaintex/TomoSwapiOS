// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustCore

struct KNContactTableViewCellModel {
  let contact: KNContact
  let index: Int

  init(
    contact: KNContact,
    index: Int
    ) {
    self.contact = contact
    self.index = index
  }

  var addressImage: UIImage? {
    guard let data = Address(string: self.contact.address)?.data else { return nil }
    return UIImage.generateImage(with: 32, hash: data)
  }

  var displayedName: String { return self.contact.name }

  var nameAndAddressAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()

    return attributedString
  }

  var displayedAddress: String {
    return "\(self.contact.address.prefix(20))...\(self.contact.address.suffix(6))"
  }

  var backgroundColor: UIColor {
    return self.index % 2 == 0 ? UIColor.clear : UIColor.white
  }
}

class KNContactTableViewCell: UITableViewCell {

  static let height: CGFloat = 68

  @IBOutlet weak var addressImageView: UIImageView!
  @IBOutlet weak var contactNameLabel: UILabel!
  @IBOutlet weak var contactAddressLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.contactNameLabel.text = ""
    self.contactAddressLabel.text = ""
    self.addressImageView.rounded(radius: self.addressImageView.frame.height / 2.0)
  }

  func update(with viewModel: KNContactTableViewCellModel) {
    self.addressImageView.image = viewModel.addressImage
    self.contactNameLabel.text = viewModel.displayedName
    self.contactNameLabel.addLetterSpacing()
    self.contactAddressLabel.text = viewModel.displayedAddress
    self.contactAddressLabel.addLetterSpacing()
    self.backgroundColor = viewModel.backgroundColor
    self.layoutIfNeeded()
  }
}
