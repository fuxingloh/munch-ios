//
// Created by Fuxing Loh on 12/11/17.
// Copyright (c) 2017 Munch Technologies. All rights reserved.
//

import Foundation

import RealmSwift
import SwiftyJSON


class RecentSearchQueryDatabase: RecentDataDatabase<SearchQuery> {
    init() {
        super.init(type: SearchQuery.self, name: "SearchQuery+\(SearchQuery.version)", maxSize: 10)
    }
}

class RecentPlaceDatabase: RecentDataDatabase<Place> {
    init() {
        super.init(type: Place.self, name: "RecentPlaceDatabase", maxSize: 20)
    }
}

class RecentData: Object {
    @objc dynamic var _name: String = ""
    @objc dynamic var _date = Date.currentMillis


    @objc dynamic var id: String = ""
    @objc dynamic var data: Data?
}

class RecentDataDatabase<T> where T: Codable {
    private let type: T.Type
    private let name: String
    private let maxSize: Int

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    /*
     * type: Type for Codable
     * name: name of database
     * maxSize: max size of number of data to store in database
     */
    init(type: T.Type, name: String, maxSize: Int) {
        self.type = type
        self.name = name
        self.maxSize = maxSize
    }

    func add(id: String, data: T) {
        let encoded = try? encoder.encode(data)

        let realm = try! Realm()
        if let exist = realm.objects(RecentData.self)
                .filter("_name == '\(name)' AND id == '\(id)'").first {
            try! realm.write {
                exist._date = Date.currentMillis
                exist.data = encoded
            }
        } else {
            try! realm.write {
                let recent = RecentData()
                recent._name = name
                recent.id = id
                recent.data = encoded

                realm.add(recent)
                self.deleteLimit(realm: realm)
            }
        }
    }

    func list() -> [T] {
        let realm = try! Realm()
        let dataList = realm.objects(RecentData.self)
                .filter("_name == '\(name)'")
                .sorted(byKeyPath: "_date", ascending: false)

        var list = [T]()
        for recent in dataList {
            if let data = recent.data, let decoded = try? decoder.decode(type, from: data) {
                list.append(decoded)
            }

            // If hit max items, auto return
            if (list.count >= maxSize) {
                return list
            }
        }
        return list
    }

    private func deleteLimit(realm: Realm = try! Realm()) {
        let saved = realm.objects(RecentData.self)
                .filter("_name == '\(name)'")
                .sorted(byKeyPath: "_date", ascending: false)

        // Delete if more then maxItems
        if (saved.count > maxSize) {
            for (index, element) in saved.enumerated() {
                if (index > maxSize) {
                    realm.delete(element)
                }
            }
        }
    }
}