import SwiftGodot

class TextureMaker {
    static func makeGridTexture(size: Vector2i, margin: Int32, bgColor: Color, fgColor: Color) -> Texture2D? {
        let image = Image.create(width: size.x, height: size.y, useMipmaps: false, format: .rgba8)
        for x in 0..<size.x {
            for y in 0..<size.y {
                if x < margin || y < margin || x >= size.x - margin || y >= size.y - margin {
                    image?.setPixel(x: x, y: y, color: fgColor)
                } else {
                    image?.setPixel(x: x, y: y, color: bgColor)
                }
            }
        }
        return ImageTexture.createFromImage(image)
    }
    
    static func makeBoxTexture(size: Vector2i) -> Texture2D? {
        let image = Image.create(width: size.x, height: size.y, useMipmaps: false, format: .rgba8)
        for x in 0..<size.x {
            for y in 0..<size.y {
                image?.setPixel(x: x, y: y, color: .white)
            }
        }
        return ImageTexture.createFromImage(image)
    }
    
    static func makePassageTexture(size: Vector2i, passageWidth: Int32) -> Texture2D? {
        let lowThreshold = (size.y - passageWidth)/2
        let highThreshold = (size.y + passageWidth)/2 - 1
        let image = Image.create(width: size.x, height: size.y, useMipmaps: false, format: .rgba8)
        for x in 0..<size.x {
            for y in 0..<size.y {
                if y < lowThreshold || y > highThreshold {
                    image?.setPixel(x: x, y: y, color: .white)
                } else {
                    image?.setPixel(x: x, y: y, color: .transparent) // secondary color (inner)
                }
            }
        }
        return ImageTexture.createFromImage(image)
    }
}

class MapDrawer {
    
    static let shared = MapDrawer()
    private init() {
//        self.setCellSize(self.cellSize)
        let configPath = "res://maps/map_config.tres"
        guard let mapConfig = ResourceLoader.load(path: configPath) as? MapConfiguration else {
            GD.pushError("[MapDrawer] Map configuration not found!")
            fatalError()
        }
        self.mapConfig = mapConfig
        self.cellSize = mapConfig.cellSize
        reloadTextureCache()
    }
    
//    private(set) var cellSize: Vector2i = Vector2i(x: 32, y: 32)
//    private(set) var cellSize = Vector2i(x: 16, y: 16)
    private(set) var cellSize: Vector2i //= Vector2i(x: 8, y: 8)
    
    func setCellSize(_ size: Vector2i) {
        self.cellSize = size
        reloadTextureCache()
    }
    
    private var mapConfig: MapConfiguration
    
    private var emptyTexture: Texture2D?
    private var fillTexture: Texture2D?
    private var cornerTexture: Texture2D?
    private var vWallTexture: Texture2D?
    private var vPassageTexture: Texture2D?
//    private var hWallTexture: Texture2D?
//    private var hPassageTexture: Texture2D?
    
    private func reloadTextureCache() {
        emptyTexture = TextureMaker.makeGridTexture(
            size: cellSize,
            margin: cellSize.x/8,
            bgColor: Color(r: 33/255, g: 33/255, b: 74/255),
            fgColor: Color(r: 0, g: 0, b: 148/255))
        fillTexture = TextureMaker.makeBoxTexture(size: cellSize)
        vWallTexture = TextureMaker.makeBoxTexture(size: Vector2i(x: cellSize.x / 8, y: cellSize.y))
        cornerTexture = TextureMaker.makeBoxTexture(size: Vector2i(x: cellSize.x / 8, y: cellSize.y / 8))
        vPassageTexture = TextureMaker.makePassageTexture(size: Vector2i(x: cellSize.x / 8, y: cellSize.y), passageWidth: Int32(mapConfig.passageWidth))
    }
    
    /// Transforms an index into a direction, 0 = right, 1 = down, 2 = left, 3 = up
    func indexToDirection(_ i: Int32) -> Vector2i {
        let negation = 1 - 2 * ((i / 2) % 2)
        let x = (1 - i % 2) * negation
        let y = i % 2 * negation
        return Vector2i(x: x, y: y)
    }
    
