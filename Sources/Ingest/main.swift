import App

let config = try Config()
try config.setup()

let drop = try Droplet(config)
try drop.setup()

let ingester = Ingester()
ingester.recursiveIngest("./public/music")
print("Done!")
