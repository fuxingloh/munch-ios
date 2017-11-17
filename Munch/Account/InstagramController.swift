//
// Created by Fuxing Loh on 15/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation
import UIKit

import SnapKit
import Auth0
import Lock

class InstagramManageController: UIViewController, UIGestureRecognizerDelegate {
    private let headerView = HeaderView()
    private let tableView = UITableView()

    var userInfo: UserInfo! // User Main UserInfo
    var idToken: String! // User Main Id Token
    private var instagramAccountStatus = InstagramAccountStatus.loading

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Make navigation bar transparent, bar must be hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initViews()
        self.registerCell()

        self.headerView.backButton.addTarget(self, action: #selector(onBackButton(_:)), for: .touchUpInside)
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.checkInstagram()
    }

    /**
     Return true is instagram is connected
     */
    private func checkInstagram(credentialsManager: CredentialsManager = CredentialsManager(authentication: Auth0.authentication())) {
        credentialsManager.credentials { error, credentials in
            guard let idToken = credentials?.idToken else {
                return
            }

            self.idToken = idToken
            Auth0.users(token: idToken)
                    .get(self.userInfo.sub, fields: ["identities"], include: true)
                    .start { result in
                        switch result {
                        case .success(let userInfo):
                            let identities = userInfo["identities"] as! [[String: Any]]
                            let hasInstagram = identities.contains {
                                $0["connection"] as! String == "instagram"
                            }

                            DispatchQueue.main.async {
                                self.instagramAccountStatus = hasInstagram ? .connected : .notConnected
                                self.tableView.reloadData()
                            }
                        case .failure(let error):
                            self.alert(title: "Fetch Profile Error", error: error)
                        }
                    }
        }
    }

    func showInstagramLogin() {
        Lock.classic()
                .withConnections { connections in
                    connections.social(name: "instagram", style: .Instagram)
                }
                .withOptions {
                    $0.initialScreen = .signup
                    $0.closable = true
                    $0.oidcConformant = true
                    $0.scope = "openid profile email"

                }
                .withStyle {
                    $0.headerColor = .white
                    $0.headerCloseIcon = LazyImage(name: "Account-Close")
                    $0.title = "Munch Partner Network"
                    $0.logo = LazyImage(name: "AppIcon")
                    $0.primaryColor = .primary
                }
                .onAuth { instagramCredentials in
                    DispatchQueue.main.async {
                        self.instagramAccountStatus = .loading
                        self.tableView.reloadData()
                    }

                    Auth0.users(token: self.idToken)
                            .link(self.userInfo.sub, withOtherUserToken: instagramCredentials.idToken!)
                            .start { result in
                                switch result {
                                case .success:
                                    DispatchQueue.main.async {
                                        self.instagramAccountStatus = .connected
                                        self.tableView.reloadData()
                                    }
                                case .failure(let error):
                                    self.alert(title: "Instagram Account Link Failure", error: error)
                                }
                            }
                }.present(from: self)
    }

    private func initViews() {
        self.view.backgroundColor = .white
        self.view.addSubview(tableView)
        self.view.addSubview(headerView)

        headerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(64)
        }