    func draw(canvasItem: CanvasItem, offset: Vector2i, coords: Vector3i, mapData: Minimap) {
        
        guard let cellData = mapData.getCell(at: coords) else {
            drawEmpty(canvasItem: canvasItem, offset: Vector2i(from: offset))
            return
        }
        let ci = canvasItem.getCanvasItem()
        
        if let centerTexture = fillTexture {
            let color = Color(r: 1.0, g: 0.0, b: 1.0)
            centerTexture.draw(canvasItem: ci, position: Vector2(from: offset * cellSize), modulate: color)
        }
        drawRegularBorders(canvasItem: canvasItem, offset: offset, coords: coords, mapData: mapData)
        
        canvasItem.drawSetTransformMatrix(xform: Transform2D())
    }
    
    func drawEmpty(canvasItem: CanvasItem, offset: Vector2i) {
        let ci = canvasItem.getCanvasItem()
        emptyTexture?.draw(canvasItem: ci, position: Vector2(from: offset * cellSize), modulate: .white)
    }
    
//    func drawRegularBorders(canvasIwtem: CanvasItem, offset: Vector2i, coords: Vector3i, mapData: MapData) {
    func drawRegularBorders(canvasItem: CanvasItem, offset: Vector2i, coords: Vector3i, mapData: Minimap) {
        guard let cellData = mapData.getCell(at: coords) else {
            return
        }
        
        var borders: [Int] = [-1, -1, -1, -1]
        for i in 0..<4 {
            borders[i] = cellData.getBorder(i)
        }
        
        // draw separator?
//        for i in 0..<2 {
//            if let tex = getBorderTexture(idx: -1, direction: i) {
//                drawBorder(canvasItem: canvasItem, offset: offset, i: i, texture: tex, color: .white)
//            }
//        }
        
        for i in 0..<4 {
            if let tex = getBorderTexture(idx: borders[i], direction: i) {
                drawBorder(canvasItem: canvasItem, offset: offset, i: i, texture: tex, color: .white)
            }
        }
        
        for i in 0..<4 {
            let j = (i + 1) % 4
            if borders[i] != -1 || borders[j] != -1 {
                continue
            }
            
            // check corner room for passages ?
            let hotCorner = Vector2i(x: coords.x, y: coords.y) + indexToDirection(Int32(i)) + indexToDirection(Int32(j))
            let hotRoom = Vector3i(x: hotCorner.x, y: hotCorner.y, z: coords.z)
            if let cell = mapData.getCell(at: hotRoom) {
                let _i = (i + 2) % 4
                let _j = (j + 2) % 4
                if cell.borders[_i].rawValue == -1 && cell.borders[_j].rawValue == -1 {
                    continue
                }
            }
            
            guard let cornerTexture else {
                break
            }
            let pos = Vector2(from: offset * cellSize + cellSize/2)
            canvasItem.drawSetTransform(position: pos, rotation: .pi * 0.5 * Double(i), scale: .one)
            
            let cornerOffset = -cornerTexture.getSize()
            let ci = canvasItem.getCanvasItem()
            cornerTexture.draw(canvasItem: ci, position: cellSize/2 + cornerOffset, modulate: .white)
//            if i == 0 || i == 2 {
//                texture.draw(canvasItem: ci, position: Vector2(x: 16, y: 16) + cornerOffset, modulate: .white)
//            }
        }
    }
    
    func drawBorder(canvasItem: CanvasItem, offset: Vector2i, i: Int, texture: Texture2D, color: Color) {
        canvasItem.drawSetTransform(
            position: Vector2(from: offset * cellSize + cellSize/2),
            rotation: .pi * 0.5 * Double(i),
            scale: .one)
        texture.draw(
            canvasItem: canvasItem.getCanvasItem(),
            position: Vector2.right * (Double(cellSize.x/2) - Double(texture.getWidth()) * 0.5) - Vector2(from: texture.getSize()) * 0.5,
            modulate: color)
    }
    
    func getBorderTexture(idx: Int, direction: Int) -> Texture2D? {
        let separator: Texture2D? = nil
        let wall: Texture2D? = vWallTexture
        let passage: Texture2D? = vPassageTexture
        
        let tex: Texture2D?
        if idx >= 2 {
            tex = nil //borders[idx - 2]
        } else {
            tex = switch idx {
            case -1: separator
            case 0: wall
            case 1: passage
            default: nil
            }
        }
        
        return tex
    }
}
