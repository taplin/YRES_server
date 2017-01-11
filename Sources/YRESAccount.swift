//
//  ExampleAccount.swift
//  PerfectAuth
//
//  Created by Edward Jiang on 10/17/16.
//
//

import Foundation
import Turnstile
import TurnstileCrypto

public struct YRESAccount: Account {
    public var uniqueID: String
    public var username: String?
    public var password: String?
    public var apiKeySecret: String = URandom().secureToken
    
    init(id: String) {
        uniqueID = id
    }
    
    init(usingRow row: [String]) {
        uniqueID = row[0]
        username = row[1]
        password = row[2]
        apiKeySecret = row[4]
        
    }
    
    var dict: [String: String] {
        return [ "id": uniqueID,
                 "username": username ?? "",
                 "password": password ?? "",
                 "api_key_id": uniqueID,
                 "api_key_secret": apiKeySecret
        ]
    }
    
    var json: String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
            let result = String(data: jsonData, encoding: .utf8) {
            return result
        }
        return ""
        
    }
}
