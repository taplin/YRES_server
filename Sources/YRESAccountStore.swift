//
//  ExampleAccountStore.swift
//  PerfectTemplate
//
//  Created by Edward Jiang on 10/14/16.
//
//

import MySQL
import PerfectLib

class YRESAccountStore {
    
    let apiAccess = DataAccess.sharedInstance
    var accounts = [YRESAccount]()
    
    init() {
        loadAccounts()
    }
    
    public func persistAccount(_ acct:YRESAccount) {
        let insert_sql = "INSERT INTO accounts(id, username, password, api_key_id, api_key_secret) VALUES('\(acct.uniqueID)', '\(acct.username!)', '\(acct.password!)', '\(acct.uniqueID)', '\(acct.apiKeySecret)') ON DUPLICATE KEY UPDATE id = '\(acct.uniqueID)', username = '\(acct.username!)', password = '\(acct.password!)', api_key_id = '\(acct.uniqueID)', api_key_secret = '\(acct.apiKeySecret)'"
        
        var findStatus = true
        var db = MySQL()
        
        findStatus = db.connect(host: apiAccess.baseURL, user: apiAccess.user, password: apiAccess.pass, db: apiAccess.db_name)
        
        defer {
            db.close()  // defer ensures we close our db connection at the end of this request
        }
        Log.info(message: "sql: \(insert_sql)")
        let queryResult = db.query(statement: insert_sql)
        
        //let results = db.storeResults()!
        Log.info(message: "insert account result: \(queryResult)")
        //results.close()
        
        Log.info(message: "account list: \(accounts.debugDescription)")
    }
    
    public func loadAccounts() {
        var findStatus = true
        var db = MySQL()
        
        findStatus = db.connect(host: apiAccess.baseURL, user: apiAccess.user, password: apiAccess.pass, db: apiAccess.db_name)
        
        defer {
            db.close()  // defer ensures we close our db connection at the end of this request
        }
        let sql = "select * from accounts"
        let queryResult = db.query(statement: sql)
        
        let results = db.storeResults()!
        
        while let row = results.next() {
            let account = YRESAccount(usingRow: row as! [String])
            
            accounts.append(account)
            
            //Log.error(message: row.debugDescription)
        }
        results.close()
        
    }
}
