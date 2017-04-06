//
//  TabViewControllers.swift
//  Munch
//
//  Created by Fuxing Loh on 7/4/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import ESTabBarController

class MunchTabViewController: ESTabBarController {
    
}

class SearchNavigationController: UINavigationController {
    
    /**
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.selectedIndex = 0
    }
    
}

/**
 Tab bar content styling
 */
class MunchTabBarContentView: ESTabBarItemContentView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        iconColor = UIColor.black
        highlightIconColor = UIColor.black
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SearchTabBarItem: ESTabBarItem {
    
    required init(coder aDecoder: NSCoder) {
        super.init(MunchTabBarContentView(), title: nil, image: UIImage(named: "Search-30"), selectedImage: UIImage(named: "Search Filled-30"))
    }
    
}

class AccountTabBarItem: ESTabBarItem {
    
    required init!(coder aDecoder: NSCoder) {
        super.init(MunchTabBarContentView(), title: nil, image: UIImage(named: "User-30"), selectedImage: UIImage(named: "User Filled-30"))
    }
    
}
