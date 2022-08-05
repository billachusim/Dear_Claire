// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    Messaging.messaging().delegate = self
    GeneratedPluginRegistrant.register(with: self)
      if #available(iOS 10.0, *) {
        // For iOS 10 display notification (sent via APNS)
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in }
        )
      } else {
        let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
      }
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    override func application(_ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

     Messaging.messaging().apnsToken = deviceToken
     super.application(application,
     didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
     }

            // Receive displayed notifications for iOS 10 devices.
              override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                        willPresent notification: UNNotification,
                                        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
                                          -> Void) {
              let userInfo = notification.request.content.userInfo

              // With swizzling disabled you must let Messaging know about the message, for Analytics
              Messaging.messaging().appDidReceiveMessage(userInfo)

              // ...

              // Print full message.
              print(userInfo)

              // Change this to your preferred presentation option
              completionHandler([[.alert, .sound]])
            }

            override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                        didReceive response: UNNotificationResponse,
                                        withCompletionHandler completionHandler: @escaping () -> Void) {
              let userInfo = response.notification.request.content.userInfo

              // ...

              // With swizzling disabled you must let Messaging know about the message, for Analytics
              Messaging.messaging().appDidReceiveMessage(userInfo)

              // Print full message.
              print(userInfo)

              completionHandler()
            }
}
