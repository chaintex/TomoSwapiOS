// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import Branch
import Result
import Crashlytics

class KNProfileHomeCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession

  fileprivate(set) var accessTokenExpireTimer: Timer?

  fileprivate(set) var webViewSignInVC: KGOInAppSignInViewController?

  lazy var rootViewController: KNProfileHomeViewController = {
    let viewModel = KNProfileHomeViewModel()
    let controller = KNProfileHomeViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  fileprivate var kycCoordinator: KYCCoordinator?

  fileprivate var loadUserInfoTimer: Timer?
  fileprivate var lastUpdatedUserInfo: Date?

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
  ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.session = session
  }

  deinit { self.stop() }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
//    self.timerAccessTokenExpired()
//    // Add notification observer
//    let callbackName = Notification.Name(kIEODidReceiveCallbackNotificationKey)
//    NotificationCenter.default.addObserver(
//      self,
//      selector: #selector(self.appCoordinatorDidReceiveCallback(_:)),
//      name: callbackName,
//      object: nil
//    )
//    if IEOUserStorage.shared.user != nil {
//      self.timerLoadUserInfo()
//    }
  }

  func stop() {
    // Remove notification observer
//    self.accessTokenExpireTimer?.invalidate()
//    self.accessTokenExpireTimer = nil
//
//    NotificationCenter.default.removeObserver(
//      self,
//      name: NSNotification.Name(kIEODidReceiveCallbackNotificationKey),
//      object: nil
//    )
//
//    self.loadUserInfoTimer?.invalidate()
//    self.loadUserInfoTimer = nil
  }

  fileprivate func timerAccessTokenExpired() {
//    if let user = IEOUserStorage.shared.user {
//      let time = Date(timeIntervalSince1970: user.expireTime).timeIntervalSinceNow
//      guard time > 0 else {
//        self.handleUserAccessTokenExpired()
//        return
//      }
//      self.accessTokenExpireTimer?.invalidate()
//      self.accessTokenExpireTimer = Timer.scheduledTimer(
//        withTimeInterval: time,
//        repeats: false,
//        block: { [weak self] _ in
//          self?.handleUserAccessTokenExpired()
//        }
//      )
//    }
  }

  fileprivate func timerLoadUserInfo() {
//    self.loadUserInfoTimer?.invalidate()
//    guard let user = IEOUserStorage.shared.user else {
//      self.loadUserInfoTimer?.invalidate()
//      return
//    }
//    self.getUserInfo(
//      type: user.tokenType,
//      accessToken: user.accessToken,
//      refreshToken: user.refreshToken,
//      expireTime: user.expireTime,
//      hasUser: true,
//      showError: false
//    ) { success in
//        if success {
//          self.rootViewController.coordinatorUserDidSignInSuccessfully()
//        }
//    }
//
//    self.loadUserInfoTimer?.invalidate()
//    self.loadUserInfoTimer = Timer.scheduledTimer(
//      withTimeInterval: KNEnvironment.default.isMainnet ? 60.0 : 10.0,
//      repeats: true,
//      block: { [weak self] _ in
//        guard let user = IEOUserStorage.shared.user else {
//          self?.loadUserInfoTimer?.invalidate()
//          return
//        }
//        self?.getUserInfo(
//          type: user.tokenType,
//          accessToken: user.accessToken,
//          refreshToken: user.refreshToken,
//          expireTime: user.expireTime,
//          hasUser: true,
//          showError: false
//        ) { success in
//            if success {
//              self?.rootViewController.coordinatorUserDidSignInSuccessfully()
//            }
//        }
//      }
//    )
  }

  // MARK: Update from app coordinator
  func updateSession(_ session: KNSession) {
    self.session = session
    self.navigationController.popToRootViewController(animated: false)
  }

  func appCoordinatorDidUpdateWalletObjects() {
  }
}

