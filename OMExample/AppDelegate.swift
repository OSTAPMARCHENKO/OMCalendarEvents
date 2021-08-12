//
//  AppDelegate.swift
//  OMExample
//
//  Created by Ostap Marchenko on 8/12/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)

        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController

        self.window?.rootViewController = viewController
        self.window?.makeKeyAndVisible()

        return true
    }
}

