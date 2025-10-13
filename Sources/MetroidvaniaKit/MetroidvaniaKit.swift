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
        // register(type: TileSetImportPlugin.self)
        register(type: TileSetResource.self)
    case .scene:
        [
            GameController.self,
            InputController.self,
            SidescrollerCamera.self,
            CharacterController2D.self,
            Hitbox.self,
            NodeAI.self,
            LinearMoveAI.self,
            LinearBounceAI.self,
            SinWaveAI.self,
            PatrolAI.self,
            CrawlerAI.self,
            FallAI.self,
            PlayerNode.self,
            PlayerStats.self,
            TriggerArea2D.self,
            PlayerHitbox.self,
            HookHitbox.self,
            Projectile.self,
            WeaponNode.self,
            PowerBeam.self,
            WaveBeam.self,
            PlasmaBeam.self,
            RocketLauncher.self,
            GranadeLauncher.self,
            SmartBomb.self,
            Flamethrower.self,
            SmartBombExplosion.self,
            BreakableBlock.self,
            SpeedBoosterBlock.self,
            RocketBlock.self,
            Enemy.self,
            DropCollectible.self,
            HUD.self,
            PauseMenu.self,
            MiniMapHUD.self,
            MapConfiguration.self,
            Hookshot.self,
            SelfDestruct.self,
            Ammo.self,
            FlameSprite.self,
            TileAnimator.self,
            TileSprite2D.self,
            Room.self,
            Item.self,
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