// MARK: Callbacks, networking
extension KNProfileHomeCoordinator {
  fileprivate func handleUserSignOut() {
    let alertController = UIAlertController(
      title: nil,
      message: NSLocalizedString("do.you.want.to.log.out?", value: "Do you want to log out?", comment: ""),
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("log.out", value: "Log Out", comment: ""), style: .default, handler: { _ in
      self.loadUserInfoTimer?.invalidate()
      self.lastUpdatedUserInfo = nil
      IEOUserStorage.shared.signedOut()
      Branch.getInstance().logout()
      self.rootViewController.coordinatorDidSignOut()
    }))
    self.rootViewController.present(alertController, animated: true, completion: nil)
  }

  fileprivate func openSignInView() {
//    if let user = IEOUserStorage.shared.user {
//      // User already signed in
//      let text = NSLocalizedString("welcome.back.user", value: "Welcome back, %@", comment: "")
//      let message = String(format: text, user.name)
//      self.navigationController.showSuccessTopBannerMessage(with: "", message: message)
//      return
//    }
//    let clientID: String = KNEnvironment.default.clientID
//    let redirectLink: String = KNEnvironment.default.redirectLink
//    if let url = URL(string: KNAppTracker.getKyberProfileBaseString() + "/oauth/authorize?lang=\(Locale.current.kyberSupportedLang)&isInternalApp=true&client_id=\(clientID)&redirect_uri=\(redirectLink)&response_type=code&state=\(KNSecret.state)") {
//      // Clear old session
//      URLCache.shared.removeAllCachedResponses()
//      URLCache.shared.diskCapacity = 0
//      URLCache.shared.memoryCapacity = 0
//
//      let storage = HTTPCookieStorage.shared
//      storage.cookies?.forEach({ storage.deleteCookie($0) })
//      self.webViewSignInVC = KGOInAppSignInViewController(
//        with: url,
//        isSignIn: true
//      )
//      self.navigationController.pushViewController(self.webViewSignInVC!, animated: true)
//    }
  }

  fileprivate func openSignUpView() {
//    if let url = URL(string: KNAppTracker.getKyberProfileBaseString() + "/users/sign_up?lang=\(Locale.current.kyberSupportedLang)&isInternalApp=true") {
//      // Clear old session
//      URLCache.shared.removeAllCachedResponses()
//      URLCache.shared.diskCapacity = 0
//      URLCache.shared.memoryCapacity = 0
//
//      let storage = HTTPCookieStorage.shared
//      storage.cookies?.forEach({ storage.deleteCookie($0) })
//      self.webViewSignInVC = KGOInAppSignInViewController(
//        with: url,
//        isSignIn: false
//      )
//      self.navigationController.pushViewController(self.webViewSignInVC!, animated: true)
//    }
  }

  @objc func appCoordinatorDidReceiveCallback(_ sender: Notification) {
//    if IEOUserStorage.shared.user != nil { return } // return if user exists
//    guard let params = sender.object as? JSONDictionary else { return }
//    guard let code = params["code"] as? String, let state = params["state"] as? String, state.contains(KNSecret.state) else { return }
//    if self.webViewSignInVC != nil {
//      self.navigationController.popViewController(animated: true) {
//        self.webViewSignInVC = nil
//      }
//    }
//    // got authentication code
//    // use the code to get access token for user
//    KNCrashlyticsUtil.logCustomEvent(withName: "profile_kyc", customAttributes: ["type": "received_call_back"])
//    self.navigationController.displayLoading(text: "\(NSLocalizedString("initializing.session", value: "Initializing Session", comment: ""))...", animated: true)
//    DispatchQueue.global(qos: .background).async {
//      let provider = MoyaProvider<KyberGOService>()
//      let accessToken = KyberGOService.getAccessToken(code: code, isRefresh: false)
//      provider.request(accessToken, completion: { [weak self] result in
//        DispatchQueue.main.async {
//          guard let _ = `self` else { return }
//          switch result {
//          case .success(let data):
//            do {
//              _ = try data.filterSuccessfulStatusCodes()
//              let dataJSON: JSONDictionary = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
//              guard let accessToken = dataJSON["access_token"] as? String,
//                let tokenType = dataJSON["token_type"] as? String,
//                let refreshToken = dataJSON["refresh_token"] as? String,
//                let expireTime = dataJSON["expires_in"] as? Double
//                else {
//                  self?.navigationController.hideLoading()
//                  self?.navigationController.showWarningTopBannerMessage(
//                    with: NSLocalizedString("error", value: "Error", comment: ""),
//                    message: NSLocalizedString("can.not.get.access.token", value: "Can not get access token", comment: "")
//                  )
//                  KNCrashlyticsUtil.logCustomEvent(withName: "profile_kyc", customAttributes: ["type": "can_not_get_access_token"])
//                  return
//              }
//              self?.getUserInfo(
//                type: tokenType,
//                accessToken: accessToken,
//                refreshToken: refreshToken,
//                expireTime:
//                Date().addingTimeInterval(expireTime).timeIntervalSince1970,
//                hasUser: false,
//                showError: true,
//                completion: { success in
//                  if success {
//                    KNCrashlyticsUtil.logCustomEvent(withName: "profile_kyc", customAttributes: ["type": "signed_in_successfully"])
//                    let name = IEOUserStorage.shared.user?.name ?? ""
//                    let text = NSLocalizedString("welcome.back.user", value: "Welcome back, %@", comment: "")
//                    let message = String(format: text, name)
//                    self?.navigationController.showSuccessTopBannerMessage(with: "", message: message)
//                  } else {
//                    KNCrashlyticsUtil.logCustomEvent(withName: "profile_kyc", customAttributes: ["type": "signed_in_failed"])
//                  }
//                }
//              )
//            } catch {
//              KNCrashlyticsUtil.logCustomEvent(withName: "profile_kyc", customAttributes: ["type": "can_not_get_access_token"])
//              self?.navigationController.hideLoading()
//              self?.navigationController.showWarningTopBannerMessage(
//                with: NSLocalizedString("error", value: "Error", comment: ""),
//                message: NSLocalizedString("can.not.get.access.token", value: "Can not get access token", comment: "")
//              )
//            }
//          case .failure(let error):
//            self?.navigationController.hideLoading()
//            self?.navigationController.displayError(error: error)
//          }
//        }
//      })
//    }
  }

  fileprivate func getUserInfo(type: String, accessToken: String, refreshToken: String, expireTime: Double, hasUser: Bool, showError: Bool = false, completion: @escaping (Bool) -> Void) {
    // got access token, user access token  to retrieve user information
//    DispatchQueue.global(qos: .background).async {
//      let provider = MoyaProvider<KyberGOService>()
//      let userInfoRequest = KyberGOService.getUserInfo(accessToken: accessToken)
//      provider.request(userInfoRequest, completion: { [weak self] userInfoResult in
//        DispatchQueue.main.async {
//          guard let _ = `self` else { return }
//          self?.navigationController.hideLoading()
//          if hasUser && IEOUserStorage.shared.user == nil {
//            self?.loadUserInfoTimer?.invalidate()
//            return
//          }
//          switch userInfoResult {
//          case .success(let userInfo):
//            guard let userDataJSON = try? userInfo.mapJSON(failsOnEmptyData: false) as? JSONDictionary, let userJSON = userDataJSON else {
//              if showError {
//                self?.navigationController.showWarningTopBannerMessage(
//                  with: NSLocalizedString("error", value: "Error", comment: ""),
//                  message: NSLocalizedString("can.not.get.user.info", value: "Can not get user info", comment: "")
//                )
//                KNCrashlyticsUtil.logCustomEvent(withName: "profile_kyc", customAttributes: ["type": "get_user_info_failed"])
//              }
//              completion(false)
//              return
//            }
//            let user = IEOUser(dict: userJSON)
//            IEOUserStorage.shared.update(objects: [user])
//            IEOUserStorage.shared.updateToken(
//              object: user,
//              type: type,
//              accessToken: accessToken,
//              refreshToken: refreshToken,
//              expireTime: expireTime
//            )
//            self?.timerAccessTokenExpired()
//            if !hasUser { self?.timerLoadUserInfo() }
//            self?.rootViewController.coordinatorUserDidSignInSuccessfully()
//            self?.lastUpdatedUserInfo = Date()
//            completion(true)
//          // Already have user
//          case .failure(let error):
//            KNCrashlyticsUtil.logCustomEvent(withName: "profile_kyc", customAttributes: ["type": "get_user_info_failed"])
//            if showError {
//              self?.navigationController.displayError(error: error)
//            }
//            completion(false)
//          }
//        }
//      })
//    }
  }

  fileprivate func handleUserAccessTokenExpired() {
//    guard let user = IEOUserStorage.shared.user else { return }
//    let refreshToken = user.refreshToken
//    DispatchQueue.global(qos: .background).async {
//      let provider = MoyaProvider<KyberGOService>()
//      let request = KyberGOService.getAccessToken(code: refreshToken, isRefresh: true)
//      provider.request(request) { [weak self] result in
//        DispatchQueue.main.async {
//          switch result {
//          case .success(let data):
//            do {
//              _ = try data.filterSuccessfulStatusCodes()
//              if let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary,
//                let accessToken = json["access_token"] as? String,
//                let tokenType = json["token_type"] as? String,
//                let refreshToken = json["refresh_token"] as? String,
//                let expireTime = json["expires_in"] as? Double {
//                IEOUserStorage.shared.updateToken(
//                  object: user,
//                  type: tokenType,
//                  accessToken: accessToken,
//                  refreshToken: refreshToken,
//                  expireTime: Date().addingTimeInterval(expireTime).timeIntervalSince1970
//                )
//                self?.timerAccessTokenExpired()
//                KNCrashlyticsUtil.logCustomEvent(withName: "profile_kyc", customAttributes: ["type": "expiry_session_reload_successfully"])
//                return
//              }
//            } catch {}
//          case .failure:
//            break
//          }
//          // Error for some reason
//          KNCrashlyticsUtil.logCustomEvent(withName: "profile_kyc", customAttributes: ["type": "expiry_session_failed_reload"])
//          KNNotificationUtil.localPushNotification(
//            title: NSLocalizedString("session.expired", value: "Session expired", comment: ""),
//            body: NSLocalizedString("your.session.has.expired.sign.in.to.continue", value: "Your session has expired, please sign in again to continue", comment: "")
//          )
//          IEOUserStorage.shared.signedOut()
//          self?.navigationController.popToRootViewController(animated: true)
//          self?.rootViewController.coordinatorDidSignOut()
//        }
//      }
//    }
  }
}

