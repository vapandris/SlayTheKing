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
dummySize :: Vec2{16, 24} // Size of the player/dummy

dummyRadius :: (dummySize.x + dummySize.y) / 2

GameState :: struct {
  // Game data:
  dummyPos: Vec2,
  rook1: Rook,
  rook2: Rook,
  
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
  topLeftPos  := tileMapPos
  topRightPos := topLeftPos + ({cast(f32)tileCols * tileSize.x, 0})
  g_state^ = GameState {
    dummyPos = {100, 200},
    rook1 = {pos = topLeftPos  + ({ rookRadius, rookRadius} * 1.25)},
    rook2 = {pos = topRightPos + ({-rookRadius, rookRadius} * 1.25)},

    img_rook = rl.LoadTexture(ROOK_PNG),
    img_dummy = rl.LoadTexture(DUMMY_PNG),
    img_lightTile = rl.LoadTexture(TILE_LIGHT_PNG),
    img_darkTile = rl.LoadTexture(TILE_DARK_PNG),

    camera = {}
  }
  
  camera_set()

  if g_state.img_rook.id <= 0 do panic("invalid path: " + ROOK_PNG)
  if g_state.img_dummy.id <= 0 do panic("invalid path: " + DUMMY_PNG)
  if g_state.img_lightTile.id <= 0 do panic("invalid path: " + TILE_LIGHT_PNG)
  if g_state.img_darkTile.id <= 0 do panic("invalid path: " + TILE_DARK_PNG)
}
//import "core:fmt"

