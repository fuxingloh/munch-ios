//
//  TabBarController.swift
//  Munch
//
//  Created by Fuxing Loh on 16/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import ESTabBarController_swift


/**
 Initial view provider
 */
enum InitialViewProvider {

    /**
     Main tab controllers for Munch App
     */
    static func main() -> TabBarController {
        return TabBarController()
    }

    fileprivate static func search() -> UIViewController {
        let controller = DiscoverNavigationalController()
        controller.tabBarItem = ESTabBarItem(MunchTabBarContentView(), title: "Discover", image: UIImage(named: "TabBar-Search"))
        return controller
    }

    fileprivate static func account() -> UIViewController {
        let controller = AccountController()
        controller.tabBarItem = ESTabBarItem(MunchTabBarContentView(), title: "Profile", image: UIImage(named: "TabBar-Profile"))
        return controller
    }
}

class TabBarController: ESTabBarController, UITabBarControllerDelegate {
    var previousController: UIViewController?
    var sameTabCounter = 0

    let searchController = InitialViewProvider.search()
    let accountController = InitialViewProvider.account()

    init() {
        super.init(nibName: nil, bundle: nil)
        tabBar.isTranslucent = false
        tabBar.backgroundColor = UIColor.white
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
        tabBar.shadow(vertical: -2)
        tabBar.frame = tabBar.frame.offsetBy(dx: 0, dy: -10)

        self.delegate = self
        self.viewControllers = [searchController, accountController]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        switch viewController {
        case is AccountController where Authentication.isAuthenticated():
            return true

        case is AccountController where !Authentication.isAuthenticated():
            Authentication.requireAuthentication(controller: self) { state in
                switch state {
                case .loggedIn:
                    tabBarController.selectedViewController = self.accountController
                default:
                    return
                }
            }
            return false

        case let nav as UINavigationController:
            if let controller = nav.topViewController as? DiscoverController {
                if (self.previousController == viewController) {
                    sameTabCounter += 1
                    if (sameTabCounter >= 2) {
                        controller.scrollsToTop(animated: true)
                    }
                } else {
                    sameTabCounter = 0
                }
                self.previousController = viewController
            }
            return true
        default: return true
        }
    }

    var discoverController: DiscoverController? {
        if let controllers = viewControllers {
            for controller in controllers {
                if let controller = (controller as? UINavigationController)?.topViewController as? DiscoverController {
                    return controller
                }
            }
        }
        return nil
    }
}

/**
 Main tab bar content styling
 */
class MunchTabBarContentView: ESTabBarItemContentView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = UIFont.systemFont(ofSize: 9, weight: .semibold)
        insets.bottom = 4
        insets.top = 5

        textColor = UIColor(hex: "A0A0A0")
        highlightTextColor = UIColor.primary500

        iconColor = UIColor(hex: "A0A0A0")
        highlightIconColor = UIColor.primary500

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
