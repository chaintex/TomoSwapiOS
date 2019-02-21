// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

enum IEOKYCStep: Int {
  case personalInfo = 1
  case identity = 2
  case submit = 3
}

class IEOUser: Object {

  @objc dynamic var userID: Int = -1
  @objc dynamic var name: String = ""
  @objc dynamic var contactType: String = ""
  @objc dynamic var contactID: String = ""
  @objc dynamic var kycStatus: String = ""
  @objc dynamic var tokenType: String = ""
  @objc dynamic var expireTime: Double = 0
  @objc dynamic var accessToken: String = ""
  @objc dynamic var refreshToken: String = ""
  @objc dynamic var isSignedIn: Bool = true
  @objc dynamic var avatarURL: String = ""
  var registeredAddress: List<String> = List<String>()

  convenience init(dict: JSONDictionary) {
    self.init()
    self.userID = dict["uid"] as? Int ?? -1
    self.name = dict["name"] as? String ?? ""
    self.contactType = dict["contact_type"] as? String ?? ""
    self.contactID = dict["contact_id"] as? String ?? ""
    self.kycStatus = dict["kyc_status"] as? String ?? ""
    self.registeredAddress = List<String>()
    self.avatarURL = dict["avatar_url"] as? String ?? ""
    if let arr = dict["active_wallets"] as? [String] {
      arr.forEach { self.registeredAddress.append($0.lowercased()) }
    }
    let step = dict["kyc_step"] as? Int ?? 1
    self.updateKYCStep(step)
    let rejectReason: String = {
      let reject: String = dict["reject_reason"] as? String ?? ""
      let block: String = dict["block_reason"] as? String ?? ""
      return !reject.isEmpty ? reject : block
    }()
    let kycInfoDict = dict["kyc_info"] as? JSONDictionary ?? [:]
    let kycObject = UserKYCDetailsInfo(userID: self.userID, dict: kycInfoDict, rejectReason: rejectReason)
    IEOUserStorage.shared.updateKYCDetails(object: kycObject)
  }

  func updateToken(type: String, accessToken: String, refreshToken: String, expireTime: Double) {
    self.tokenType = type
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.expireTime = expireTime
  }

  fileprivate func updateKYCStep(_ step: Int) {
    let userDefaults = UserDefaults.standard
    userDefaults.set(step, forKey: "kUserKYCStepKey_\(self.userID)")
    userDefaults.synchronize()
  }

  func removeKYCStep() {
    let userDefaults = UserDefaults.standard
    userDefaults.removeObject(forKey: "kUserKYCStepKey_\(self.userID)")
    userDefaults.synchronize()
  }

  var kycStep: Int {
    return UserDefaults.standard.object(forKey: "kUserKYCStepKey_\(self.userID)") as? Int ?? 1
  }

  var kycDetails: UserKYCDetailsInfo? {
    return IEOUserStorage.shared.getKYCDetails(for: self.userID)
  }

  override class func primaryKey() -> String? {
    return "userID"
  }
}

class UserKYCDetailsInfo: Object {
  @objc dynamic var userID: Int = -1
  @objc dynamic var rejectedReason: String = ""
  @objc dynamic var firstName: String = ""
  @objc dynamic var middleName: String = ""
  @objc dynamic var lastName: String = ""
  @objc dynamic var nativeFullName: String = ""
  @objc dynamic var nationality: String = ""
  @objc dynamic var residentialAddress: String = ""
  @objc dynamic var country: String = ""
  @objc dynamic var city: String = ""
  @objc dynamic var zipCode: String = ""
  @objc dynamic var documentProofAddress: String = ""
  @objc dynamic var photoProofAddress: String = ""
  @objc dynamic var sourceFund: String = ""
  @objc dynamic var occupationCode: String = ""
  @objc dynamic var industryCode: String = ""
  @objc dynamic var taxResidencyCountry: String = ""
  @objc dynamic var haveTaxIndentification: Bool = false
  @objc dynamic var taxIDNUmber: String = ""
  @objc dynamic var gender: Bool = true
  @objc dynamic var dob: String = ""
  @objc dynamic var documentType: String = ""
  @objc dynamic var documentNumber: String = ""
  @objc dynamic var documentPhotoFront: String = ""
  @objc dynamic var documentPhotoBack: String = ""
  @objc dynamic var documentIssueDate: String = ""
  @objc dynamic var documentExpiryDate: String = ""
  @objc dynamic var documentSelfiePhoto: String = ""

  convenience init(userID: Int, dict: JSONDictionary, rejectReason: String) {
    self.init()
    self.userID = userID
    self.firstName = dict["first_name"] as? String ?? ""
    self.middleName = dict["middle_name"] as? String ?? ""
    self.lastName = dict["last_name"] as? String ?? ""
    self.nativeFullName = dict["native_full_name"] as? String ?? ""
    self.nationality = dict["nationality"] as? String ?? ""
    self.residentialAddress = dict["residential_address"] as? String ?? ""
    self.country = dict["country"] as? String ?? ""
    self.city = dict["city"] as? String ?? ""
    self.zipCode = dict["zip_code"] as? String ?? ""
    self.documentProofAddress = dict["document_proof_address"] as? String ?? ""
    self.photoProofAddress = dict["photo_proof_address"] as? String ?? ""
    self.sourceFund = dict["source_fund"] as? String ?? ""
    self.occupationCode = dict["occupation_code"] as? String ?? ""
    self.industryCode = dict["industry_code"] as? String ?? ""
    self.taxResidencyCountry = dict["tax_residency_country"] as? String ?? ""
    self.haveTaxIndentification = dict["have_tax_identification"] as? Bool ?? false
    self.taxIDNUmber = dict["tax_identification_number"] as? String ?? ""
    self.gender = dict["gender"] as? Bool ?? true
    self.dob = dict["dob"] as? String ?? ""
    self.documentType = dict["document_type"] as? String ?? ""
    self.documentNumber = dict["document_id"] as? String ?? ""
    self.documentPhotoFront = dict["photo_identity_front_side"] as? String ?? ""
    self.documentPhotoBack = dict["photo_identity_back_side"] as? String ?? ""
    self.documentIssueDate = dict["document_issue_date"] as? String ?? ""
    self.documentExpiryDate = dict["document_expiry_date"] as? String ?? ""
    self.documentSelfiePhoto = dict["photo_selfie"] as? String ?? ""
    self.rejectedReason = rejectReason
  }

  override class func primaryKey() -> String? {
    return "userID"
  }
}