update :: proc() {
  if rl.IsWindowResized() do camera_set()

  FPS := cast(f32)rl.GetFPS()
  dt := rl.GetFrameTime()
  if rl.IsKeyDown(.S) do g_state.dummyPos.y += 80 * dt
  if rl.IsKeyDown(.W) do g_state.dummyPos.y -= 80 * dt
  if rl.IsKeyDown(.D) do g_state.dummyPos.x += 80 * dt
  if rl.IsKeyDown(.A) do g_state.dummyPos.x -= 80 * dt

  // Logic for rook 1:
  // Is more agressive. Prefers to stay on the most left/right row
  VRook_Update(&g_state.rook1, FPS, dt, Rook1_ChargeTime)
  if false{
  #partial switch g_state.rook1.state {
    case .SLIDE, .CHARGE: {
      acceleration := Rook_Acceleration * FPS;
      deceleration := (Rook_Acceleration / 2) * FPS
      direction := Vec2{0, g_state.dummyPos.y - g_state.rook1.pos.y}
      speed := Vec2_GetLength(g_state.rook1.vel)

      if abs(g_state.dummyPos.x - g_state.rook1.pos.x) < tileSize.x/2 {
        //fmt.println("oii! not cool!");
      } 
      
      if Vec2_GetLength(direction) < (5 + 25*speed) {
        direction = {}
        g_state.rook1.state = .CHARGE
        g_state.rook1.chargeCounter += dt
      } else {
        g_state.rook1.state = .SLIDE
        g_state.rook1.chargeCounter -= dt
        if g_state.rook1.chargeCounter < 0 do g_state.rook1.chargeCounter = 0
      }

      decelerationVec := Vec2_GetScaled(g_state.rook1.vel, -1 * deceleration)
      g_state.rook1.vel += direction * (acceleration * dt)
      g_state.rook1.vel += decelerationVec * dt

      speed = Vec2_GetLength(g_state.rook1.vel)
      if Rook_MaxSpeed < speed {
        Vec2_Scale(&g_state.rook1.vel, Rook_MaxSpeed)
      }
      
      g_state.rook1.pos += g_state.rook1.vel
      limitTop:f32 = tileMapPos.y + rookRadius*2
      limitBot:f32 = tileMapPos.y + (cast(f32)tileRows*tileSize.y) - rookRadius*2
      distanceFromTop:f32 = g_state.rook1.pos.y - limitTop
      distanceFromBot:f32 = limitBot - g_state.rook1.pos.y
      
      if distanceFromTop < 0 do g_state.rook1.pos.y -= distanceFromTop
      else if distanceFromBot < 0 do g_state.rook1.pos.y += distanceFromBot

      if speed < 0.5 {
        g_state.rook1.vel = {}
      }

      if g_state.rook1.chargeCounter >= Rook1_ChargeTime do g_state.rook1.state = .ATTACK
    }
    case .ATTACK: {
      chargeMultiplyer: f32 = 5

      g_state.rook1.chargeCounter = 0
      acceleration := Rook_Acceleration * chargeMultiplyer * FPS
      deceleration := (Rook_Acceleration / chargeMultiplyer) * FPS
      if g_state.rook1.attackDir == {} {
        g_state.rook1.attackDir = Vec2{g_state.dummyPos.x - g_state.rook1.pos.x, 0}
      }

      decelerationVec := Vec2_GetScaled(g_state.rook1.vel, -1 * deceleration)
      g_state.rook1.vel += g_state.rook1.attackDir * (acceleration * dt)
      g_state.rook1.vel += decelerationVec * dt

      speed := Vec2_GetLength(g_state.rook1.vel)
      if chargeMultiplyer*Rook_MaxSpeed < speed {
        Vec2_Scale(&g_state.rook1.vel, chargeMultiplyer*Rook_MaxSpeed)
      }

      g_state.rook1.pos += g_state.rook1.vel
      
      padding :f32 = 0.9
      leftStopPosX  := tileMapPos.x + (rookRadius * padding)
      rightStopPosX := tileMapPos.x + (cast(f32)tileCols * tileSize.x) - (rookRadius*padding)
      if  g_state.rook1.pos.x <= leftStopPosX ||
        rightStopPosX <= g_state.rook1.pos.x {

        g_state.rook1.vel = {}
        g_state.rook1.attackDir = {}
        g_state.rook1.state = .SLIDE
      }
    }
    case: {}
  }}

  // Logic for rook 2:
  // Defensive. Prefers to stay on the top column, protecting the exit
  #partial switch g_state.rook2.state {
    case .SLIDE, .CHARGE: {
      acceleration := Rook_Acceleration * 1.5 * FPS;
      deceleration := (Rook_Acceleration / 2) * FPS
      direction := Vec2{g_state.dummyPos.x - g_state.rook2.pos.x, 0}
      speed := Vec2_GetLength(g_state.rook2.vel)
      
      if Vec2_GetLength(direction) < (5 + 25*speed) {
        direction = {}
        g_state.rook2.state = .CHARGE
        g_state.rook2.chargeCounter += dt
      } else {
        g_state.rook2.state = .SLIDE
        g_state.rook2.chargeCounter -= dt
        if g_state.rook2.chargeCounter < 0 do g_state.rook2.chargeCounter = 0
      }

      decelerationVec := Vec2_GetScaled(g_state.rook2.vel, -1 * deceleration)
      g_state.rook2.vel += direction * (acceleration * dt)
      g_state.rook2.vel += decelerationVec * dt

      speed = Vec2_GetLength(g_state.rook2.vel)
      if Rook_MaxSpeed < speed {
        Vec2_Scale(&g_state.rook2.vel, Rook_MaxSpeed)
      }

      g_state.rook2.pos += g_state.rook2.vel
      limitLeft:f32 = tileMapPos.x + rookRadius*2
      limitRight:f32 = tileMapPos.x + (cast(f32)tileCols*tileSize.x) - rookRadius*2
      distanceFromLeft:f32 = g_state.rook2.pos.x - limitLeft
      distanceFromRight:f32 = limitRight - g_state.rook2.pos.x
      
      if distanceFromLeft < 0 do g_state.rook2.pos.x -= distanceFromLeft
      else if distanceFromRight < 0 do g_state.rook2.pos.x += distanceFromRight

      if speed < 0.5 {
        g_state.rook2.vel = {}
      }

      if g_state.rook2.chargeCounter >= Rook2_ChargeTime do g_state.rook2.state = .ATTACK
    }
    case .ATTACK: {
      chargeMultiplyer: f32 = 5

      g_state.rook2.chargeCounter = 0
      acceleration := Rook_Acceleration * chargeMultiplyer * FPS
      deceleration := (Rook_Acceleration / chargeMultiplyer) * FPS
      if g_state.rook2.attackDir == {} {
        g_state.rook2.attackDir = Vec2{0, g_state.dummyPos.y - g_state.rook2.pos.y}
      }

      decelerationVec := Vec2_GetScaled(g_state.rook2.vel, -1 * deceleration)
      g_state.rook2.vel += g_state.rook2.attackDir * (acceleration * dt)
      g_state.rook2.vel += decelerationVec * dt

      speed := Vec2_GetLength(g_state.rook2.vel)
      if chargeMultiplyer*Rook_MaxSpeed < speed {
        Vec2_Scale(&g_state.rook2.vel, chargeMultiplyer*Rook_MaxSpeed)
      }

      g_state.rook2.pos += g_state.rook2.vel
      
      paddingTop: f32 = 1.25
      paddingBot: f32 = 0.7
      topStopPosY  := tileMapPos.y + (rookRadius * paddingTop)
      botStopPosY := tileMapPos.y + (cast(f32)tileRows * tileSize.y) - (rookRadius*paddingBot)
      if botStopPosY <= g_state.rook2.pos.y {
        g_state.rook2.vel = {}
        g_state.rook2.attackDir = {}
        // stay in ATTACK state to go back to defending
      }

      if  g_state.rook2.pos.y <= topStopPosY {

        g_state.rook2.vel = {}
        g_state.rook2.attackDir = {}
        g_state.rook2.state = .SLIDE
      }
    }
    case: {}
  }
  
}

