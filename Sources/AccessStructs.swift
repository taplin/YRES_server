//
//  AccessStructs.swift
//  YRES_server
//
//  Created by Tim Taplin on 11/12/16.
//
//
import MySQL
import PerfectLib
import Foundation

struct DataAccess {
    
    var baseURL:String = "127.0.0.1"
    
    var user = "test"
    var pass = "test"
    var db_name = "yres_data"
    
    static let sharedInstance: DataAccess = DataAccess()
    
    private init() {
        do {
            let tmpfile = File("config/yresserver.conf")
            let jsonEnv = try tmpfile.readString()
            
            //load data access variables from json file
            //Log.info(message: "datastring: \(jsonEnv)")
            do {
                let configraw:[String:String] = try jsonEnv.jsonDecode() as! [String : String]
                baseURL = configraw["baseUrl"]!
                user = configraw["user"]!
                pass = configraw["pass"]!
                db_name = configraw["db_name"]!
            } catch {
                Log.error(message: "decode config failed")
            }
        } catch {
            Log.error(message: "read conf failed")
        }
    }
}

protocol PerfectObject {
    func jsonEncodedString() throws -> String
    func toDictionary() -> Dictionary<String, Any>
    
}

enum MysqlError : Error {
    case select(UInt32)
    case insert(UInt32)
    case update(UInt32)
    case delete(UInt32)
    case createTable(UInt32)
}

protocol mysqlDBObject {
    var db: MySQL! { get set }
    
    init(db: MySQL)
    
}

extension mysqlDBObject {
    
    init(db:MySQL){
        self.init(db: db)
        self.db = db
    }
}

extension PerfectObject {
    
    func toDictionary() -> Dictionary<String, Any> {
        var dict =  Dictionary<String, Any>()
        
        return dict
    }
    public func jsonEncodedString() throws -> String {
        
        return try self.toDictionary().jsonEncodedString()
    }
}

public struct YRESCategory:PerfectObject, JSONConvertible {
    public var id:String, label:String, name:String, slogan:String, icon:String, sort:Int
    
    init(usingRow row: [String], withFields fields: [String]){
        //var custDict:Dictionary<String, Any> = [:]
        
        id = row[fields.index(of:"id")!]
        label = row[fields.index(of:"label")!]
        name = row[fields.index(of:"name")!]
        slogan = row[fields.index(of:"slogan")!]
        icon = row[fields.index(of:"icon")!]
        sort = Int(row[fields.index(of:"sort")!])!
    }
    
    func toDictionary() -> [String:Any] {
        var dict = [String:Any]()
        dict["id"] = id
        dict["label"] = label
        dict["name"] = name
        dict["slogan"] = slogan
        dict["icon"] = icon
        dict["sort"] = sort
        
        //Log.info(message: "Category Dictionary: \(dict)")
        return dict
    }
    
    
}

public struct YRESResource:PerfectObject, JSONConvertible {
    
    public var id:String
    public var name:String
    public var blurb:String
    public var icon:String = ""
    public var primary_link:String
    public var display_categories:[[String:Any]] {
        let apiAccess = DataAccess.sharedInstance
        var tmpid = ""
        if id == "new" {
            tmpid = "0"
        } else {
            tmpid = id
        }
        let displayCat_sql = "select c.label, c.name, c.id, (select id from res_cat_join j where j.cat_id = c.id and j.resource_id = \(tmpid)) as selected from category c"
        var findStatus = true
        var db = MySQL()
        
        findStatus = db.connect(host: apiAccess.baseURL, user: apiAccess.user, password: apiAccess.pass, db: apiAccess.db_name)
        
        defer {
            db.close()  // defer ensures we close our db connection at the end of this request
        }
        let queryResult = db.query(statement: displayCat_sql)
        
        var category_map = [[String:Any]]()
        
        if let results = db.storeResults() {
            while let row = results.next() {
                let category_line:[String:Any] = ["label":row[0]!, "name":row[1]!, "selected":(row[3] != nil), "id":row[2]!]
                
                category_map.append(category_line)
                
            }
            results.close()
        }
        return category_map
        
    }
    
    init(usingRow row: [String?], withFields fields: [String]){
        //var custDict:Dictionary<String, Any> = [:]
        
        id = row[fields.index(of:"id")!]!
        name = (row[fields.index(of:"name")!] != nil) ? row[fields.index(of:"name")!]! : ""
        blurb = (row[fields.index(of:"blurb")!] != nil) ? row[fields.index(of:"blurb")!]! : ""
        blurb = blurb.stringByReplacing(string: "<br>", withString: "")
        
        if let tmpicon = row[fields.index(of:"icon")!] {
            icon = tmpicon
        }
        primary_link = row[fields.index(of:"primary_link")!]!
        
    }
    
    init(usingDict dict:[String:String]) {
        id = dict["id"]!
        name = dict["name"]!
        blurb = dict["blurb"]!
        icon = dict["icon"]!
        primary_link = dict["primary_link"]!
        
    }
    
