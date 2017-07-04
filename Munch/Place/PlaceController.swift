//
//  PlaceController.swift
//  Munch
//
//  Created by Fuxing Loh on 28/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Kingfisher

import UIKit
import SnapKit
import Hero

import MXSegmentedPager

class PlaceViewController: MXSegmentedPagerController {
    var place: Place!
    var appLink: AppLink!
    
    let imageGradientBorder = UIView()
    @IBOutlet weak var placeHeaderView: UIView!
    @IBOutlet weak var placeImageGradientView: UIView!
    @IBOutlet weak var placeImageView: UIImageView!
    
    @IBOutlet weak var placeRatingLabel: UILabel!
    @IBOutlet weak var placeNavBar: PlaceNavBar!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.appLink = AppLink(controller: self)
        
        self.segmentedPager.backgroundColor = UIColor.white
        self.segmentedPager.pager.isScrollEnabled = true // Scrolling of page from side to side
        
        // Setup 2 header UI, pages are auto setup using datasource and segues
        setupParallaxHeader()
        setupSegmentControl()
        
        // Finally render the place data
        render(place: place)
    }
    
    func setupParallaxHeader() {
        // Parallax Header
        self.segmentedPager.parallaxHeader.view = placeHeaderView
        self.segmentedPager.parallaxHeader.mode = .fill
        self.segmentedPager.parallaxHeader.height = 320
        self.segmentedPager.parallaxHeader.minimumHeight = 53 + 64
        
        // Add gradient bar for image so that nav bar buttons and status bar can be seen
        let placeImageGradient = CAGradientLayer()
        placeImageGradient.frame = CGRect(x: 0, y: 0, width: UIScreen.width, height: 64)
        placeImageGradient.colors = [UIColor.black.withAlphaComponent(0.8).cgColor, UIColor.clear.cgColor]
        placeImageView.layer.insertSublayer(placeImageGradient, at: 0)
        
        // Add shadow/border line for placeImageGradientView
        imageGradientBorder.isHidden = true
        imageGradientBorder.backgroundColor = UIBorder.color
        placeImageGradientView.addSubview(imageGradientBorder)
        imageGradientBorder.snp.makeConstraints { make in
            make.height.equalTo(UIBorder.onePixel)
            make.left.equalTo(placeImageGradientView)
            make.right.equalTo(placeImageGradientView)
            make.bottom.equalTo(placeImageGradientView)
        }
    }
    
    /**
     Segmented Control customization
     */
    func setupSegmentControl() {
        let control = self.segmentedPager.segmentedControl
        control.selectionIndicatorLocation = .none
        control.segmentWidthStyle = .fixed
        control.backgroundColor = UIColor.white
        control.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.black.withAlphaComponent(0.85),
            NSFontAttributeName: UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)
        ]
        control.selectedTitleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
        ]
        
        // Create border for segmented control top and bottom
        let topBorder = UIView()
        let bottomBorder = UIView()
        control.addSubview(topBorder)
        control.addSubview(bottomBorder)
        topBorder.backgroundColor = UIBorder.color
        bottomBorder.backgroundColor = UIBorder.color
        // Add constraint for top/bottom border
        topBorder.snp.makeConstraints { make in
            make.height.equalTo(UIBorder.onePixel)
            make.left.equalTo(control)
            make.right.equalTo(control)
            make.top.equalTo(control)
        }
        bottomBorder.snp.makeConstraints{ make in
            make.height.equalTo(UIBorder.onePixel)
            make.left.equalTo(control)
            make.right.equalTo(control)
            make.bottom.equalTo(control)
        }
        
        // Selected; top segment control
        segmentedPager.segmentedControl.indexChangeBlock = { index in
            self.segmentedPager(self.segmentedPager, didSelectViewWith: index)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func segmentedPager(_ segmentedPager: MXSegmentedPager, titleForSectionAt index: Int) -> String {
        return ["General", "Gallery", "Articles", "Reviews"][index]
    }
    
    /**
     Animate; hide/show parallaxHeader based on selected index
     */
    override func segmentedPager(_ segmentedPager: MXSegmentedPager, didSelectViewWith index: Int) {
        if (index == 0) {
            self.segmentedPager.bounces = true
            self.segmentedPager.contentView.isScrollEnabled = true
        }else{
            self.segmentedPager.bounces = false
            self.segmentedPager.contentView.isScrollEnabled = false
            self.segmentedPager.contentView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
    }
    
    /**
     Update gradient of image nav bar, progress 1.0 means full image
     Progress 0 means image hidden
     */
    override func segmentedPager(_ segmentedPager: MXSegmentedPager, didScrollWith parallaxHeader: MXParallaxHeader) {
        let progress = 1.0 - parallaxHeader.progress/0.8
        if (progress < 0.5) {
            // Transiting to white
            placeImageGradientView.backgroundColor = UIColor.white.withAlphaComponent(progress*2)
            navigationController?.navigationBar.barStyle = .blackTranslucent
            navigationController?.navigationBar.tintColor = UIColor.white
            imageGradientBorder.isHidden = true // 1px Shadow
            
            // Name label progress
            self.navigationItem.title = nil
            self.placeNavBar.placeNameLabel.textColor = UIColor.black
        } else {
            // Fullly white bar
            placeImageGradientView.backgroundColor = UIColor.white
            navigationController?.navigationBar.barStyle = .default
            navigationController?.navigationBar.tintColor = UIColor.black
            imageGradientBorder.isHidden = false // 1px Shadow
            
            // Name label progress for secondary nav bar
            self.navigationItem.title = place.name
            let nameProgress = 0.65/progress - 0.65
            self.placeNavBar.placeNameLabel.textColor = UIColor.black.withAlphaComponent(nameProgress)
        }
    }
    
    /**
     Pass place data to Abstract place controller
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PlaceControllers {
            controller.place = place
            controller.appLink = appLink
        }
    }
}

extension PlaceViewController {
    /**
     Render place struct to place controller
     */
    func render(place: Place) {
        // Render image
        if let images = place.images {
            if (!images.isEmpty) {
                placeImageView.render(imageMeta: images[0])
            }
        }
        
        // Render rating label
        let ratingColor = UIColor(hex: "5CB85C")
        placeRatingLabel.text = "4.9"
        placeRatingLabel.backgroundColor = ratingColor
        placeRatingLabel.layer.borderColor = ratingColor.cgColor
        
        // Render sticky bar
        self.placeNavBar.render(place: place)
    }
    
    /**
     All action button clicks is handled here
     */
    @IBAction func clickActionButton(_ sender: UIButton) {
        if let title = sender.currentTitle {
            switch(title){
            case "Call":
                if let phone = place.phone {
                    appLink.openApp(phone: phone)
                }
            case "Map" :
                if let address = place.location?.address {
                    appLink.openApp(address: address)
                }
            default: break
            }
        }
    }
}

/**
 App link to open other iOS application
 */
class AppLink {
    let controller: UIViewController
    
    init(controller: UIViewController) {
        self.controller = controller
    }
    
    /**
     Open the address app
     */
    func openApp(address: String) {
        let address = address.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if (UIApplication.shared.canOpenURL(URL(string:"http://maps.apple.com/")!)){
            let appleMapAction = UIAlertAction(title: "Apple Maps", style: .default) { alert in
                UIApplication.shared.open(URL(string:"http://maps.apple.com/?daddr=\(address)")!)
            }
            actionSheet.addAction(appleMapAction)
        }
        
        // Monster Jobs uses comgooglemap url scheme, those fuckers
        if (UIApplication.shared.canOpenURL(URL(string:"https://www.google.com/maps/")!)) {
            let googleMapAction = UIAlertAction(title: "Google Maps", style: .default) { alert in
                UIApplication.shared.open(URL(string:"https://www.google.com/maps/?daddr=\(address)")!)
            }
            actionSheet.addAction(googleMapAction)
        }
        
        // Present action sheet for user to choose map provider
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.present(actionSheet, animated: true, completion:nil)
    }
    
    /**
     Open the phone app
     */
    func openApp(phone: String) {
        let alert = UIAlertController(title: nil, message: "Call: \(phone)?", preferredStyle: .alert)
        
        if (UIApplication.shared.canOpenURL(URL(string:"http://maps.apple.com/")!)){
            let callAction = UIAlertAction(title: "Call", style: .default) { alert in
                if let url = URL(string: "telprompt:\(phone)") {
                    UIApplication.shared.open(url)
                }
            }
            alert.addAction(callAction)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
}

/**
 Place nav bar that appear under the parallex image
 */
class PlaceNavBar: UIView {
    
    @IBOutlet weak var placeMainButton: UIButton!
    @IBOutlet weak var placeNameLabel: UILabel!
    
    func render(place: Place) {
        placeNameLabel.text = place.name
        
        placeMainButton.backgroundColor = .clear
        placeMainButton.layer.cornerRadius = 5
        placeMainButton.layer.borderWidth = 1
        placeMainButton.layer.borderColor = UIColor(hex: "458eff").cgColor
    }
}

/**
 Abstract controllers for place segues
 */
class PlaceControllers: UIViewController {
    var place: Place!
    var appLink: AppLink!
}
