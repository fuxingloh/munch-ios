//
//  RestfulClient.swift
//  Munch
//
//  Created by Fuxing Loh on 23/3/17.
//  Copyright © 2017 Munch Technologies. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
import SwiftyJSON

public class RestfulClient {
    public static var lastLatLng: String?
    
    private let url: String
    private let version: String
    private let build: String
    
    init(_ url: String) {
        self.url = url
        self.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        self.build = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
    }
    
    /**
     Params Encoding is query string
     */
    fileprivate func get(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .get, path: path, parameters: parameters, encoding: URLEncoding.default, callback: callback)
    }
    
    /**
     Params Encoding is json
     */
    fileprivate func post(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .post, path: path, parameters: parameters, encoding: JSONEncoding.default, callback: callback)
    }
    
    /**
     method: HttpMethod
     path: After domain
     paramters: json or query string both supported
     encoding: encoding of paramters
     callback: Meta and Json
     */
    fileprivate func request(method: HTTPMethod, path: String, parameters: Parameters, encoding: ParameterEncoding, callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        var headers = [String: String]()
        headers["Application-Version"] = version
        headers["Application-Build"] = build
        
        // Always set latLng if available, only to get from header for logging, debugging purpose only
        // Otherwise, use the explicit value declared
        if let latLng = MunchLocation.getLatLng() {
            headers["Location-LatLng"] = latLng
        }
        
        Alamofire.request(url + path, method: method, parameters: parameters, encoding: encoding, headers: headers)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    callback(MetaJSON(metaJson: json["meta"]), json)
                case .failure(let error):
                    // TODO error handling
                    // - Offline
                    // - Timeout
                    print(error)
                }
        }
    }
}

/**
 Meta Json in response
 {meta: {}}
 */
public struct MetaJSON {
    public let code: Int!
    public let error: Error?
    
    public struct Error {
        public let type: String?
        public let message: String?
        
        public init(errorJson: JSON){
            self.type = errorJson["type"].string
            self.message = errorJson["message"].string
        }
    }
    
    public init(metaJson: JSON){
        self.code = metaJson["code"].intValue
        if metaJson["error"].exists() {
            self.error = Error(errorJson: metaJson["error"])
        }else{
            self.error = nil
        }
    }
    
    /**
     Returns true if meta is successful
     */
    public func isOk() -> Bool {
        return code == 200
    }
    
    /**
     Create an UI Alert Controller with prefilled info to
     easily print error message as alert dialog
     */
    public func createAlert() -> UIAlertController {
        let type = error?.type ?? "Unknown Error"
        let message = error?.message ?? "An unknown error has occured."
        let alert = UIAlertController(title: type, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        return alert
    }
}

let MunchApi = MunchClient.instance

public class MunchClient: RestfulClient {
    public static let instance = MunchClient()
    
    private static let baseUrl = MunchPlist.get(asString: "MunchApiBaseUrl-Beta")!
    
    let discovery = DiscoveryClient(baseUrl)
    let places = PlaceClient(baseUrl)
    let locations = LocationClient(baseUrl)
    let cached = CachedSyncClient(baseUrl)
    
    private init() {
        super.init(MunchClient.baseUrl)
    }
}

/**
 DiscoveryClient from DiscoveryService in munch-core/munch-api
 */
class DiscoveryClient: RestfulClient {
    func suggest(text: String, size: Int, latLng: String? = nil, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
        var params = Parameters()
        params["text"] = text
        params["size"] = size
        params["latLng"] = latLng
        
        super.post("/discovery/suggest", parameters: params) { meta, json in
            callback(meta, SearchCollection.parseList(searchResult: json["data"]))
        }
    }
    
    func search(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ collections: [SearchCollection]) -> Void) {
        super.post("/discovery/search", parameters: query.toParams()) { meta, json in
            callback(meta, json["data"].map { SearchCollection(json: $0.1) })
        }
    }
    
    func searchNext(query: SearchQuery, callback: @escaping (_ meta: MetaJSON, _ results: [SearchResult]) -> Void) {
        super.post("/discovery/search/next", parameters: query.toParams()) { meta, json in
            callback(meta, SearchCollection.parseList(searchResult: json["data"]))
        }
    }
}

/**
 PlaceClient from PlaceService in munch-core/munch-api
 */
class PlaceClient: RestfulClient {
    func get(id: String, callback: @escaping (_ meta: MetaJSON, _ place: Place?) -> Void) {
        super.get("/places/\(id)") { meta, json in
            callback(meta, Place(json: json["data"]))
        }
    }
    
    func cards(id: String, callback: @escaping (_ meta: MetaJSON, _ cards: [PlaceCard]) -> Void) {
        super.get("/places/\(id)/cards") { meta, json in
            callback(meta, json["data"].map { PlaceCard(json: $0.1) })
        }
    }
}

/**
 LocationClient from LocationService in munch-core/munch-api
 that is direct proxy to LocationService in munch-core/service-location
 */
class LocationClient: RestfulClient {
    
    /**
     Find the location the user is currently at
     Different from reverse, is the location given here can be street based
     */
    func find(latLng: String?, callback: @escaping (_ meta: MetaJSON, _ location: Location?) -> Void) {
        var params = Parameters()
        params["latLng"] = latLng
        
        super.get("/location/find", parameters: params) { meta, json in
            callback(meta, Location(json: json["data"]))
        }
    }
    
    func reverse(lat: Double, lng: Double, callback: @escaping (_ meta: MetaJSON, _ location: Location?) -> Void) {
        super.get("/locations/reverse", parameters: ["latLng": "\(lat),\(lng)"]) { meta, json in
            callback(meta, Location(json: json["data"]))
        }
    }
    
    func suggest(text: String, callback: @escaping (_ meta: MetaJSON, _ locations: [Location]) -> Void) {
        super.get("/locations/suggest", parameters: ["text": text]) { meta, json in
            callback(meta, json["data"].map { Location(json: $0.1)! })
        }
    }
}

/**
 CachedSyncClient from CachedSyncService in munch-core/munch-api
 */
class CachedSyncClient: RestfulClient {
    
    func hashes(callback: @escaping (_ meta: MetaJSON, _ hashes: [String: String]) -> Void) {
        super.get("/cached/hashes") { meta, json in
            var hashes = [String: String]()
            for hash in json["data"] {
                hashes[hash.0] = hash.1.stringValue
            }
            callback(meta, hashes)
        }
    }
    
    func get(type: String, callback: @escaping (_ meta: MetaJSON, _ hash: String?, _ json: JSON) -> Void) {
        super.get("/cached/data/\(type)") { meta, json in
            let hash = json["data"]["hash"].string
            let data = json["data"]["data"]
            callback(meta, hash, data)
        }
    }
    
}

/**
 MetaClient from MetaService in munch-core/munch-api
 Used for facilitating alpha/beta testing
 */
class MetaClient: RestfulClient {
    
}

