//
//  DiscoverController.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import SwiftLocation
import Kingfisher

import UIKit
import SnapKit
import Hero

import FlexibleHeightBar
import ESTabBarController

/**
 Munch search bar is a duo search bar
 That is used by search controller
 , location search controller
 and field search controller
 */
class MunchSearchBar: UIView {
    @IBOutlet weak var locationSearchField: DiscoverSearchField!
    @IBOutlet weak var filterSearchField: DiscoverSearchField!
    
    func update(previous: MunchSearchBar) -> Bool {
        // Check for changes
        let changes = locationSearchField.text != previous.locationSearchField.text ||
        filterSearchField.text != previous.filterSearchField.text
        
        apply(previous: previous)
        return changes
    }

    /**
     Apply update to text from previous search bar
     */
    func apply(previous: MunchSearchBar) {
        locationSearchField.text = previous.locationSearchField.text
        filterSearchField.text = previous.filterSearchField.text
    }
    
    func setDelegate(delegate: UITextFieldDelegate) {
        self.locationSearchField.delegate = delegate
        self.filterSearchField.delegate = delegate
    }
}

class SearchViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var discoverTableView: UITableView!
    @IBOutlet var searchBar: MunchSearchBar!
    var delegate: SearchTableDelegate!
    
    var discoverPlaces = [Place]()
    var selectedIndex: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = SearchTableDelegate(controller: self)
        self.discoverTableView.delegate = self.delegate
        self.discoverTableView.dataSource = self.delegate
        
        self.navigationController?.navigationBar.barStyle = .black
        self.setupFlexibleSearchBar()
        self.searchBar.setDelegate(delegate: self)
    }
    
    func setupFlexibleSearchBar() {
        let height: CGFloat = 154.0
        let flexibleBar = FlexibleHeightBar(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: height))
        flexibleBar.minimumBarHeight = 64.0
        flexibleBar.maximumBarHeight = height
        
        flexibleBar.backgroundColor = UIColor.primary
        flexibleBar.behaviorDefiner = FacebookBarBehaviorDefiner()
        flexibleBar.addSubview(searchBar)

        // Search bar snaps to flexible bar
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(flexibleBar)
            make.left.equalTo(flexibleBar)
            make.right.equalTo(flexibleBar)
            make.bottom.equalTo(flexibleBar)
        }
        
        self.view.addSubview(flexibleBar)
        self.delegate.otherDelegate = flexibleBar.behaviorDefiner
        self.discoverTableView.contentInset = UIEdgeInsetsMake(height - 64.0, 0.0, 0.0, 0.0)
    }
    
    /**
     Segue to location or filter search
     */
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if (textField == searchBar.locationSearchField) {
            performSegue(withIdentifier: "segueToLocationSearch", sender: self)
        }else if (textField == searchBar.filterSearchField) {
            performSegue(withIdentifier: "segueToFilterSearch", sender: self)
        }
        return false
    }
    
    /**
     Prepare for segue transition for search bar controller
     Using hero transition
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? SearchBarController {
            controller.previousSearchBar = self.searchBar
            
            self.navigationController!.isHeroEnabled = true
            self.navigationController!.heroNavigationAnimationType = .fade
        }
    }
    
    /**
     Unwind Search
     Check search bar and source search bar for changes
     If there is changes, will do re-search
     */
    @IBAction func unwindSearch(segue: UIStoryboardSegue) {
        if let controller = segue.source as? SearchBarController {
            if (self.searchBar.update(previous: controller.searchBar)) {
                // Chages is search bar, do re-search
                print("Search changed")
            }
        }
    }
}

/**
 Custom delegate because scroll view delegate ned to be shared with
 Flexible height bar
 */
class SearchTableDelegate: TableViewDelegateHandler, UITableViewDataSource {
    let controller: SearchViewController
    
    init(controller: SearchViewController) {
        self.controller = controller
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controller.discoverPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let storyboard = UIStoryboard(name: "Place", bundle: nil)
        
        let placeController = storyboard.instantiateInitialViewController() as! PlaceViewController
        placeController.place = self.controller.discoverPlaces[indexPath.row]
        self.controller.navigationController!.isHeroEnabled = false
        self.controller.navigationController!.pushViewController(placeController, animated: true)
    }
}

/**
 Shared search bar controller for location & filter views
 */
class SearchBarController: UIViewController, UITextFieldDelegate {
    var previousController: SearchBarController?
    var previousSearchBar: MunchSearchBar!
    @IBOutlet weak var searchBar: MunchSearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Disable back button
        self.navigationItem.hidesBackButton = true
        // Fixes elipsis bug when multiple segue are chained
        let backBarItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backBarItem
        
        // Setup search bar
        self.searchBar.apply(previous: previousSearchBar)
        self.searchBar.setDelegate(delegate: self)
    }
    
    @IBAction func actionCancel(_ sender: Any) {
        // Un-apply search bar due to cancel
        self.searchBar.apply(previous: previousSearchBar)
        performSegue(withIdentifier: "unwindSearchWithSegue", sender: self)
    }
    
    /**
     User click return button on either search bar
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        performSegue(withIdentifier: "unwindSearchWithSegue", sender: self)
        return true
    }
    
    /**
     Prepare for segue transition for search bar controller
     Using hero transition
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? SearchBarController {
            controller.previousController = self
            controller.previousSearchBar = self.searchBar
            
            self.navigationController!.isHeroEnabled = true
            self.navigationController!.heroNavigationAnimationType = .fade
        }
    }
    
    /**
     Text field helper to check if need to transit to another view controller
     */
    func textFieldShouldBeginEditing(_ textField: UITextField, altTextField: UITextField, segue: String) -> Bool {
        if (textField == altTextField) {
            // Check if previous controller is the controller forward
            if let controller = previousController {
                controller.searchBar.apply(previous: self.searchBar)
                hero_dismissViewController()
            }else{
                performSegue(withIdentifier: segue, sender: self)
            }
            return false
        }
        return true
    }
}

class SearchLocationController: SearchBarController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.searchBar.locationSearchField.becomeFirstResponder()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return textFieldShouldBeginEditing(textField, altTextField: searchBar.filterSearchField, segue: "segueToFilterSearch")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.font = UIFont.boldSystemFont(ofSize: 13)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.7)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

class SearchFilterController: SearchBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.searchBar.filterSearchField.becomeFirstResponder()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return textFieldShouldBeginEditing(textField, altTextField: searchBar.locationSearchField, segue: "segueToLocationSearch")
    }
}