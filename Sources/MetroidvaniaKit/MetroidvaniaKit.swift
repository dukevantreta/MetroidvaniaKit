import SwiftGodot

//#initSwiftExtension(cdecl: "swift_entry_point")
//#initSwiftExtension(cdecl: "swift_entry_point", types: [
//    CharacterController2D.self,
//    TriggerArea2D.self,
//    PlayerHitbox.self,
//    HookHitbox.self,
//    WaveShot.self,
//    NormalShot.self,
//    TiledImporter.self,
//    TestButton.self,
//])

func setupScene (level: GDExtension.InitializationLevel) {
    switch level {
    case .editor:
        register(type: TileSetImporter.self)
        register(type: TileMapImporter.self)
        register(type: WorldImporter.self)
    case .scene:
        [
            GameController.self,
            InputController.self,
            SidescrollerCamera.self,
            CharacterController2D.self,
            PlayerNode.self,
            PlayerStats.self,
            TriggerArea2D.self,
            PlayerHitbox.self,
            HookHitbox.self,
            Projectile.self,
            PowerBeam.self,
            WaveBeam.self,
            PlasmaBeam.self,
            RocketLauncher.self,
            BreakableBlock.self,
            SpeedBoosterBlock.self,
            RocketBlock.self,
            PatrolEnemy.self,
            CrawlerEnemy.self,
            LinearEnemy.self,
            HUD.self,
            PauseMenu.self,
            MiniMapHUD.self,
            MapConfiguration.self,
        ].forEach { register(type: $0) }
    default:
        break
    }
}

@_cdecl ("swift_entry_point")
public func swift_entry_point(
    interfacePtr: OpaquePointer?,
    libraryPtr: OpaquePointer?,
    extensionPtr: OpaquePointer?) -> UInt8
{
    print ("SwiftGodot Extension loaded")
    guard let interfacePtr, let libraryPtr, let extensionPtr else {
        print ("Error: some parameters were not provided")
        return 0
    }
    initializeSwiftModule(interfacePtr, libraryPtr, extensionPtr, initHook: setupScene, deInitHook: { x in })
    return 1
}
