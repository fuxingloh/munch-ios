//
// Created by Fuxing Loh on 2018-12-01.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import SafariServices

import Localize_Swift

class RIPCardStatus: RIPCard, SFSafariViewControllerDelegate {
    private let container = ContainerWidget()
            .with(backgroundColor: .close)
            .with(cornerRadius: 3)

    private let titleLabel = UILabel()
            .with(style: .h3)
            .with(text: "Permanently Closed")
            .with(color: .white)

    private let messageLabel = UILabel()
            .with(style: .h6)
            .with(numberOfLines: 0)
            .with(color: .white)

    override func didLoad(data: PlaceData!) {
        let statusType = data.place.status.type

        self.addSubview(container) { (maker: ConstraintMaker) -> Void in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(8)
            maker.bottom.equalTo(self).inset(8)
        }

        titleLabel.text = statusType.title
        self.container.add(titleLabel) { (maker: ConstraintMaker) -> Void in
            maker.top.equalTo(container).inset(16)
            maker.left.right.equalTo(container).inset(24)
        }

        if let message = statusType.message {
            messageLabel.text = message + " Suggest an edit."
            self.container.add(messageLabel) { (maker: ConstraintMaker) -> Void in
                maker.left.right.equalTo(container).inset(24)
                maker.top.equalTo(titleLabel.snp.bottom).inset(-8)
                maker.bottom.equalTo(container).inset(16)
            }
        } else {
            titleLabel.snp.makeConstraints { maker in
                maker.bottom.equalTo(container).inset(16)
            }
        }

        self.layoutIfNeeded()
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return data.place.status.type != .open
    }

    override func didSelect(data: PlaceData!, controller: RIPController) {
        RIPSuggestEditCard.onSuggestEdit(place: data.place, controller: self.controller, delegate: self)
    }
}

class RIPNameTagCard: RIPCard {
    fileprivate let nameLabel = UILabel()
            .with(style: .h1)
            .with(numberOfLines: 0)
    fileprivate let locationLabel = UILabel()
            .with(style: .h6)
            .with(numberOfLines: 1)
    fileprivate var tagView: RIPTagCollection!
    private let separatorLine = RIPSeparatorLine()

    override func didLoad(data: PlaceData!) {
        self.nameLabel.text = data.place.name
        self.locationLabel.text = data.place.location.neighbourhood ?? data.place.location.street ?? data.place.location.address

        var tags = data.place.tags.filter({ (tag: Tag) in tag.type != .Timing })
        if tags.isEmpty {
            tags.append(Tag.restaurant)
        }
        self.tagView = RIPTagCollection(tags: tags.map({ $0.name }))

        self.addSubview(nameLabel)
        self.addSubview(locationLabel)
        self.addSubview(tagView)
        self.addSubview(separatorLine)

        nameLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(12)
            maker.height.equalTo(42 * nameLabel.countLines(width: UIScreen.main.bounds.width - 48)).priority(.high)
        }

        locationLabel.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(nameLabel.snp.bottom).inset(-4)
        }

        tagView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(locationLabel.snp.bottom).inset(-16)
        }

        separatorLine.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)

            maker.top.equalTo(tagView.snp.bottom).inset(-24)
            maker.bottom.equalTo(self).inset(12)
        }
    }
}

fileprivate class RIPTagCollection: UIView {
    fileprivate let tags: [String]
    fileprivate var collectionView: UICollectionView!

    required init(tags: [String]) {
        self.tags = Array(tags.prefix(6))
        super.init(frame: .zero)

        let layout = LeftAlignedLayout()
        layout.sectionInset = .zero
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(RIPTagCollectionCell.self, forCellWithReuseIdentifier: "RIPTagCollectionCell")
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = .zero
        collectionView.backgroundColor = backgroundColor

        self.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalTo(self)
            maker.height.equalTo(self.height(tags: self.tags)).priority(.high)
        }
    }

    private func height(tags: [String]) -> CGFloat {
        let workingWidth = UIScreen.main.bounds.width - 48

        var height: CGFloat = 0
        var currentRemaining: CGFloat = 0

        for tag in tags {
            let size = RIPTagCollectionCell.size(text: tag)
            if currentRemaining - size.width <= 0 {
                // Not Enough Space, New Line
                height += size.height
                height += 10
                currentRemaining = workingWidth - size.width - 10
            } else {
                currentRemaining = currentRemaining - size.width - 10
            }
        }

        return height - 10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RIPTagCollection: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return RIPTagCollectionCell.size(text: tags[indexPath.row])
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "RIPTagCollectionCell", for: indexPath) as! RIPTagCollectionCell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? RIPTagCollectionCell {
            cell.textLabel.text = tags[indexPath.row]
        }
    }
}

fileprivate class RIPTagCollectionCell: UICollectionViewCell {
    static let font = UIFont.systemFont(ofSize: 13.0, weight: .semibold)

    let textLabel: UILabel = {
        let label = UILabel()
                .with(font: font)
                .with(color: .ba80)
                .with(alignment: .center)
        label.backgroundColor = UIColor.whisper100
        label.layer.cornerRadius = 3
        label.clipsToBounds = true
        return label
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        self.addSubview(textLabel)
        self.backgroundColor = .clear

        textLabel.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    static func size(text: String) -> CGSize {
        return UILabel.textSize(font: font, text: text, extra: CGSize(width: 22, height: 13))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}