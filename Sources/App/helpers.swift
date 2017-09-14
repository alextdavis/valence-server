//
// Created by alex on 9/13/17.
//

import Foundation
import Crypto

func fileChecksum(path: String) -> String? {
    if let fileBytes = FileManager.default.contents(atPath: path)?.makeBytes(),
       let checksum = try? Data(Hash.make(.md5, fileBytes)).base64EncodedString() {
        return checksum
    } else {
        return nil
    }
}
