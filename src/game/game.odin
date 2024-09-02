package game

import rl "../../raylib"

Rect :: rl.Rectangle
Vec2 :: [2]f32
Vec2i :: [2]i32

// Assets:
ASSETS_PATH :: "assets/"
ROOK_PNG :: ASSETS_PATH + "rook.png"
DUMMY_PNG :: ASSETS_PATH + "dummy.png"
TILE_DARK_PNG :: ASSETS_PATH + "tile_dark.png"
TILE_LIGHT_PNG :: ASSETS_PATH + "tile_light.png"

GameState :: struct {
	player_pos: Vec2,

	img_rook: rl.Texture2D,
	img_dummy: rl.Texture2D,
	img_lightTile: rl.Texture2D,
	img_darkTile: rl.Texture2D,
}

g_state: ^GameState

init :: proc() {
	g_state^ = GameState {
		player_pos = {100, 200},

		img_rook = rl.LoadTexture(ROOK_PNG),
		img_dummy = rl.LoadTexture(DUMMY_PNG),
		img_lightTile = rl.LoadTexture(TILE_LIGHT_PNG),
		img_darkTile = rl.LoadTexture(TILE_DARK_PNG),
	}

	if	g_state.img_rook.id <= 0 do panic("invalid path: " + ROOK_PNG)
	if	g_state.img_dummy.id <= 0 do panic("invalid path: " + DUMMY_PNG)
	if	g_state.img_lightTile.id <= 0 do panic("invalid path: " + TILE_LIGHT_PNG)
	if	g_state.img_darkTile.id <= 0 do panic("invalid path: " + TILE_DARK_PNG)
}

update :: proc() {
	dt := rl.GetFrameTime()
	if rl.IsKeyDown(.S) do g_state.player_pos.y += 300 * dt
	if rl.IsKeyDown(.W) do g_state.player_pos.y -= 300 * dt
	if rl.IsKeyDown(.D) do g_state.player_pos.x += 300 * dt
	if rl.IsKeyDown(.A) do g_state.player_pos.x -= 300 * dt
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rect := Rect {
		g_state.player_pos.x,
		g_state.player_pos.y,
		100, 100,
	}
	//rl.DrawRectangleRec(rect, rl.GREEN)
	rl.DrawTextureEx(
		g_state.img_rook,
		{rect.x, rect.y},
		0,
		rect.width / cast(f32)g_state.img_rook.width,
		rl.WHITE
	);

	rl.EndDrawing()
}
