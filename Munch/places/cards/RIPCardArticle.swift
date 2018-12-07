//
// Created by Fuxing Loh on 2018-12-06.
// Copyright (c) 2018 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class RIPArticleCard: RIPCard {
    private static let height: CGFloat = 354

    private let label = UILabel(style: .h2)
    private let separatorLine = RIPSeparatorLine()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 24 * 3, height: RIPArticleCard.height)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 24

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.backgroundColor = .white
        return collectionView
    }()

    private var articles: [Article]!

    override func didLoad(data: PlaceData!) {
        self.addSubview(label)
        self.addSubview(separatorLine)
        self.addSubview(collectionView)

        self.articles = data.articles
        self.registerCells(collectionView: self.collectionView)

        label.with(text: "\(data.place.name) Articles")
        label.snp.makeConstraints { maker in
            maker.left.right.equalTo(self).inset(24)
            maker.top.equalTo(self).inset(12)
        }

        collectionView.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)
            maker.top.equalTo(label.snp.bottom).inset(-24)
            maker.height.equalTo(RIPArticleCard.height).priority(.high)
        }

        separatorLine.snp.makeConstraints { maker in
            maker.left.right.equalTo(self)

            maker.top.equalTo(collectionView.snp.bottom).inset(-48)
            maker.bottom.equalTo(self).inset(12)
        }
    }

    override class func isAvailable(data: PlaceData) -> Bool {
        return !data.articles.isEmpty
    }
}


extension RIPArticleCard: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func registerCells(collectionView: UICollectionView) {
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(type: RIPArticleCardCell.self)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(type: RIPArticleCardCell.self, for: indexPath)
        cell.render(with: articles[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }
}

fileprivate class RIPArticleCardCell: UICollectionViewCell {
    private let imageView: SizeShimmerImageView = {
        let imageView = SizeShimmerImageView(points: UIScreen.main.bounds.width - 48 - 24, height: 128)
        imageView.roundCorners([.topLeft, .topRight], radius: 3)
        return imageView
    }()
    private let titleLabel = UILabel(style: .h5)
            .with(numberOfLines: 2)
    private let descriptionLabel = UILabel(style: .subtext)
            .with(numberOfLines: 4)

    private let brand = UILabel(style: .h6)
            .with(color: .secondary700)
            .with(numberOfLines: 1)
    private let date = UILabel(style: .subtext)
            .with(numberOfLines: 1)

    private let moreBtn = MunchButton(style: .borderSmall)
            .with(text: "Read More")

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        let container = UIView()
        container.layer.cornerRadius = 3
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.ba10.cgColor
        self.addSubview(container)

        container.addSubview(imageView)
        container.addSubview(titleLabel)
        container.addSubview(descriptionLabel)

        let bottom = UIView()
        let domain = UIView()
        domain.addSubview(brand)
        domain.addSubview(date)
        bottom.addSubview(moreBtn)
        bottom.addSubview(domain)
        container.addSubview(bottom)

        container.snp.makeConstraints { maker in
            maker.top.left.right.equalTo(self)

            imageView.snp.makeConstraints { maker in
                maker.top.left.right.equalTo(container)
                maker.height.equalTo(128).priority(999)
            }

            titleLabel.snp.makeConstraints { maker in
                maker.left.right.equalTo(container).inset(20)
                maker.top.equalTo(imageView.snp.bottom).inset(-16).priority(.high)
            }

            descriptionLabel.snp.makeConstraints { maker in
                maker.left.right.equalTo(container).inset(20)
                maker.top.equalTo(titleLabel.snp.bottom).inset(-16).priority(.high)
                maker.bottom.equalTo(bottom.snp.top).inset(-24).priority(.low)
            }
        }

        bottom.snp.makeConstraints { maker in
            maker.left.right.equalTo(container).inset(20)
            maker.height.equalTo(40).priority(999)
            maker.bottom.equalTo(container).inset(16).priority(.high)

            domain.snp.makeConstraints { maker in
                maker.left.centerY.equalTo(bottom)
                maker.right.lessThanOrEqualTo(moreBtn.snp.left).inset(-16)

                brand.snp.makeConstraints { maker in
                    maker.left.top.equalTo(domain)
                    maker.bottom.equalTo(date.snp.top)
                }

                date.snp.makeConstraints { maker in
                    maker.left.right.bottom.equalTo(domain)
                }
            }

            moreBtn.snp.makeConstraints { maker in
                maker.right.centerY.equalTo(bottom)
            }
        }
    }

    func render(with article: Article) {
        self.imageView.render(image: article.thumbnail)
        self.titleLabel.with(text: article.title, lineSpacing: 1.3)
        self.descriptionLabel.with(text: article.description, lineSpacing: 1.5)
        self.brand.with(text: article.domain.name, lineSpacing: 1.3)
        self.date.text = article.createdMillis?.asMonthDayYear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}