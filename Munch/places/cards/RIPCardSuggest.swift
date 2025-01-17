//
// Created by Fuxing Loh on 19/2/18.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import RxSwift
import SafariServices

class RIPSuggestEditCard: RIPCard {

    private let separatorLine = RIPSeparatorLine()
    let button: UIButton = {
        let button = UIButton()
        button.setTitle("Suggest Edits", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = FontStyle.regular.font

        button.setImage(UIImage(named: "RIP-Card-Edit"), for: .normal)
        button.tintColor = UIColor.black
        button.imageEdgeInsets.right = 18
        return button
    }()

    var place: Place?

    override func didLoad(data: PlaceData!) {
        self.addSubview(button)
        self.addSubview(separatorLine)
        self.addTargets(controller: self.controller)

        button.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.top.equalTo(self).inset(12)
        }

        separatorLine.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)

            maker.top.equalTo(button.snp.bottom).inset(-24)
            maker.bottom.equalTo(self).inset(12)
        }
    }

    override func willDisplay(data: PlaceData!) {
        self.place = data.place
    }
}

extension RIPSuggestEditCard: SFSafariViewControllerDelegate {
    func addTargets(controller: RIPController) {
        self.button.addTarget(self, action: #selector(onSuggestEdit), for: .touchUpInside)
    }

    @objc func onSuggestEdit() {
        RIPSuggestEditCard.onSuggestEdit(place: self.place, controller: self.controller, delegate: self)
    }

    static func onSuggestEdit(place: Place?, controller: UIViewController, delegate: SFSafariViewControllerDelegate) {
        guard let place = place else {
            return
        }

        Authentication.requireAuthentication(controller: controller) { state in
            guard case .loggedIn = state else {
                return
            }

            Authentication.getCustomToken().subscribe { event in
                switch event {
                case let .success(token):
                    let components = NSURLComponents(string: "https://www.munch.app/authenticate")!
                    components.queryItems = [
                        URLQueryItem(name: "token", value: token),
                        URLQueryItem(name: "redirect", value: "/places/suggest?placeId=\(place.placeId)"),
                    ]

                    let safari = SFSafariViewController(url: components.url!)
                    safari.delegate = delegate
                    MunchAnalytic.logEvent("rip_click_suggest_edit")
                    controller.present(safari, animated: true, completion: nil)

                case let .error(error):
                    controller.alert(error: error)
                }
            }
        }
    }
}