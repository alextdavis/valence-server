import Vapor

class BrowseRoutes: Routes {
    static let orderables = Set(["name", "year", "rating", "rank", "time", "play_count", "album"])
    
//    func ordering(by: String?, order: String?) {
//        
//        
//    }
    
    override func build(_ builder: RouteBuilder) throws {
        builder.group("b") { b in
            
            b.get("all") { req in
                let cols = ["rank", "track", "name", "time", "rating", "artists", "album", "year"]
                let songs: [Song]
                if let by = req.parameters["by"], let order = req.parameters["order"] {
                    songs = try Song.all()
                } else {
                    songs = try Song.all()
                }
                return try self.view.make("table.erb", ["layout": "just_container.erb", "@cols": cols, "@songs": songs, "@orderables": BrowseRoutes.orderables])
            }
            
            
            
        }//group
    }
}
