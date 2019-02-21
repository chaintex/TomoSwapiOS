// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Branch
//import Moya
//import Fabric
//import Crashlytics
import UserNotificationsUI
import UserNotifications
//import OneSignal

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    var window: UIWindow?
    var coordinator: KNAppCoordinator!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (_, _) in
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
            application.applicationIconBadgeNumber = 0
          }
        }
        UNUserNotificationCenter.current().delegate = self
        window = UIWindow(frame: UIScreen.main.bounds)
        do {
            let keystore = try EtherKeystore()
            coordinator = KNAppCoordinator(window: window!, keystore: keystore)
            coordinator.start()
            coordinator.appDidFinishLaunch()
        } catch {
            print("EtherKeystore init issue.")
        }
        KNReachability.shared.startNetworkReachabilityObserver()
//        Fabric.with([Crashlytics.self])
//        OneSignal.setRequiresUserPrivacyConsent(false)
//        OneSignal.initWithLaunchOptions(launchOptions, appId: KNSecret.oneSignalAppID)
//        OneSignal.inFocusDisplayType = .notification
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        coordinator.appDidBecomeActive()
        KNReachability.shared.startNetworkReachabilityObserver()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        coordinator.appDidEnterBackground()
      KNReachability.shared.stopNetworkReachabilityObserver()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
      self.coordinator.appWillEnterForeground()
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplicationExtensionPointIdentifier) -> Bool {
        if extensionPointIdentifier == UIApplicationExtensionPointIdentifier.keyboard {
            return false
        }
        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
      return true
    }

    // Respond to URI scheme links
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
      return true
    }

    // Respond to Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    guard let txHash = response.notification.request.content.userInfo["transaction_hash"] as? String else {
      completionHandler()
      return
    }
    self.coordinator.appDidReceiveLocalNotification(transactionHash: txHash)
    completionHandler()
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .sound, .badge])
  }
}
