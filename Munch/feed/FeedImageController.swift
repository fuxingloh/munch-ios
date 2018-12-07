//
// Created by Fuxing Loh on 2018-12-04.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

import SwiftRichString
import SafariServices

class FeedImageController: UIViewController, UIGestureRecognizerDelegate {
    private let provider = MunchProvider<FeedImageService>()

    private let headerView = FeedImageHeaderView()
    private let footerView = FeedImageFooterView()

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        return stackView
    }()

    private let item: ImageFeedItem
    private let places: [Place]

    private var place: Place? {
        return places.get(0)
    }

    required init(item: ImageFeedItem, places: [Place]) {
        self.item = item
        self.places = places
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.view.addSubview(scrollView)
        self.view.addSubview(headerView)
        self.view.addSubview(footerView)

        self.scrollView.addSubview(self.stackView)

        self.addArrangedSubview()
        self.addTargets()

        headerView.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self.view)
        }

        footerView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
        }

        scrollView.snp.makeConstraints { maker in
            maker.top.equalTo(self.view)
            maker.left.right.equalTo(self.view)
            maker.bottom.equalTo(self.footerView.snp.top)
        }

        stackView.snp.makeConstraints { maker in
            maker.edges.equalTo(scrollView)
            maker.width.equalTo(scrollView.snp.width)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FeedImageController {
    func addArrangedSubview() {
        self.stackView.addArrangedSubview(FeedImage(item: self.item))
        self.stackView.addArrangedSubview(FeedContent(item: self.item))
        if let place = self.place {
            self.stackView.addArrangedSubview(FeedPlace(place: place))
        }
    }
}

// MARK: Add Targets
extension FeedImageController: SFSafariViewControllerDelegate {
    func addTargets() {
        self.scrollView.delegate = self

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)

        if let place = place {
            self.footerView.addButton.register(place: place, controller: self)
            self.headerView.titleView.text = place.name
        }

        if let contentView = self.stackView.arrangedSubviews[1] as? FeedContent {
            contentView.addTarget(self, action: #selector(onContent(_:)), for: .touchUpInside)
        }

        if let placeView = self.stackView.arrangedSubviews[2] as? FeedPlace {
            placeView.addTarget(self, action: #selector(onPlace(_:)), for: .touchUpInside)
        }
    }

    @objc func onContent(_ sender: Any) {
        if let link = self.item.instagram?.link, let url = URL(string: link) {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            present(safari, animated: true, completion: nil)
        }
    }

    @objc func onPlace(_ sender: Any) {
        if let place = self.places.get(0) {
            let controller = RIPController(placeId: place.placeId)
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    @objc func onBackButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: Scrolling
extension FeedImageController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationBackground(y: scrollView.contentOffset.y)
    }

    func updateNavigationBackground(y: CGFloat) {
        if (120 < y) {
            headerView.isOpaque = true
        } else {
            headerView.isOpaque = false
        }
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        let y = self.scrollView.contentOffset.y
        if (120 < y) {
            return .default
        } else {
            return .lightContent
        }
    }
}

class FeedImageHeaderView: UIView {
    let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "NavigationBar-Back"), for: .normal)
        button.tintColor = .white
        button.imageEdgeInsets.left = 18
        button.contentHorizontalAlignment = .left
        return button
    }()

    let titleView: UILabel = {
        let titleView = UILabel(style: .navHeader)
        return titleView
    }()
    let backgroundView = UIView()
    let shadowView = UIView()

    override var isOpaque: Bool {
        didSet {
            if isOpaque {
                self.backButton.tintColor = .black
                self.titleView.textColor = .black
                self.backgroundView.backgroundColor = .white
                self.shadowView.isHidden = false
            } else {
                self.titleView.textColor = .white
                self.backButton.tintColor = .white
                self.backgroundView.backgroundColor = .clear
                self.shadowView.isHidden = true
            }
        }
    }

    required init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(shadowView)
        self.addSubview(backgroundView)
        self.addSubview(backButton)
        self.addSubview(titleView)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(self.safeArea.top)
            make.left.bottom.equalTo(self)

            make.width.equalTo(52)
            make.height.equalTo(44)
        }

        titleView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(self.backButton)
            maker.left.equalTo(backButton.snp.right)
            maker.right.equalTo(self).inset(24)
        }

        backgroundView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        self.isOpaque = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.shadow(vertical: 2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FeedImageFooterView: UIView {
    let addButton = AddPlaceButton()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(addButton)

        addButton.snp.makeConstraints { maker in
            maker.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(10)
            maker.bottom.equalTo(self.safeArea.bottom).inset(10)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shadow(vertical: -1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FeedImage: UIView {
    let imageView: SizeImageView = {
        let imageView = SizeImageView(points: UIScreen.main.bounds.width, height: 1)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        return imageView
    }()

    init(item: ImageFeedItem) {
        super.init(frame: .zero)
        self.addSubview(imageView)


        imageView.render(image: item.image)
        imageView.snp.makeConstraints { maker in
            maker.edges.equalTo(self).priority(999)
            if let size = item.image.sizes.max {
                maker.height.equalTo(imageView.snp.width).multipliedBy(size.heightMultiplier)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FeedContent: UIControl {
    let topLine = SeparatorLine()
    let botLine = SeparatorLine()
    let caption = UILabel(style: .subtext)
            .with(numberOfLines: 2)
    let username = UILabel(style: .h5)
            .with(numberOfLines: 1)

    init(item: ImageFeedItem) {
        super.init(frame: .zero)
        self.addSubview(topLine)
        self.addSubview(botLine)
        self.addSubview(caption)
        self.addSubview(username)

        caption.text = item.instagram?.caption

        let mutable = NSMutableAttributedString()
        mutable.append(NSAttributedString(string: "by "))
        mutable.append((item.instagram?.username ?? "").set(style: Style {
            $0.color = UIColor.secondary700
        }))
        mutable.append(NSAttributedString(string: " on \(item.createdMillis.asMonthDayYear)"))
        username.attributedText = mutable

        topLine.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.top.equalTo(self)
        }

        caption.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(topLine.snp.bottom).inset(-24)
        }

        username.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(caption.snp.bottom).inset(-8)
            maker.bottom.equalTo(botLine.snp.top).inset(-24)
        }

        botLine.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.bottom.equalTo(self).inset(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class FeedPlace: UIControl {
    let label = UILabel(style: .h2)
            .with(text: "Place Mentioned")
    let placeCard = PlaceCard()

    init(place: Place) {
        super.init(frame: .zero)
        self.addSubview(label)
        self.addSubview(placeCard)

        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(8)
            maker.height.equalTo(32)
        }

        placeCard.place = place
        placeCard.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.bottom.equalTo(self).inset(120)
            maker.top.equalTo(label.snp.bottom).inset(-24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}