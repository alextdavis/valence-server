import Vapor

class BrowseRoutes: Routes {

    override func build(_ builder: RouteBuilder) throws {
        builder.group("b") { b in
            b.get("albums") { req in
                return try self.view.make("split.erb",
                                          ["layout": false,
                                           "@albums": Album.all().map({ $0.makeJSON() })
                                          ])
            }

            b.get("artists") { req in
                return try self.view.make("split.erb",
                                          ["layout": false,
                                           "@artists": Artist.all().map({ $0.makeJSON() })
                                          ])
            }

            b.get("tags") { req in
                return try self.view.make("split.erb",
                                          ["layout": false,
                                           "@tags": Tag.all().map({ $0.makeJSON() })
                                          ])
            }

            b.get("stars") { req in
                return try self.view.make("split.erb",
                                          ["layout": false,
                                           "@stars": [1, 2, 3, 4, 5]
                                          ])
            }

            b.get("searches") { req in
                return try self.view.make("split.erb",
                                          ["layout": false,
                                           "@searches": Search.all().map({ $0.makeJSON() })
                                          ])
            }

            b.get("all") { req in
                return try self.makeTableView(
                        search: Search("all"),
                        request: req,
                        cols: ["rank", "track", "name", "time", "rating", "artists", "album", "year"],
                        layout: "just_container.erb")
            }

            b.get("artist", Artist.parameter) { req in
                return try self.makeTableView(
                        search: Search("@\(req.parameters.next(Artist.self).id!.int!)"),
                        request: req,
                        cols: ["rank", "track", "name", "time", "rating", "tags", "artists", "album"])
            }

            b.get("album", Album.parameter) { req in
                return try self.makeTableView(
                        search: Search("%\(req.parameters.next(Album.self).id!.int!)"),
                        request: req,
                        cols: ["rank", "track", "name", "time", "rating", "tags", "artists", "year"])
            }

            b.get("tag", Tag.parameter) { req in
                return try self.makeTableView(
                        search: Search("#\(req.parameters.next(Tag.self).id!.int!)"),
                        request: req,
                        cols: ["rank", "track", "name", "time", "rating", "tags", "artists", "year"])
            }

            b.get("star", Int.parameter) { req in
                return try self.makeTableView(
                        search: Search(":rating >= \(req.parameters.next(Int.self))"),
                        request: req,
                        cols: ["rank", "track", "name", "time", "rating", "artists", "album", "year"])
            }

            b.get("search", Search.parameter) { req in
                return try self.makeTableView(
                        search: req.parameters.next(Search.self),
                        request: req,
                        cols: ["rank", "track", "name", "time", "rating", "artists", "album", "year"])
            }

        }//group
    }

    private func makeTableView(search: Search,
                               request req: Request,
                               cols: [String],
                               layout: String? = nil) throws -> ResponseRepresentable {
        let (orderBy, orderStrs) = self.doOrdering(query: req.query)
        Queuer.q.updateViewList(try search.getIDs(orderBy: orderBy))
        return try self.view.make("table.erb",
                                  ["layout": layout ?? false,
                                   "@all_tags": Tag.database!.raw("SELECT name FROM tags"),
                                   "@cols": cols,
                                   "@songs": try search.getJSON(orderBy: orderBy),
                                   "@order": orderStrs as Any?,
                                  ])
    }

    private func doOrdering(query: Node?) -> (String, [String]?) {
        var orderStrs: [String]?
        let orderBy: String
        if let by = query?["by"]?.string, let order = query?["order"]?.string {
            orderBy = "songs.\(by) \(order)"
            orderStrs = [by, order]
        } else {
            orderBy = "album_id, disc, track"
        }
        return (orderBy, orderStrs)
    }
}
