import Vapor

class PlayerRoutes: Routes {
    override func build(_ builder: RouteBuilder) throws {
        builder.get("p") { req in
            return try self.view.make("blank.erb")
        }
    }
}