draw :: proc() {
  rl.BeginDrawing()
  defer rl.EndDrawing()

  rl.ClearBackground(rl.Color{ 30, 30, 31, 255 })

  rl.BeginMode2D(g_state.camera)
  defer rl.EndMode2D()

  rect := Rect {
    g_state.dummyPos.x,
    g_state.dummyPos.y,
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
        {0, 0, tileSize.x, tileSize.y},
        drawDestination,
        {}, 0, rl.WHITE
      )

      currentTilePos.x += tileSize.x;
    }
    currentTilePos.y += tileSize.y
  }

  rook1_color := rl.WHITE
  counter := g_state.rook1.chargeCounter
  if  (0 < counter &&
    counter < Rook1_ChargeTime * 0.333) ||
    (Rook1_ChargeTime * 0.666 < counter &&
    counter < Rook1_ChargeTime)
  {
    rook1_color = rl.RED
  }

  rook2_color := rl.WHITE
  counter = g_state.rook2.chargeCounter
  if  (0 < counter &&
    counter < Rook2_ChargeTime * 0.333) ||
    (Rook2_ChargeTime * 0.666 < counter &&
    counter < Rook2_ChargeTime)
  {
    rook2_color = rl.RED
  }
  
  rl.DrawTexturePro(
    g_state.img_dummy,
    {0, 0, dummySize.x, dummySize.y},
    {rect.x, rect.y, dummySize.x, dummySize.y},
    dummySize * {0.5 , 0.75},
    0, rl.WHITE
  )

  rl.DrawTexturePro(
    g_state.img_rook,
    {0, 0, rookSize.x, rookSize.y},
    {g_state.rook1.pos.x, g_state.rook1.pos.y,
     rookSize.x, rookSize.y},
    rookSize * {0.5 , 0.75},
    0, rook1_color
  )
  
  rl.DrawTexturePro(
    g_state.img_rook,
    {0, 0, rookSize.x, rookSize.y},
    {g_state.rook2.pos.x, g_state.rook2.pos.y,
     rookSize.x, rookSize.y},
    rookSize * {0.5 , 0.75},
    0, rook2_color
  )

  // debug draw:
  /*
  rl.DrawCircle(
    cast(i32)g_state.dummyPos.x,
    cast(i32)g_state.dummyPos.y,
    5, rl.Color{ 253, 249, 0, 55 }
  )

  rl.DrawCircle(
    cast(i32)g_state.rook1.pos.x,
    cast(i32)g_state.rook1.pos.y,
    15, rl.Color{ 253, 10, 0, 55 }
  )
  */
}

// ==================================
// Helper functions :)
// ==================================

// Camera:
camera_set :: proc(midPoint: Vec2 = Vec2{
  (tileMapPos.x + (cast(f32)tileCols * tileSize.x)) / 2,
  (tileMapPos.y + (cast(f32)tileRows * tileSize.y)) / 2,
}) {
  // Set camera's origin to the midle of the window
  g_state.camera.offset = Vec2{
    cast(f32)rl.GetScreenWidth() / 2,
    cast(f32)rl.GetScreenHeight() / 2,
  }

  // Set the camera's target to the midle of the board
  g_state.camera.target = midPoint

  // Set the zoom of the camera so it matches the height of the board with a bit of padding
  g_state.camera.zoom = cast(f32)rl.GetScreenHeight() / (cast(f32)tileRows * tileSize.y)
  g_state.camera.zoom *= 0.95
}

// Math:
sqrt :: proc(num: f32) -> f32 {
  num := num
  if num < 0 do num *= -1

  i: i32
  x, y: f32

  x = num * 0.5
  y = num
  i = (cast(^i32)&y)^
  i = 0x5f3759df - (i >> 1)
  y = (cast(^f32)&i)^
  y = y * (1.5 - (x * y * y))
  y = y * (1.5 - (x * y * y))

  return num * y
}

sq :: proc(num: f32) -> f32 {
  return num * num
}

// Vec2:
Vec2_GetLength :: proc(v: Vec2) -> f32 {
  return sqrt(sq(v.x) + sq(v.y))
}

Vec2_GetNormal :: proc(v: Vec2) -> Vec2 {
  if v == {} do return v

  length := Vec2_GetLength(v)
  return {
    v.x / length,
    v.y / length,
  }
}

Vec2_Normalize :: proc(v: ^Vec2) {
  normal := Vec2_GetNormal(v^)
  if normal == {} do return

  v^ = normal
}


Vec2_GetScaled :: proc(v: Vec2, scaler: f32) -> Vec2 {
  scaled := Vec2_GetNormal(v)
  scaled.x *= scaler
  scaled.y *= scaler

  return scaled
}

Vec2_Scale :: proc(v: ^Vec2, scaler: f32) {
  v^ = Vec2_GetScaled(v^, scaler)
}

Vec2_GetVectorTo :: proc(start: Vec2, end: Vec2) -> Vec2 {
  return  end - start
}

Vec2_GetDistance :: proc(p1: Vec2, p2: Vec2) -> f32 {
  return Vec2_GetLength(p1 - p2)
}