//
// Created by Fuxing Loh on 2018-12-07.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SafariServices

class RIPAboutFirstDividerCard: RIPCard {
    private let separatorLine = RIPSeparatorLine()

    override func didLoad(data: PlaceData!) {
        self.addSubview(separatorLine)

        separatorLine.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.top.bottom.equalTo(self).inset(24)
        }
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return RIPHourCard.isAvailable(data: data) ||
                RIPPriceCard.isAvailable(data: data) ||
                RIPPhoneCard.isAvailable(data: data) ||
                RIPMenuWebsiteCard.isAvailable(data: data)
    }
}

class RIPAboutSecondDividerCard: RIPCard {
    private let separatorLine = RIPSeparatorLine()

    override func didLoad(data: PlaceData!) {
        self.addSubview(separatorLine)

        separatorLine.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.top.equalTo(self).inset(24)
            maker.bottom.equalTo(self).inset(12)
        }
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return RIPDescriptionCard.isAvailable(data: data) ||
                RIPAwardCard.isAvailable(data: data) ||
                RIPWebsiteCard.isAvailable(data: data)
    }
}

class RIPDescriptionCard: RIPCard {
    private let value = UILabel(style: .regular)
            .with(numberOfLines: 4)

    override func didLoad(data: PlaceData!) {
        self.value.text = data.place.description
        self.addSubview(value)

        value.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).inset(12)
            maker.left.right.equalTo(self).inset(24)
        }
        self.layoutIfNeeded()
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return data.place.description != nil
    }

    override func didSelect(data: PlaceData!, controller: RIPController) {
        let destination = RIPDescriptionController(place: data.place)

        let delegate = HalfModalTransitioningDelegate(viewController: controller, presentingViewController: destination)
        destination.modalPresentationStyle = .custom
        destination.transitioningDelegate = delegate
        MunchAnalytic.logEvent("rip_click_about")
        controller.present(destination, animated: true)
    }
}

class RIPPhoneCard: RIPCard {
    private let labelValue = RIPLabelValue(title: "PHONE")

    override func didLoad(data: PlaceData!) {
        self.addSubview(labelValue)
        labelValue.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }
    }

    override func willDisplay(data: PlaceData!) {
        self.labelValue.text = data.place.phone
    }

    override func didSelect(data: PlaceData!, controller: RIPController) {
        let phone = data.place.phone!.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
            MunchAnalytic.logEvent("rip_click_phone")
            UIApplication.shared.open(url)
        }
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return data.place.phone != nil
    }
}

class RIPPriceCard: RIPCard {
    private let labelValue = RIPLabelValue(title: "PRICE PER PERSON")

    override func didLoad(data: PlaceData!) {
        self.addSubview(labelValue)
        labelValue.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }
    }

    override func willDisplay(data: PlaceData!) {
        self.labelValue.text = "$\(data.place.price!.perPax!.roundTo(places: 1))"
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return data.place.price?.perPax != nil
    }
}

class RIPWebsiteCard: RIPCard, SFSafariViewControllerDelegate {
    private let labelValue = RIPLabelValue(title: "WEBSITE")

    override func didLoad(data: PlaceData!) {
        self.addSubview(labelValue)
        labelValue.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
        }
    }

    override func willDisplay(data: PlaceData!) {
        self.labelValue.text = data.place.website
    }

    override func didSelect(data: PlaceData!, controller: RIPController) {
        guard  let url = URL.init(string: data.place.website!) else {
            return
        }

        let alert = UIAlertController(title: nil, message: "Open in Safari?".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Open", style: .default, handler: { action in
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            MunchAnalytic.logEvent("rip_click_website")
            self.controller.present(safari, animated: true, completion: nil)
        }))
        controller.present(alert, animated: true, completion: nil)
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return data.place.website != nil
    }
}

fileprivate class RIPLabelValue: UIView {
    private let label = UILabel(style: .regular)
            .with(font: UIFont.systemFont(ofSize: 14, weight: .bold))
            .with(color: .secondary700)

    private let value = UILabel(style: .regular)
            .with(alignment: .right)

    required init(title: String) {
        super.init(frame: .zero)
        self.label.with(text: title)

        self.addSubview(label)
        self.addSubview(value)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        value.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        label.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(value)
            maker.left.equalTo(self).inset(24)
        }

        value.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self).inset(10)
            maker.left.equalTo(label.snp.right).inset(-24)
            maker.right.equalTo(self).inset(24)
        }
    }

    var text: String? {
        didSet {
            self.value.text = text
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class RIPDescriptionController: HalfModalController {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceHorizontal = false
        return scrollView
    }()
    private let header = UILabel(style: .h2)
            .with(numberOfLines: 0)
    private let label = UILabel(style: .regular)
            .with(numberOfLines: 0)

    init(place: Place) {
        header.with(text: "About \(place.name)")
        label.with(text: place.description, lineSpacing: 1.5)
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.addSubview(header)
        scrollView.addSubview(label)
        self.view.addSubview(scrollView)

        scrollView.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.safeArea.top)
            maker.bottom.equalTo(self.view.safeArea.bottom)
            maker.left.right.equalTo(self.view)
        }

        header.snp.makeConstraints { maker in
            maker.top.equalTo(scrollView).inset(24)
            maker.left.right.equalTo(self.view).inset(24)
        }

        label.snp.makeConstraints { maker in
            maker.top.equalTo(header.snp.bottom).inset(-16)
            maker.bottom.equalTo(scrollView).inset(24)
            maker.left.right.equalTo(self.view).inset(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}