        tableView.separatorStyle = .none
        tableView.separatorInset.left = 24
        tableView.allowsSelection = true
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = 40
        tableView.estimatedRowHeight = 50

        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.left.right.equalTo(self.view)
        }
    }

    @objc func onBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    private class HeaderView: UIView {
        let backButton = UIButton()
        let titleView = UILabel()

        override init(frame: CGRect = CGRect.zero) {
            super.init(frame: frame)
            self.initViews()
        }

        private func initViews() {
            self.backgroundColor = .white
            self.addSubview(titleView)
            self.addSubview(backButton)

            titleView.text = "Manage Instagram"
            titleView.font = .systemFont(ofSize: 17, weight: .regular)
            titleView.textAlignment = .center
            titleView.snp.makeConstraints { make in
                make.top.equalTo(self).inset(20)
                make.centerX.equalTo(self)
                make.bottom.equalTo(self)
            }

            backButton.setImage(UIImage(named: "Back-34"), for: .normal)
            backButton.tintColor = .black
            backButton.imageEdgeInsets.left = 15
            backButton.contentHorizontalAlignment = .left
            backButton.snp.makeConstraints { make in
                make.top.equalTo(self).inset(20)
                make.left.equalTo(self)
                make.bottom.equalTo(self)
                make.width.equalTo(64)
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            self.hairlineShadow(height: 1.0)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

fileprivate enum InstagramAccountStatus {
    case loading
    case connected
    case notConnected
}

fileprivate enum InstagramCellType {
    case loading
    case boarding
    case setting
}

extension InstagramManageController: UITableViewDataSource, UITableViewDelegate {
    func registerCell() {
        func register(cellClass: UITableViewCell.Type) {
            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }

        register(cellClass: AccountLoadingCell.self)
        register(cellClass: InstagramConnectCell.self)
        register(cellClass: InstagramAccountSettingCell.self)
    }

    private var items: [(String?, [InstagramCellType])] {
        switch self.instagramAccountStatus {
        case .loading:
            return [(nil, [InstagramCellType.loading])]
        case .connected:
            return [(nil, [InstagramCellType.setting])]
        case .notConnected:
            return [(nil, [InstagramCellType.boarding])]
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].1.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].0
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.tintColor = .white
        header.textLabel!.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        header.textLabel!.textColor = UIColor.black.withAlphaComponent(0.85)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func dequeue(cellClass: UITableViewCell.Type) -> UITableViewCell {
            let identifier = String(describing: cellClass)
            return tableView.dequeueReusableCell(withIdentifier: identifier)!
        }

        let item = items[indexPath.section].1[indexPath.row]

        switch item {
        case .loading:
            return dequeue(cellClass: AccountLoadingCell.self)
        case .boarding:
            return dequeue(cellClass: InstagramConnectCell.self)
        case .setting:
            return dequeue(cellClass: InstagramAccountSettingCell.self)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.section].1[indexPath.row]
        switch item {
        case .boarding:
            self.showInstagramLogin()
        default:
            return
        }
    }
}

class InstagramConnectCell: UITableViewCell {
    let appImageView = UIImageView()
    let titleView = UILabel()
    let continueButton = UIButton()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initViews()
    }

    private func initViews() {
        let boxView = UIView()
        addSubview(boxView)
        boxView.addSubview(appImageView)
        boxView.addSubview(titleView)
        boxView.addSubview(continueButton)

        boxView.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(24)
            make.left.right.equalTo(self).inset(24)
        }

        appImageView.image = UIImage(named: "AppIconLarge")
        appImageView.contentMode = .scaleAspectFit
        appImageView.clipsToBounds = true
        appImageView.snp.makeConstraints { make in
            make.left.right.equalTo(boxView)
            make.top.equalTo(boxView)
            make.height.equalTo(150)
        }

        titleView.text = "Some text for munch partner network on boarding."
        titleView.numberOfLines = 0
        titleView.textAlignment = .center
        titleView.snp.makeConstraints { make in
            make.left.right.equalTo(boxView)
            make.top.equalTo(appImageView.snp.bottom).inset(-16)
            make.bottom.equalTo(continueButton.snp.top).inset(-24)
        }

        continueButton.setTitle("Continue", for: .normal)
        continueButton.isEnabled = false
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = .primary
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        continueButton.layer.cornerRadius = 3
        continueButton.layer.borderWidth = 1.0
        continueButton.layer.borderColor = UIColor.primary.cgColor
        continueButton.snp.makeConstraints { make in
            make.left.right.equalTo(boxView)
            make.bottom.equalTo(boxView)
            make.height.equalTo(48)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class InstagramAccountSettingCell: UITableViewCell {
    let titleView = UILabel()
    let buttonView = UISwitch()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initViews()
    }

    private func initViews() {
        self.addSubview(titleView)
        self.addSubview(buttonView)

        titleView.text = "Allow Content"
        titleView.snp.makeConstraints { make in
            make.left.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(12)
            make.right.equalTo(buttonView.snp.left).inset(24)
        }

        buttonView.tintColor = .primary
        buttonView.setOn(true, animated: false)
        buttonView.snp.makeConstraints { make in
            make.right.equalTo(self).inset(24)
            make.top.bottom.equalTo(self).inset(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}