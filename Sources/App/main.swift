import Vapor
import Foundation
import Auth
import Fluent
import FluentSQLite
import Routing
import HTTP

// Controllers
let userController = UserController()
let planController = PlanController()

let drop = Droplet()
let auth = AuthenticationMiddleware()

// Database preparation
do {
    let driver = try SQLiteDriver(path: drop.workDir + "Database/plnnr.db")
    Database.default = Database(driver)
    drop.database = Database.default
    drop.preparations.append(User.self)
    drop.preparations.append(Plan.self)
    drop.preparations.append(Comment.self)

} catch { }

// Set documentation route
drop.get { req in
    return try drop.view.make("doc.html")
}

// Create API group
let api: RouteGroup  = drop.grouped("api")

// Create register endpoint
setupRegisterRoute(for: api)

// Create resource endpoints
api.resource("users", userController.setupRoutes(for: api, baseRoute: "users"))
api.resource("plans", planController.setupRoutes(for: api, baseRoute: "plans"))

// Setup custom middleware
drop.middleware.append(LogMiddleware(path: drop.workDir + "PlnnrLog.log"))
drop.middleware.append(auth)

drop.run()
