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

        builder.post("search") { req in
            return "hi"
        }

        builder.group("typeahead") { g in
            g.get("test") { req in
                return try self.view.make("searchbox.erb")
            }

            g.get("albums") { req in
                return try String(node: Song.database!.raw("SELECT array_to_json(array_agg(row_to_json(a))) FROM " +
                        "(SELECT id, name FROM albums) a")[0]?["array_to_json"])
            }

            g.get("artists") { req in
                return try String(node: Song.database!.raw("SELECT array_to_json(array_agg(row_to_json(a))) FROM " +
                        "(SELECT id, name FROM artists) a")[0]?["array_to_json"])
            }

            g.get("tags") { req in
                return try String(node: Song.database!.raw("SELECT array_to_json(array_agg(row_to_json(a))) FROM " +
                        "(SELECT id, name FROM tags) a")[0]?["array_to_json"])
            }
        }
    }
}
