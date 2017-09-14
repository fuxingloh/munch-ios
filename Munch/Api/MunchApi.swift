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

let MunchApi = MunchClient.instance

public class MunchClient: RestfulClient {
    public static let instance = MunchClient()
    
    private static let baseUrl = MunchPlist.get(asString: "MunchApiBaseUrl-Beta")!
    
    let search = SearchClient(baseUrl)
    let places = PlacesClient(baseUrl)
    let locations = LocationsClient(baseUrl)
    let cached = CachedSyncClient(baseUrl)
    
    private init() {
        super.init(MunchClient.baseUrl)
    }
}

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
    func get(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
        request(method: .get, path: path, parameters: parameters, encoding: URLEncoding.default, callback: callback)
    }
    
    /**
     Params Encoding is json
     */
    func post(_ path: String, parameters: Parameters = [:], callback: @escaping (_ meta: MetaJSON, _ json: JSON) -> Void) {
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