    // MARK: NSCoding
    /*
    public init(tmpid:String, tmpname:String, tmpblurb:String, tmpicon:String, tmpprimary_link:String) {
        id = tmpid
        name = tmpname
        blurb = tmpblurb
        icon = tmpicon
        primary_link = tmpprimary_link
        
    }
    
    required public convenience init(coder decoder: NSCoder) {
        let tmpid = decoder.decodeObject(forKey: "id") as! String
        let tmpname = decoder.decodeObject(forKey: "name") as! String
        let tmpblurb = decoder.decodeObject(forKey: "blurb") as! String
        var tmpicon:String = ""
        if let anicon = decoder.decodeObject(forKey: "icon") as? String {
            tmpicon = anicon
        }
        let tmpprimary_link = decoder.decodeObject(forKey: "primary_link") as! String

        self.init(tmpid:tmpid, tmpname:tmpname, tmpblurb:tmpblurb, tmpicon:tmpicon, tmpprimary_link:tmpprimary_link)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.id, forKey: "id")
        aCoder.encode(self.name, forKey: "name")
        aCoder.encode(self.blurb, forKey: "blurb")
        aCoder.encode(self.icon, forKey: "icon")
        aCoder.encode(self.primary_link, forKey: "primary_link")
    }
    */
    func toDictionary() -> [String:Any] {
        var dict = [String:Any]()
        dict["id"] = id
        dict["name"] = name
        dict["blurb"] = blurb
        dict["icon"] = icon
        dict["primary_link"] = primary_link
        if display_categories.count > 0 {
            dict["display_categories"] = display_categories
        }
        //Log.info(message: "Category Dictionary: \(dict)")
        return dict
    }
    
    func save() -> Bool {
        let apiAccess = DataAccess.sharedInstance
        var update_sql = ""
        var findStatus = true
        var db = MySQL()
        
        findStatus = db.connect(host: apiAccess.baseURL, user: apiAccess.user, password: apiAccess.pass, db: apiAccess.db_name)
        
        defer {
            db.close()  // defer ensures we close our db connection at the end of this request
        }
        
        if id == "new" {
            //update_sql = "insert into resource set name= '\(name)', blurb= '\(blurb)', icon= '\(icon)', primary_link= '\(primary_link)'"
            do {
                _ = try self.insert(db)
                return true
            } catch {
                Log.error(message: "resource insert failed with \(error)")
                return false
            }
        } else {
            //update_sql = "update resource set name= '\(name)', blurb= '\(blurb)', icon= '\(icon)', primary_link= '\(primary_link)' where id = \(id)"
            update_sql = "update resource set name= ?, blurb= ?, icon= ?, primary_link= ? where id = ?"
            let fieldvalues = [name, blurb, icon, primary_link, id]
            let statement = MySQLStmt(db)
            defer {
                statement.close()
            }
            do {
                let prepRes = statement.prepare(statement: update_sql)
                if(prepRes){
                    
                    fieldvalues.forEach({(field) in
                        
                        if(field != nil){
                            _ = statement.bindParam(field )
                        } else {
                            _ = statement.bindParam()
                        }
                    })
                    
                    let execRes = statement.execute()
                    if(execRes){
                        //entity.id = Int(statement.insertId()) ;
                        Log.info(message: " statement affected \(statement.affectedRows())")
                    }else{
                        Log.error(message: "\(statement.errorCode()) \(statement.errorMessage()) - \(db.errorCode()) \(db.errorMessage())")
                        let errorCode = db.errorCode()
                        if errorCode > 0 {
                            throw MysqlError.insert(errorCode)
                        }
                    }
                    return execRes
                }
            } catch {
                Log.error(message: "resource update failed with \(error)")
                return false
            }
            /*
            Log.info(message: "update sql: \(update_sql)")
            let update = db.query(statement: update_sql)
            return update
             */
        }
        return false
        
    }
    
    func insert(_ db:MySQL) throws -> Int {
        
       	let sql = "INSERT INTO resource (`name`, `blurb`, `icon`, `primary_link`) VALUES (?, ?, ?, ?);"
       	let statement = MySQLStmt(db)
        defer {
            statement.close()
        }
        let customer_fields:Array<Any> =
            [
                name,
                blurb,
                icon,
                primary_link
        ]
        let prepRes = statement.prepare(statement: sql)
        if(prepRes){
            
            customer_fields.forEach({(field) in
                
                if((field as! String) != ""){
                    _ = statement.bindParam(field as! String)
                } else {
                    _ = statement.bindParam()
                }
            })
            
            
            let execRes = statement.execute()
            if(execRes){
                //entity.id = Int(statement.insertId()) ;
                return Int(statement.insertId())
            }else{
                Log.error(message: "\(statement.errorCode()) \(statement.errorMessage()) - \(db.errorCode()) \(db.errorMessage())")
                let errorCode = db.errorCode()
                if errorCode > 0 {
                    throw MysqlError.insert(errorCode)
                }
            }
            
            statement.close()
        }
        return 0
    }
}
