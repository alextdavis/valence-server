import Vapor

class Routes: RouteCollection {
    let view: ViewRenderer
    
    init(_ view: ViewRenderer) {
        self.view = view
    }
    
    func build(_ builder: RouteBuilder) throws {
        builder.get("") { req in
            return try self.view.make("home.erb", ["layout": false])
        }

        builder.group("typeahead") { g in
            g.get("albums") { req in
                
            }
        }
    }
}