extension KNProfileHomeCoordinator: KNProfileHomeViewControllerDelegate {
  func profileHomeViewController(_ controller: KNProfileHomeViewController, run event: KNProfileHomeViewEvent) {
    switch event {
    case .signIn:
      self.openSignInView()
    case .signUp:
      self.openSignUpView()
    case .logOut:
      self.handleUserSignOut()
    case .openVerification:
      self.openVerificationView()
    }
  }

  fileprivate func openVerificationView() {
//    guard let user = IEOUserStorage.shared.user else { return }
//    if user.kycStatus.lowercased() == "blocked" { return }
//    if let date = self.lastUpdatedUserInfo, Date().timeIntervalSince(date) <= 2.0, user.kycStatus.lowercased() != "rejected" {
//      if user.kycStatus.lowercased() == "approved" || user.kycStatus.lowercased() == "pending" { return }
//      // draft or none, just open the verification
//      self.kycCoordinator = KYCCoordinator(navigationController: self.navigationController, user: user)
//      self.kycCoordinator?.delegate = self
//      self.kycCoordinator?.start()
//      return
//    }
//    self.navigationController.displayLoading(text: "\(NSLocalizedString("checking", value: "Checking", comment: ""))...", animated: true)
//    self.getUserInfo(
//      type: user.tokenType,
//      accessToken: user.accessToken,
//      refreshToken: user.refreshToken,
//      expireTime: user.expireTime,
//      hasUser: true,
//      showError: true) { [weak self] success in
//        guard let `self` = self, let user = IEOUserStorage.shared.user else { return }
//        if success {
//          self.rootViewController.coordinatorUserDidSignInSuccessfully()
//          let status = user.kycStatus.lowercased()
//          if status == "approved" || status == "pending" || status == "blocked" { return }
//          if status == "rejected" {
//            self.sendResubmitRequest(for: user)
//          } else {
//            self.kycCoordinator = KYCCoordinator(navigationController: self.navigationController, user: user)
//            self.kycCoordinator?.delegate = self
//            self.kycCoordinator?.start()
//          }
//        }
//    }
  }

