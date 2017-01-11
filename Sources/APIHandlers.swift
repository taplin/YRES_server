//
//  APIHandlers.swift
//  YRES_server
//
//  Created by Tim Taplin on 11/12/16.
//
//
import PerfectLib
import Foundation

import MySQL

import TurnstilePerfect
import Turnstile
import TurnstileCrypto
import TurnstileWeb

public class yresApi {
    
    static let sharedInstance = yresApi()
    let apiAccess = DataAccess.sharedInstance
    let categoryFields = ["id", "label", "name", "slogan", "icon", "sort"]
    let resourceFields = ["id", "name", "blurb", "icon", "primary_link"]

    public func categoriesJson() -> [YRESCategory] {
        var findStatus = true
        var db = MySQL()
        
        findStatus = db.connect(host: apiAccess.baseURL, user: apiAccess.user, password: apiAccess.pass, db: apiAccess.db_name)
        
        defer {
            db.close()  // defer ensures we close our db connection at the end of this request
        }
        
        var sql:String = "SELECT "

        categoryFields.forEach({ (fieldname) in
            
            sql.append(fieldname)
            if(categoryFields.index(of: fieldname)! < (categoryFields.count - 1)){
                sql.append(", ")
            }
        })
        
        sql.append(" from category")

        Log.info(message:" retrieve Category: \(sql)")
        let queryResult = db.query(statement: sql)
        
        let results = db.storeResults()!
        
        var categories = [YRESCategory]()
        while let row = results.next() {
            let category = YRESCategory(usingRow: row as! [String], withFields: categoryFields)
            
            categories.append(category)
            
            //Log.error(message: row.debugDescription)
        }
        results.close()
        do {
            //let categoriesJson = try categories.jsonEncodedString()
            return categories
        } catch {
            Log.error(message: "error: \(error)")
            return categories
        }
        
    }

    public func resourcesList() -> [YRESResource] {
        var findStatus = true
        var db = MySQL()
        
        findStatus = db.connect(host: apiAccess.baseURL, user: apiAccess.user, password: apiAccess.pass, db: apiAccess.db_name)
        
        defer {
            db.close()  // defer ensures we close our db connection at the end of this request
        }
        
        var sql:String = "SELECT "
        
        resourceFields.forEach({ (fieldname) in
            
            sql.append(fieldname)
            if(resourceFields.index(of: fieldname)! < (resourceFields.count - 1)){
                sql.append(", ")
            }
        })
        
        sql.append(" from resource order by name")
        
        Log.info(message:" retrieve Resources: \(sql)")
        _ = db.query(statement: sql)
        
        let results = db.storeResults()!
        
        var resources = [YRESResource]()
        Log.info(message: "found count: \(results.numRows())")
        while let row = results.next() {
            let resource = YRESResource(usingRow: row, withFields: resourceFields)
            //Log.info(message: "row: \(row)")
            resources.append(resource)
            
        }
        results.close()
        
        return resources
        
        
    }
    
    func getResource(withId id:String) -> YRESResource? {
        var findStatus = true
        var db = MySQL()
        
        findStatus = db.connect(host: apiAccess.baseURL, user: apiAccess.user, password: apiAccess.pass, db: apiAccess.db_name)
        
        defer {
            db.close()  // defer ensures we close our db connection at the end of this request
        }
        
        var sql:String = "SELECT "
        
        resourceFields.forEach({ (fieldname) in
            
            sql.append(fieldname)
            if(resourceFields.index(of: fieldname)! < (resourceFields.count - 1)){
                sql.append(", ")
            }
        })
        
        sql.append(" from resource where id = \(id) order by name")
        
        Log.info(message:" retrieve Resource: \(sql)")
        let queryResult = db.query(statement: sql)
        
        let results = db.storeResults()!
        
        //var resources = [YRESResource]()
        guard results.numRows() > 0 else {
            Log.error(message: "YRESResource retrieval error")
            return nil
        }
        let the_row = results.next()!
        Log.info(message:"row contents: \(the_row)")
        let resource = YRESResource(usingRow: the_row as! [String?], withFields: resourceFields)
        
        results.close()
        return resource
        
    }
    
