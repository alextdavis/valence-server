import Vapor
import HTTP

class InfoRoutes: Routes {
    override func build(_ builder: RouteBuilder) throws {
        builder.group("i") { g in
            g.group("song", Song.parameter) { b in
                b.get("url") { req in
                    let song = try req.parameters.next(Song.self)
                    if let url = song.audioAsset?.url {
                        return Response(redirect: url)
                    } else {
                        throw Abort(.notFound)
                    }
                }

                b.get("info") { req in
                    return try req.parameters.next(Song.self).makeJSON()
                }
            }

            g.group("album", Album.parameter) { b in
                b.get("info") { req in
                    return try req.parameters.next(Album.self).makeJSON()
                }
            }

            g.group("artist", Artist.parameter) { b in
                b.get("info") { req in
                    return try req.parameters.next(Artist.self).makeJSON()
                }
            }

            g.group("tag", Tag.parameter) { b in
                b.get("info") { req in
                    return try req.parameters.next(Tag.self).makeJSON()
                }
            }

        }
    }
}
