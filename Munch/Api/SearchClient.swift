//
//  SearchClient.swift
//  Munch
//
//  Created by Fuxing Loh on 14/9/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

/**
 DiscoveryClient from DiscoveryService in munch-core/munch-api
 */
class SearchClient {
    func suggest(text: String, size: Int, latLng: String? = nil, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
        var params = Parameters()
        params["text"] = text
        params["size"] = size
        params["latLng"] = latLng

        MunchApi.restful.post("/search/suggest", parameters: params) { meta, json in
            callback(meta, json["data"].flatMap({ SearchClient.parseResult(result: $0.1) }))
        }
    }

    func search(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ results: [SearchCard]) -> Void) {
        MunchApi.restful.post("/search/search", parameters: query.toParams()) { meta, json in
            callback(meta, json["data"].map({ SearchCard(json: $0.1) }))
        }
    }

    func count(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ count: Int?) -> Void) {
        MunchApi.restful.post("/search/count", parameters: query.toParams()) { meta, json in
            callback(meta, json["data"].int)
        }
    }

    func priceRange(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ priceRangeInArea: PriceRangeInArea?) -> Void) {
        // TODO Actual logic
        let priceRangeInArea = PriceRangeInArea.init(avg: 25.0, min: 5, max: 65,
                cheapRange: .init(min: 5, max: 15),
                averageRange: .init(min: 15, max: 35),
                expensiveRange: .init(min: 35, max: 65)
        )
        callback(.init(metaJson: .init(["code", 200])), priceRangeInArea)
    }

    /**
     Method to parse search result type
     */
    public static func parseResult(result json: JSON?) -> SearchResult? {
        if let json = json {
            switch json["dataType"].stringValue {
            case "Tag": return Tag(json: json)
            case "Place": return Place(json: json)
            case "Location": return Location(json: json)
            case "Container": return Container(json: json)
            default: return nil
            }
        }
        return nil
    }
}

struct PriceRangeInArea {
    var avg: Double
    var min: Double
    var max: Double

    var cheapRange: PriceRange
    var averageRange: PriceRange
    var expensiveRange: PriceRange

    struct PriceRange {
        var min: Double
        var max: Double
    }
}

/**
 Possible types are:
 - Place
 - Location
 - Tag
 */
protocol SearchResult {
}

/**
 Tag object from munch-core/munch-data
 */
struct Tag: SearchResult {
    var id: String?
    var name: String?

    init(json: JSON) {
        self.id = json["id"].string
        self.name = json["name"].string
    }

    func toParams() -> Parameters {
        var params = Parameters()
        params["id"] = id
        params["name"] = name
        params["dataType"] = "Tag"
        return params
    }
}

struct Container: SearchResult, Equatable {
    var id: String?
    var type: String?
    var name: String?

    var images: [SourcedImage]?
    var ranking: Double

    init(json: JSON) {
        self.id = json["id"].string
        self.type = json["type"].string
        self.name = json["name"].string

        self.images = json["images"].map({ SourcedImage(json: $0.1) })
        self.ranking = json["ranking"].double ?? 0

    }

    func toParams() -> Parameters {
        var params = Parameters()
        params["id"] = id
        params["type"] = type
        params["name"] = name
        params["dataType"] = "Container"
        return params
    }

    static func ==(lhs: Container, rhs: Container) -> Bool {
        return lhs.id == rhs.id
    }
}

/**
 SearchQuery object from munch-core/service-places
 This is a input and output data
 */
struct SearchQuery: Equatable {
    var from: Int? = 0
    var size: Int? = 20

    var query: String?
    var latLng: String?
    var radius: Double?

    var filter: Filter
    var sort: Sort

    init() {
        filter = Filter()
        sort = Sort()
    }

    init(json: JSON) {
        self.from = json["from"].int
        self.size = json["size"].int

        self.query = json["query"].string
        self.latLng = json["latLng"].string
        self.radius = json["radius"].double

        self.filter = Filter(json: json["filter"])
        self.sort = Sort(json: json["sort"])
    }

    struct Filter {
        var price = Price()
        var tag = Tag()
        var hour = Hour()
        var location: Location?
        var containers: [Container]?

        init() {

        }

        init(json: JSON) {
            price.name = json["price"]["name"].string
            price.min = json["price"]["min"].double
            price.max = json["price"]["max"].double

            tag.positives = Set(json["tag"]["positives"].arrayValue.map({ $0.stringValue }))

            hour.name = json["hour"]["name"].string
            hour.day = json["hour"]["day"].string
            hour.open = json["hour"]["open"].string
            hour.close = json["hour"]["close"].string

            location = Location(json: json["location"])
            containers = json["containers"].map({ Container(json: $0.1) })
        }

        struct Price {
            var name: String?
            var min: Double?
            var max: Double?
        }

        struct Tag {
            var positives = Set<String>()
        }

        struct Hour {
            var name: String?

            var day: String?
            var open: String?
            var close: String?
        }

        func toParams() -> Parameters {
            var params = Parameters()
            params["price"] = ["name": price.name, "min": price.min, "max": price.max]
            params["tag"] = ["positives": Array(tag.positives)]
            params["hour"] = ["name": hour.name, "day": hour.day, "open": hour.open, "close": hour.close]
            params["location"] = location?.toParams()
            params["containers"] = containers?.map({ $0.toParams() })
            return params
        }
    }

    struct Sort {
        // See MunchCore for the available sort methods
        var type: String?

        init() {

        }

        init(json: JSON) {
            type = json["sort"]["type"].string
        }

        func toParams() -> Parameters {
            var params = Parameters()
            params["type"] = type
            return params
        }
    }

    /**
     Map to Alamofire supported parameters encoding
     */
    func toParams() -> Parameters {
        var params = Parameters()
        params["from"] = from
        params["size"] = size

        params["query"] = query
        params["latLng"] = latLng
        params["radius"] = radius

        params["filter"] = filter.toParams()
        params["sort"] = sort.toParams()
        return params
    }

    static func ==(lhs: SearchQuery, rhs: SearchQuery) -> Bool {
        guard (lhs.query == rhs.query) else {
            return false
        }

        guard (NSDictionary(dictionary: lhs.filter.toParams()).isEqual(to: rhs.filter.toParams())) else {
            return false
        }

        guard (NSDictionary(dictionary: lhs.sort.toParams()).isEqual(to: rhs.sort.toParams())) else {
            return false
        }
        return true
    }
}

/**
 Search typed Cards
 Access json through the subscript
 */
struct SearchCard: Equatable {
    var cardId: String
    var uniqueId: String?
    private var json: JSON

    init(cardId: String) {
        self.cardId = cardId
        self.json = JSON(parseJSON: "{}")
    }

    init(json: JSON) {
        self.cardId = json["_cardId"].stringValue
        self.uniqueId = json["_uniqueId"].string
        self.json = json
    }

    /**
     Subscript to get data from json with its name
     */
    subscript(name: String) -> JSON {
        return json[name]
    }

    static func ==(lhs: SearchCard, rhs: SearchCard) -> Bool {
        return lhs.cardId == rhs.cardId && lhs.uniqueId == rhs.uniqueId
    }
}
