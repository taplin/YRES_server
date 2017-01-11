import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectMustache

import TurnstilePerfect
import Turnstile
import TurnstileCrypto
import TurnstileWeb
import Foundation

let accountStore = YRESAccountStore()

let turnstile = TurnstilePerfect(sessionManager: ExampleSessionManager(accountStore: accountStore), realm: YRESRealm(accountStore: accountStore))

// Create HTTP server.
let server = HTTPServer()
Log.logger = SysLogger()
/**
 Endpoint for the home page.
 */
var routes = Routes()

routes.add(method: .get, uri: "/") {
    request, response in
    let context: [String : Any] = ["account": (request.user.authDetails?.account as? YRESAccount)?.dict,
                                   "baseURL": request.baseURL,
                                   "authenticated": request.user.authenticated]
    Log.info(message: "authentication context: \(context)")
    response.render(template: "index", context: context)
}

/**
 Login Endpoint
 */
routes.add(method: .get, uri: "/login") { request, response in
    response.render(template: "login")
}

routes.add(method: .post, uri: "/login") { request, response in
    
    guard let username = request.param(name: "username"),
        let password = request.param(name: "password") else {
            response.render(template: "login", context:  ["flash": "Missing username or password"])
            return
    }
    let credentials = UsernamePassword(username: username, password: password)
    
    do {
        try request.user.login(credentials: credentials, persist: true)
        response.redirect(path: "/")
    } catch {
        response.render(template: "login", context: ["flash": "Invalid Username or Password"])
    }
    
}

routes.add(method: .get, uris: ["/admin/{adminrequest}", "/admin/{adminrequest}/{id}"]) { request, response in
    var usetemplate:String = ""
    let yres = yresApi.sharedInstance
    var context:[String:Any] = ["account": (request.user.authDetails?.account as? YRESAccount)?.dict,
                                "baseURL": request.baseURL,
                                "authenticated": request.user.authenticated,
                                "categories": yres.categoriesJson().map({$0.toDictionary()})
                                ]
    
    guard request.user.authenticated != false  else {
        response.redirect(path: "/")
        return
    }
    
    switch request.urlVariables["adminrequest"]! {
    case "users":
        usetemplate = "recordslist"
        context["accounts"] = accountStore.accounts.map({$0.dict})

    case "resources": 
        if let recordid = request.urlVariables["id"] {
            usetemplate = "resourceedit"
            context["edit_resource"] = yres.getResource(withId: recordid)?.toDictionary()
            
        } else {
            usetemplate = "resourcelist"
            context["resources"] = yres.resourcesList().map({$0.toDictionary()})
        
        }
    case "newresource":

        usetemplate = "resourceedit"
        var new_resource:[String:Any] = ["id":"new", "display_categories": yres.categoriesJson().map({$0.toDictionary()})]
        context["edit_resource"] = new_resource
        
    default:
        usetemplate = "index"
        
    }
    //Log.info(message: "admin context: \(context.keys)")
    response.render(template: usetemplate, context: context)
}

routes.add(method: .post, uris: ["/admin/{adminrequest}", "/admin/{adminrequest}/{id}"]) { request, response in
    var usetemplate:String = ""
    let yres = yresApi.sharedInstance
    var context:[String:Any] = ["account": (request.user.authDetails?.account as? YRESAccount)?.dict,
                                "baseURL": request.baseURL,
                                "authenticated": request.user.authenticated,
                                "categories": yres.categoriesJson().map({$0.toDictionary()}),
                                "category_map": yres.getCategoryMap()
                                ]
    Log.info(message: "post request auth: \(context)")
    
    switch request.urlVariables["adminrequest"]! {
    case "users":
        if let recordid = request.urlVariables["id"] {
            usetemplate = "recordsedit"
            context["edit_account"] = accountStore.accounts.filter({$0.uniqueID == recordid}).first?.dict
            
        }
    case "resources":
        if let recordid = request.urlVariables["id"] {
            usetemplate = "resourceedit"
            if recordid == "save" {
                let save_result:(YRESResource, Bool) = yres.saveResource(fromParams: request.postParams)
                if !save_result.1 {
                    context["alert"] = "Your changes did not save"
                }
                Log.info(message:"saved resource: \(save_result.0)")
                context["edit_resource"] = save_result.0.toDictionary()
                
            } else {
                var editResource = yres.getResource(withId: recordid)
                //editResource = yres.setDisplayCategories(forResource: editResource!)
                Log.info(message:"editing resource: \(editResource)")
                context["edit_resource"] = editResource?.toDictionary()
            }
            
        }
    case "save":
        usetemplate = "resourceedit"
        let save_result:(YRESResource, Bool) = yres.saveResource(fromParams: request.postParams)
        if !save_result.1 {
            context["alert"] = "Your changes did not save"
        }
        Log.info(message:"saved resource: \(save_result.0)")
        context["edit_resource"] = save_result.0.toDictionary()
        
    case "resource_cat":
        response.setBody(string: yres.saveCategoryOption(fromParams: request.postParams).description)
        response.completed()
        return
        
    default:
        usetemplate = "index"
    }
    Log.info(message: "admin context: \(context)")
    response.render(template: usetemplate, context: context)
}
/**
 Registration Endpoint
 */