    public func getReferences() -> [String:String] {
        var findStatus = true
        var db = MySQL()
        
        findStatus = db.connect(host: apiAccess.baseURL, user: apiAccess.user, password: apiAccess.pass, db: apiAccess.db_name)
        
        defer {
            db.close()  // defer ensures we close our db connection at the end of this request
        }
        
        var sql:String = "SELECT ref_id, link "
        
        
        sql.append(" from reference")
        
        Log.info(message:" retrieve links: \(sql)")
        let queryResult = db.query(statement: sql)
        
        let results = db.storeResults()!
        
        var references = [String:String]()
        Log.info(message: "ref found count: \(results.numRows())")
        while let row = results.next() {
            //let resource = YRESResource(usingRow: row as! [String?], withFields: resourceFields)
            
            references[row[0]!] = row[1]!
            
        }
        results.close()
        do {
            //Log.info(message:" current references Dictionary: \(references)")
            return references
        } catch {
            Log.error(message: "error: \(error)")
            return references
        }
        
    }
    
    func getCategoryMap() -> [[String:String]] {
        var findStatus = true
        var db = MySQL()
        
        findStatus = db.connect(host: apiAccess.baseURL, user: apiAccess.user, password: apiAccess.pass, db: apiAccess.db_name)
        
        defer {
            db.close()  // defer ensures we close our db connection at the end of this request
        }
        
        var sql:String = "select resource_id, cat_id from res_cat_join "
        Log.info(message:" retrieve Category join: \(sql)")
        let queryResult = db.query(statement: sql)
        
        let results = db.storeResults()!
        var category_map = [[String:String]]()
        
        while let row = results.next() {
            let category_line = ["resource_id":row[0]!, "cat_id":row[1]!]
            
            category_map.append(category_line)
            
        }
        results.close()
        return category_map
    }
    /*
    public func setDisplayCategories(forResource resource:YRESResource) -> YRESResource {
        
        var tmpresource:YRESResource = resource
        
        let category_map = getCategoryMap()
        
        let categories = categoriesJson()
        
        let matches = category_map.filter({ $0["resource_id"]! == resource.id })
        
        let labels:[String] = matches.map({
            let localid = $0["cat_id"]!
            if localid == "9" {
                return "find_events"
            } else {
                let categorymatch = categories.filter({$0.id == localid})
                let thiscategory = categorymatch[0].name
                return thiscategory
            }
            
        })
        tmpresource.display_categories = labels
        
        return tmpresource
    }
    */
    func getFileURL(fileName: String) -> URL? {
        do {
            let manager = FileManager.default
            let dirURL = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            return dirURL.appendingPathComponent(fileName)
        } catch {
            Log.error(message: "get file url failed")
            return nil
        }
        
    }
    
