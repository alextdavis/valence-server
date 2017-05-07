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
        builder.get("seed") { req in
            let media_asset = MediaAsset.init(url: "//example.com/audio.mp3", contentType: "audio/mpeg")
            try media_asset.save()
            
            let album = try Album.findOrCreate(name: "Dummy Album")
            
            let song = Song.init(name: "Dummy Song", track: 1, rating: 0, rank: 2, album: album.id!, mediaAsset: media_asset.id!, time: 0)
            try song.save()
            return "Finished"
        }
        try builder.resource("posts", PostController.self)
    }
}
