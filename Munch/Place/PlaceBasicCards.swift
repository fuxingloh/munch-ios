//
//  PlaceBasicCards.swift
//  Munch
//
//  Created by Fuxing Loh on 8/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import MapKit

import SnapKit
import SwiftRichString

class PlaceBasicImageBannerCard: PlaceCardView {
    let imageGradientView = UIView()
    let imageBannerView = ShimmerImageView()
    
    override func didLoad(card: PlaceCard) {
        self.addSubview(imageBannerView)
        imageBannerView.snp.makeConstraints { make in
            make.height.equalTo(260).priority(999)
            make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: topBottom, right: 0))
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 64)
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.5).cgColor, UIColor.clear.cgColor]
        imageGradientView.layer.insertSublayer(gradientLayer, at: 0)
        imageGradientView.backgroundColor = UIColor.clear
        self.addSubview(imageGradientView)
        
        imageGradientView.snp.makeConstraints { make in
            make.height.equalTo(64)
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
        }
        
        imageBannerView.render(images: card["images"][0]["images"])
    }
    
    override class var cardId: String? {
        return "basic_ImageBanner_20170915"
    }
}

class PlaceBasicNameTagCard: PlaceCardView {
    let nameLabel = UILabel()
    let tagsLabel = UILabel()
    
    override func didLoad(card: PlaceCard) {
        nameLabel.text = card["name"].string
        nameLabel.font = UIFont.systemFont(ofSize: 27.0, weight: UIFont.Weight.medium)
        nameLabel.textColor = UIColor.black.withAlphaComponent(0.9)
        nameLabel.numberOfLines = 0
        self.addSubview(nameLabel)
        
        let tags = card["tags"].arrayValue.map { $0.stringValue.capitalized }
        tagsLabel.text = tags.joined(separator: ", ")
        tagsLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
        tagsLabel.textColor = UIColor.black.withAlphaComponent(0.75)
        tagsLabel.numberOfLines = 1
        self.addSubview(tagsLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
        }
        
        tagsLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).inset(0)
            make.left.right.equalTo(self).inset(leftRight)
            make.bottom.equalTo(self).inset(topBottom)
        }
    }
    
    override class var cardId: String? {
        return "basic_NameTag_20170912"
    }
}

class PlaceBasicBusinessHourCard: PlaceCardView {
    static let openStyle = Style("open", {
        $0.color = UIColor.secondary
    })
    static let closeStyle = Style("close", {
        $0.color = UIColor.primary
    })
    
    let grid = UIView()
    let openLabel = UILabel()
    let dayView = DayView()
    
    var openHeightConstraint: Constraint!
    var dayHeightConstraint: Constraint!
    
    override func didLoad(card: PlaceCard) {
        let hours = BusinessHour(hours: card["hours"].flatMap { Place.Hour(json: $0.1) })
        
        self.addSubview(grid)
        grid.snp.makeConstraints { (make) in
            make.left.right.equalTo(self).inset(leftRight)
            make.top.bottom.equalTo(self).inset(topBottom)
        }
        
        if hours.isOpen() {
            openLabel.attributedText = "Open Now\n".set(style: PlaceBasicBusinessHourCard.openStyle) + hours.today
        } else {
            openLabel.attributedText = "Closed Now\n".set(style: PlaceBasicBusinessHourCard.closeStyle) + hours.today
        }
        grid.addSubview(openLabel)
        openLabel.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
        openLabel.numberOfLines = 2
        openLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(grid)
            make.left.right.equalTo(grid)
        }
        
