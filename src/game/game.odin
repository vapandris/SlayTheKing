package game

import rl "../../raylib"

Rect :: rl.Rectangle
Vec2 :: [2]f32
Vec2i :: [2]i32

// ============
// Assets:
// ============

ASSETS_PATH :: "assets/"
ROOK_PNG :: ASSETS_PATH + "rook.png"
DUMMY_PNG :: ASSETS_PATH + "dummy.png"
TILE_DARK_PNG :: ASSETS_PATH + "tile_dark.png"
TILE_LIGHT_PNG :: ASSETS_PATH + "tile_light.png"


// ============
// Game state:
// ============
tileCols  :: 8
tileRows :: 8

tileMapPos :: Vec2{0, 0} // TopLeft corner of the tile map
tileSize :: Vec2{48, 48} // Size of each individual tile

GameState :: struct {
    // Game data:
    playerPos: Vec2,
    
    // Game-Render data:
    camera: rl.Camera2D,

    // Render data:
    img_rook: rl.Texture2D,
    img_dummy: rl.Texture2D,
    img_lightTile: rl.Texture2D,
    img_darkTile: rl.Texture2D,
}

g_state: ^GameState

init :: proc() {
    g_state^ = GameState {
        playerPos = {100, 200},

        img_rook = rl.LoadTexture(ROOK_PNG),
        img_dummy = rl.LoadTexture(DUMMY_PNG),
        img_lightTile = rl.LoadTexture(TILE_LIGHT_PNG),
        img_darkTile = rl.LoadTexture(TILE_DARK_PNG),

        camera = {
            offset = Vec2{
                cast(f32)rl.GetScreenWidth() / 2,
                cast(f32)rl.GetScreenHeight() / 2,
            },
            zoom = 1,
        }
    }
    g_state.camera.target = g_state.playerPos

    if    g_state.img_rook.id <= 0 do panic("invalid path: " + ROOK_PNG)
    if    g_state.img_dummy.id <= 0 do panic("invalid path: " + DUMMY_PNG)
    if    g_state.img_lightTile.id <= 0 do panic("invalid path: " + TILE_LIGHT_PNG)
    if    g_state.img_darkTile.id <= 0 do panic("invalid path: " + TILE_DARK_PNG)
}

update :: proc() {
    // Set the camera's target to the midle of the board
    g_state.camera.target = Vec2{
        (cast(f32)tileRows * tileSize.y) / 2,
        (cast(f32)tileCols * tileSize.x) / 2,
    }
    // Set the zoom of the camera so it matches the height of the board with a bit of padding
    g_state.camera.zoom = cast(f32)rl.GetScreenHeight() / (cast(f32)tileRows * tileSize.y)
    g_state.camera.zoom *= 0.95
    dt := rl.GetFrameTime()
    if rl.IsKeyDown(.S) do g_state.playerPos.y += 300 * dt
    if rl.IsKeyDown(.W) do g_state.playerPos.y -= 300 * dt
    if rl.IsKeyDown(.D) do g_state.playerPos.x += 300 * dt
    if rl.IsKeyDown(.A) do g_state.playerPos.x -= 300 * dt
}

draw :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.Color{ 30, 30, 31, 255 })

    rl.BeginMode2D(g_state.camera)
    defer rl.EndMode2D()

    rect := Rect {
        g_state.playerPos.x,
        g_state.playerPos.y,
        100, 100,
    }
    

    currentTilePos := tileMapPos
    for row in 0..<tileRows {
        currentTilePos.x = tileMapPos.x
        for col in 0..<tileRows {
            pairity := ((col + (row % 2)) % 2)
            tileToDraw: ^rl.Texture2D

            if pairity == 0 do tileToDraw = &g_state.img_lightTile
            else do tileToDraw = &g_state.img_darkTile

            drawDestination := rl.Rectangle{
                x = currentTilePos.x,
                y = currentTilePos.y,
                width = tileSize.x,
                height = tileSize.y,
            }

            rl.DrawTexturePro(
                tileToDraw^,
                {0, 0, 48, 48},
                drawDestination,
                {}, 0, rl.WHITE
            )

            currentTilePos.x += tileSize.x;
        }
        currentTilePos.y += tileSize.y
    }

    rl.DrawTextureEx(
        g_state.img_rook,
        {rect.x, rect.y},
        0,
        rect.width / cast(f32)g_state.img_rook.width,
        rl.WHITE
    );
}