routes.add(method: .get, uri: "/register") { request, response in
    response.render(template: "register");
}

routes.add(method: .post, uri: "/register") { request, response in
    guard let username = request.param(name: "username"),
        let password = request.param(name: "password") else {
            response.render(template: "register", context: ["flash": "Missing username or password"])
            return
    }
    let credentials = UsernamePassword(username: username, password: password)
    
    do {
        try request.user.register(credentials: credentials)
        try request.user.login(credentials: credentials, persist: true)
        response.redirect(path: "/")
    } catch let e as TurnstileError {
        response.render(template: "register", context: ["flash": e.description])
    } catch {
        response.render(template: "register", context: ["flash": "An unknown error occurred."])
    }
}

/**
 API Endpoint for /me
 */

routes.add(method: .get, uri: "/api/me") { request, response in
    guard let account = request.user.authDetails?.account as? YRESAccount else {
        response.status = .unauthorized
        response.appendBody(string: "401 Unauthorized")
        response.completed()
        return
    }
    response.appendBody(string: account.json)
    response.completed()
    return
}

routes.add(method:.get, uri:"/api/categories") {
    request, response in
    /*guard let account = request.user.authDetails?.account as? YRESAccount else {
        response.status = .unauthorized
        response.appendBody(string: "401 Unauthorized")
        response.completed()
        return
    }*/
    do {
        response.setHeader(.contentType, value: "application/json")
        
        try response.setBody(json: ["categories":yresApi.sharedInstance.categoriesJson()])
    } catch {
        Log.info(message: "body JSON encode failed")
    }
    response.completed()
    return
    
}

routes.add(method:.get, uri:"/api/resources") {
    request, response in
    /*guard let account = request.user.authDetails?.account as? YRESAccount else {
     response.status = .unauthorized
     response.appendBody(string: "401 Unauthorized")
     response.completed()
     return
     }*/
    do {
        response.setHeader(.contentType, value: "application/json")
        
        try response.setBody(json: ["resources":yresApi.sharedInstance.resourcesList()])
    } catch {
        Log.info(message: "body JSON encode failed")
    }
    response.completed()
    return
    
}

routes.add(method:.get, uri:"/api/resource/{resource_id}") {
    request, response in
    do {
        response.setHeader(.contentType, value: "application/json")
        let resource_id = request.urlVariables["resource_id"]
        try response.setBody(json: ["resource":yresApi.sharedInstance.getResource(withId: resource_id! )])
    } catch {
        Log.info(message: "body JSON encode failed")
    }
    response.completed()
    return
}

routes.add(method:.get, uri:"/api/resources/write") {
    request, response in
    /*guard let account = request.user.authDetails?.account as? YRESAccount else {
     response.status = .unauthorized
     response.appendBody(string: "401 Unauthorized")
     response.completed()
     return
     }*/
    do {
        response.setHeader(.contentType, value: "application/json")
        
        try response.setBody(json: ["resources":yresApi.sharedInstance.writeResourcesToFile()])
        
    } catch {
        Log.info(message: "body JSON encode failed")
    }
    response.completed()
    return
    
}

/**
 Logout endpoint
 */
routes.add(method: .post, uri: "/logout") { request, response in
    request.user.logout()
    
    response.redirect(path: "/")
}

// Add the routes to the server.
server.addRoutes(routes)

// Set a listen port of 8181
server.serverPort = 8181

server.setRequestFilters([turnstile.requestFilter])
server.setResponseFilters([turnstile.responseFilter])


var webroot: String
#if Xcode
webroot = "/" + #file.characters.split(separator: "/").map(String.init).dropLast(2).joined(separator: "/")
webroot += "/webroot"
#else
webroot = "./webroot"
#endif

server.documentRoot = webroot

do {
    // Launch the HTTP server.
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