        dayView.render(hours: hours)
        dayView.isHidden = true
        grid.addSubview(dayView)
    }
    
    override func didTap() {
        dayView.isHidden = !dayView.isHidden
        openLabel.isHidden = !openLabel.isHidden
        
        if (openLabel.isHidden) {
            openLabel.snp.removeConstraints()
            dayView.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(grid)
                make.left.right.equalTo(grid)
                make.height.equalTo(44 * 7)
            }
        }
        
        if (dayView.isHidden){
            dayView.snp.removeConstraints()
            openLabel.snp.makeConstraints { (make) in
                make.top.bottom.equalTo(grid)
                make.left.right.equalTo(grid)
            }
        }
    }
    
    override class var cardId: String? {
        return "basic_BusinessHour_20170907"
    }
    
    class DayView: UIView {
        let dayLabels = [UILabel(), UILabel(), UILabel(), UILabel(), UILabel(), UILabel(), UILabel()]
        
        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.clipsToBounds = true
            
            for (index, label) in dayLabels.enumerated() {
                label.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.regular)
                label.numberOfLines = 2
                self.addSubview(label)

                label.snp.makeConstraints { make in
                    make.left.right.equalTo(self)
                    make.height.equalTo(44)
                    
                    if index == 0 {
                        make.top.equalTo(self)
                    } else {
                        make.top.equalTo(dayLabels[index-1].snp.bottom)
                    }
                }
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func render(hours: BusinessHour) {
            func createLine(day: String, dayText: String) -> NSAttributedString {
                if hours.isToday(day: day) {
                    if hours.isOpen() {
                        return "\(dayText)\n" + hours[day].set(style: PlaceBasicBusinessHourCard.openStyle)
                    } else {
                        return "\(dayText)\n" + hours[day].set(style: PlaceBasicBusinessHourCard.closeStyle)
                    }
                } else {
                    return NSAttributedString(string: "\(dayText)\n\(hours[day])")
                }
            }
            
            dayLabels[0].attributedText = createLine(day: "mon", dayText: "Monday")
            dayLabels[1].attributedText = createLine(day: "tue", dayText: "Tuesday")
            dayLabels[2].attributedText = createLine(day: "wed", dayText: "Wednesday")
            dayLabels[3].attributedText = createLine(day: "thu", dayText: "Thursday")
            dayLabels[4].attributedText = createLine(day: "fri", dayText: "Friday")
            dayLabels[5].attributedText = createLine(day: "sat", dayText: "Saturday")
            dayLabels[6].attributedText = createLine(day: "sun", dayText: "Sunday")
        }
    }
    
    class BusinessHour {
        let hours: [Place.Hour]
        let dayHours: [String: String]
        
        init(hours: [Place.Hour]) {
            self.hours = hours
            
            var dayHours = [String: String]()
            for hour in hours.sorted(by: { $0.open > $1.open } ) {
                if let timeText = dayHours[hour.day] {
                    dayHours[hour.day] = timeText + ", " + hour.timeText()
                } else {
                    dayHours[hour.day] = hour.timeText()
                }
            }
            self.dayHours = dayHours
        }
        
        subscript(day: String) -> String {
            get {
                return dayHours[day] ?? "Closed"
            }
        }
        
        func isToday(day: String) -> Bool {
            return day == Place.Hour.Formatter.dayNow().lowercased()
        }
        
        func isOpen() -> Bool {
            return Place.Hour.Formatter.isOpen(hours: hours) ?? false
        }
        
        var today: String {
            return self[Place.Hour.Formatter.dayNow().lowercased()]
        }
    }
}

class PlaceBasicAddressCard: PlaceCardView {
    let lineOneLabel = UILabel()
    let lineTwoLabel = UILabel()
    var address: String?
    
    override func didLoad(card: PlaceCard) {
        lineOneLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.regular)
        lineOneLabel.numberOfLines = 0
        self.addSubview(lineOneLabel)
        
        lineTwoLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.regular)
        lineTwoLabel.numberOfLines = 1
        self.addSubview(lineTwoLabel)
        
        lineOneLabel.snp.makeConstraints { make in
            make.top.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self).inset(leftRight)
        }
        
        lineTwoLabel.snp.makeConstraints { make in
            make.top.equalTo(lineOneLabel.snp.bottom)
            make.left.right.equalTo(self).inset(leftRight)
            make.bottom.equalTo(self).inset(topBottom)
        }
        
        self.address = card["address"].string
        render(lineOne: card)
        render(lineTwo: card)
    }
    
    override func didTap() {
        if let address = address?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            // Monster Jobs uses comgooglemap url scheme, those fuckers
            if (UIApplication.shared.canOpenURL(URL(string:"https://www.google.com/maps/")!)) {
                UIApplication.shared.open(URL(string:"https://www.google.com/maps/?daddr=\(address)")!)
            } else if (UIApplication.shared.canOpenURL(URL(string:"http://maps.apple.com/")!)){
                UIApplication.shared.open(URL(string:"http://maps.apple.com/?daddr=\(address)")!)
            }
        }
    }
    
    private func render(lineOne card: PlaceCard) {
        var line = [NSAttributedString]()
        
        if let street = card["street"].string {
            line.append(street.set(style: .default {
                $0.font = FontAttribute(font: UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.medium))
                }
            ))
        }
        
        if let unitNumber = card["unitNumber"].string {
            if unitNumber.hasPrefix("#") {
                line.append(NSAttributedString(string: unitNumber))
            } else {
                line.append(NSAttributedString(string: "#\(unitNumber)"))
            }
        }
        
        if let city = card["city"].string, let postal = card["postal"].string {
            line.append(NSAttributedString(string: "\(city) \(postal)"))
        }
        
        if (!line.isEmpty) {
            let attrString = NSMutableAttributedString(attributedString: line[0])
            for string in line.dropFirst() {
                attrString.append(NSAttributedString(string: ", "))
                attrString.append(string)
            }
            lineOneLabel.attributedText = attrString
        } else if let address = card["address"].string {
            lineOneLabel.text = address
        }
    }
    
    private func render(lineTwo card: PlaceCard) {
        var line = [String]()
        
        if let latLng = card["latLng"].string, MunchLocation.isEnabled {
            if let distance = MunchLocation.distance(asMetric: latLng) {
                line.append(distance)
            }
        }
        
        if let nearestTrain = card["nearestTrain"].string {
            line.append(nearestTrain + " MRT")
        }
        
        lineTwoLabel.text = line.joined(separator: " • ")
    }
    
    override class var cardId: String? {
        return "basic_Address_20170924"
    }
}

class PlaceBasicLocationCard: PlaceCardView {
    let titleLabel = UILabel()
    let directionLabel = UILabel()
    
    let mapView = MKMapView()
    var address: String?
    
    override func didLoad(card: PlaceCard) {
        super.addSubview(titleLabel)
        titleLabel.text = "Location"
        titleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.medium)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
        }
        
        super.addSubview(directionLabel)
        directionLabel.text = "Directions >"
        directionLabel.font = UIFont.systemFont(ofSize: 15.0, weight: UIFont.Weight.regular)
        directionLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self).inset(leftRight)
            make.top.equalTo(self).inset(topBottom)
            make.height.equalTo(titleLabel.snp.height)
        }
        
        self.addSubview(mapView)
        mapView.isUserInteractionEnabled = false
        mapView.showsUserLocation = false
        mapView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).inset(-10)
            make.bottom.equalTo(self).inset(topBottom)
            make.left.right.equalTo(self)
            make.height.equalTo(230)
        }
        
        self.address = card["address"].string
        render(location: card)
    }
    
    override func didTap() {
        if let address = address?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
            // Monster Jobs uses comgooglemap url scheme, those fuckers
            if (UIApplication.shared.canOpenURL(URL(string:"https://www.google.com/maps/")!)) {
                UIApplication.shared.open(URL(string:"https://www.google.com/maps/?daddr=\(address)")!)
            } else if (UIApplication.shared.canOpenURL(URL(string:"http://maps.apple.com/")!)){
                UIApplication.shared.open(URL(string:"http://maps.apple.com/?daddr=\(address)")!)
            }
        }
    }
    
    private func render(location card: PlaceCard) {
        if let coordinate = CLLocation(latLng: card["latLng"].stringValue)?.coordinate {
            var region = MKCoordinateRegion()
            region.center.latitude = coordinate.latitude
            region.center.longitude = coordinate.longitude
            region.span.latitudeDelta = 0.004
            region.span.longitudeDelta = 0.004
            mapView.setRegion(region, animated: false)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = card["placeName"].stringValue
            mapView.addAnnotation(annotation)
        }
    }
    
    override class var cardId: String? {
        return "basic_Location_20170924"
    }
}
