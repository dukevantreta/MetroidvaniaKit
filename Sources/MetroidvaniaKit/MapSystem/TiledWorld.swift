struct TiledWorld: Codable {
    
    struct Map: Codable {
        let fileName: String
        let height: Int
        let width: Int
        let x: Int
        let y: Int
    }
    
    let maps: [Map]
    let type: String
    let onlyShowAdjacentMaps: Bool
}

//{
//    "maps": [
//        {
//            "fileName": "shaft.tmx",
//            "height": 720,
//            "width": 400,
//            "x": 0,
//            "y": 0
//        },
//        {
//            "fileName": "greenhouse.tmx",
//            "height": 480,
//            "width": 2000,
//            "x": 400,
//            "y": 240
//        },
//        {
//            "fileName": "corridor.tmx",
//            "height": 240,
//            "width": 1600,
//            "x": 400,
//            "y": 480
//        }
//    ],
//    "onlyShowAdjacentMaps": false,
//    "type": "world"
//}
