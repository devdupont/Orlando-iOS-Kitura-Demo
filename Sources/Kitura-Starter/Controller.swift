/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Kitura
import SwiftyJSON
import LoggerAPI
import CloudFoundryEnv

public class Controller {
    
    let router: Router
    let appEnv: AppEnv
    
    var port: Int {
        get { return appEnv.port }
    }
    
    var url: String {
        get { return appEnv.url }
    }
    
    init() throws {
        appEnv = try CloudFoundryEnv.getAppEnv()
        
        // All web apps need a Router instance to define routes
        router = Router()
        
        //----- Static Website -----//
        
        // Serve static content from "public"
        router.all("/", middleware: StaticFileServer())
        
        //----- Routing Demos -----//
        
        // Basic GET request
        router.get("/hello", handler: getHello)
        
        // Basic POST request
        router.post("/hello", handler: postHello)
        
        // JSON Get request
        router.get("/json", handler: getJSON)
        
        //----- API Routing Errors -----//
        
        // Because the last param is a function
        router.get("/api") { _, response, _ in
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            try response.status(.notFound).send(json: ["Error": "No report type given"]).end()
        }
        
        router.get("/api/metar") { _, response, _ in
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            try response.status(.notFound).send(json: ["Error": "No station given"]).end()
        }
        
        //----- API Routing -----//
        
        router.get("/api/metar/:station", handler: getMetar)
        
        router.all("/api/process", middleware: BodyParser())
        router.post("/api/process", handler: postMetar)
    }
    
    //----- Demo Functions -----//
    
    public func getHello(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        Log.debug("GET - /hello route handler...")
        response.headers["Content-Type"] = "text/plain; charset=utf-8"
        try response.status(.OK).send("Hello from Kitura-Starter!").end()
    }
    
    public func postHello(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        Log.debug("POST - /hello route handler...")
        response.headers["Content-Type"] = "text/plain; charset=utf-8"
        if let name = try request.readString() {
            try response.status(.OK).send("Hello \(name), from Kitura-Starter!").end()
        } else {
            try response.status(.OK).send("Kitura-Starter received a POST request!").end()
        }
    }
    
    public func getJSON(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        Log.debug("GET - /json route handler...")
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        var jsonResponse = JSON([:])
        jsonResponse["framework"].stringValue = "Kitura"
        jsonResponse["applicationName"].stringValue = "iOS-Meetup-Demo"
        jsonResponse["presenter"] = "Michael duPont"
        jsonResponse["presentation-count"].intValue = 2
        jsonResponse["organization"].stringValue = "Orlando iOS Developers Group"
        jsonResponse["location"].stringValue = "Orlando, Florida"
        try response.status(.OK).send(json: jsonResponse).end()
    }
    
    //----- API Functions -----//
    
    public func getMetar(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        // Grab the URL parameter
        let station = request.parameters["station"] ?? ""
        /*let metar = Metar()
         metar.addStation(StationID: station)
         metar.update(StationID: station)*/
        if !(["KLEX", "KMCO", "KSFB"].contains(station)) {
            try response.status(.notAcceptable).send(json: ["Error": "Not a valid station"]).end()
        }
        var rjson = JSON([
            "Station": station,
            "Report": station + " 123456Z 09013KT 13/11",
            "Time": "123456Z",
            "Wind-Speed": 13,
            "Wind-Direction": 90,
            "Temperature": 13,
            "Dewpoint": 11,
            "Units": ["Temperature": "C", "Wind-Speed": "kt"]
            ])
        // Grab the optional query parameter
        if let opts = request.queryParameters["opts"] {
            rjson["opts"].stringValue = opts
        }
        try response.status(.OK).send(json: rjson).end()
    }
    
    public func postMetar(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        guard let body = request.body else {
            next()
            return
        }
        switch(body) {
        case .json(let reqjson):
            let station = reqjson["Station"].string!
            response.headers["Content-Type"] = "text/plain; charset=utf-8"
            try response.status(.OK).send("Processing \(station)").end()
        default:
            break
        }
        next()
    }
}