  fileprivate func sendResubmitRequest(for user: IEOUser) {
//    self.navigationController.displayLoading()
//    let accessToken = user.accessToken
//    DispatchQueue.global(qos: .background).async {
//      let provider = MoyaProvider<ProfileKYCService>()
//      provider.request(.resubmitKYC(accessToken: accessToken)) { [weak self] result in
//        guard let `self` = self else { return }
//        DispatchQueue.main.async {
//          self.navigationController.hideLoading()
//          switch result {
//          case .success(let resp):
//            var json: JSONDictionary = [:]
//            do {
//              json = try resp.mapJSON() as? JSONDictionary ?? [:]
//            } catch {} // ignore catch error
//            let success = json["success"] as? Bool ?? false
//            let reason = json["reason"] as? String ?? NSLocalizedString("unknown.reason", value: "Unknown reason", comment: "")
//            if success {
//              self.kycCoordinator = KYCCoordinator(navigationController: self.navigationController, user: user)
//              self.kycCoordinator?.delegate = self
//              self.kycCoordinator?.start()
//            } else {
//              self.navigationController.showWarningTopBannerMessage(
//                with: NSLocalizedString("error", value: "Error", comment: ""),
//                message: reason,
//                time: 1.5
//              )
//            }
//          case .failure(let error):
//            self.navigationController.displayError(error: error)
//          }
//        }
//      }
//    }
  }
}

extension KNProfileHomeCoordinator: KYCCoordinatorDelegate {
  func kycCoordinatorDidSubmitData() {
//    self.kycCoordinator = nil
//    guard let user = IEOUserStorage.shared.user else { return }
//    self.navigationController.displayLoading(
//      text: NSLocalizedString("updating.data", value: "Updating data", comment: ""),
//      animated: true
//    )
//    self.getUserInfo(
//      type: user.tokenType,
//      accessToken: user.accessToken,
//      refreshToken: user.refreshToken,
//      expireTime: user.expireTime,
//      hasUser: true,
//      showError: true,
//      completion: { success in
//        if success {
//          self.rootViewController.coordinatorUserDidSignInSuccessfully()
//        }
//      }
//    )
  }

  func kycCoordinatorDidBack() {
    self.kycCoordinator = nil
  }
}