    func writeResourcesToFile() -> [String:Any] {
        let current_resources:[YRESResource] = resourcesList()
        
        var resourceDict = [String:Any]()
        resourceDict["resources"] = current_resources.map({$0.toDictionary()})
        resourceDict["category_map"] = getCategoryMap()
        resourceDict["categories"] = categoriesJson().map({$0.toDictionary()})
        resourceDict["references"] = getReferences()
        
        //let filePath = getFileURL(fileName:"resources.plist")!
        Log.info(message: "ready to check working Directories")
        let workingDir = Dir("plist_store")
        Log.info(message: "current working dir: \(Dir.workingDir)")
        if !workingDir.exists {
            do {
                try workingDir.create()
                Log.info(message:"Working Directory (\(workingDir.path)) for plist data created.")
            } catch {
                Log.info(message:"Could not create Working Directory for plist data.")
            }
        }
        // Set the working directory
        /*
        do {
            try workingDir.setAsWorkingDir()
            Log.info(message:"Working Directory set with path: \(workingDir.path)")
        } catch {
            Log.info(message:"Could not set Working Directory for examples.")
        }
        */
        Log.info(message: "updated working dir: \(Dir.workingDir)")
        let url = URL(fileURLWithPath: workingDir.path+"resources.plist")
        Log.info(message: "resources ready to write \(resourceDict.count) sections")
        do {
            let resourcesJSON = try resourceDict.jsonEncodedString()
            let resourceFile = File(workingDir.path+"resources.json")
            
            do {
                // Create a file
                
                try resourceFile.open(.readWrite)
                defer {
                    resourceFile.close()
                }
                
                
                Log.info(message: resourceFile.realPath)
                Log.info(message: "resource array size: \(resourceDict.count)")
                try resourceFile.write(string: resourcesJSON)
                
            } catch {
                Log.error(message: "file write failed for \(resourceFile.path)")
            }
        } catch {
            Log.error(message: "json encoding failed")
        }

        if let resourceDict = resourceDict as? NSDictionary {
            //resourceDict.write(to: url, atomically: true)
            resourceDict.write(toFile: url.path, atomically: false)
            
        } else {
            Log.info(message: "cast to NSDictionary failed. resourceDict not written.")
        }
        /*
        let resourceFile = File("resources.plist")
        do {
            // Create a file
            
            try resourceFile.open(.readWrite)
            defer {
                resourceFile.close()
            }
            
            
            Log.info(message: resourceFile.realPath)
            Log.info(message: "resource array size: \(resourceDict.count)")
            
            /*
            let datarepository:Data = try PropertyListSerialization.data(fromPropertyList: resourceDict as! AnyObject, format: .xml, options: 0)
            Log.info(message: "datarepository: \(datarepository.count)")
            //try datarepository.st
            let datastring = String(data: datarepository, encoding: .utf8)
            Log.info(message: "datastring: \(datastring?.characters.count)")
            try resourceFile.write(string: datastring!)
            */
            //archiver.archiveRootObject(resourceArray, toFile: filePath)
            
            //archiveRootObject(current_resources, toFile: filePath)
        } catch {
            Log.info(message: "data serialization failed")
        }
         */
        //Log.info(message: "unarchived value: \(NSKeyedUnarchiver.unarchiveObject(withFile: resourceFile.path))")
        
        return resourceDict
        
    }
    
    func saveResource(fromParams param_array:[(String,String)]) -> (YRESResource, Bool) {
        //separate out category selections
        //let categories_selected = param_array.filter({$0.0 == "category_list"})
        
        
        //compare to current category selections
        
        //create Resource object from remaining params
        let resource_dict = param_array.reduce([String:Any]()) {
            accum, next in
            var tmpdict = accum
            if next.0 != "category_list" {
                if next.0 == "blurb" {
                    let blurb = next.1.stringByReplacing(string: "<br>", withString: "")
                    tmpdict[next.0] = blurb
                } else {
                    tmpdict[next.0] = next.1
                }
            }
            return tmpdict
        }
        
        Log.info(message: "reduced params: \(resource_dict.description)")
        
        let res = YRESResource(usingDict:resource_dict as! [String : String])
        
        //save resource object to db
        let save_result = res.save()
        return (res, save_result)
    }
    
    func saveCategoryOption(fromParams param_array: [(String,String)]) -> Bool {
        //create dictionary from params
        let resourceCat_dict = param_array.reduce([String:String]()) {
            accum, next in
            var tmpdict = accum
            tmpdict[next.0] = next.1
            
            return tmpdict
        }
        Log.info(message:"reduced params: \(resourceCat_dict.description)")
        
        var findStatus = true
        var db = MySQL()
        
        findStatus = db.connect(host: apiAccess.baseURL, user: apiAccess.user, password: apiAccess.pass, db: apiAccess.db_name)
        
        defer {
            db.close()  // defer ensures we close our db connection at the end of this request
        }
        
        var sql:String = ""
        if resourceCat_dict["operation"] == "add" {
            sql = "insert into res_cat_join set resource_id = '\(resourceCat_dict["resid"]!)', cat_id = '\(resourceCat_dict["catid"]!)'"
        } else {
            sql = "delete from res_cat_join where resource_id = '\(resourceCat_dict["resid"]!)' and cat_id = '\(resourceCat_dict["catid"]!)'"
        }
        let catresult = db.query(statement: sql)

        return catresult
    }
}
