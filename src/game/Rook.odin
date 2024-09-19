package game

rookSize :: Vec2{48, 64}
rookRadius :: 24.0 

Rook_Acceleration :: 0.05
Rook_MaxSpeed :: 1.5

Rook1_ChargeTime:f32 : 1.5
Rook2_ChargeTime:f32 : 2.5

Rook :: struct {
    pos: Vec2,
    vel: Vec2,
    state: enum  {
        SLIDE = 0, CHARGE, ATTACK, DEFEND,
        COORDATTACK_V, COORDATTACK_H,
    },
    chargeCounter: f32, // from 0 to 1.5 seconds, the rooks will charge up before attacking the player
    attackDir: Vec2, // Saved direction of where the rook is charging
}

import "core:fmt"

VRook_Update :: proc(
    rook: ^Rook,
    FPS: f32,
    dt: f32,
    chargeTime := Rook1_ChargeTime,
) {
    #partial switch rook.state {
        case .SLIDE, .CHARGE: {
            direction := g_state.dummyPos - rook.pos
            acceleration := Rook_Acceleration * FPS
            deceleration := (Rook_Acceleration / 2) * FPS

            if rook.state == .CHARGE {
                // Update chargeCounter and transition to ATTACK when ready
                rook.chargeCounter += dt

                if rook.chargeCounter >= chargeTime {
                    rook.state = .ATTACK
                    rook.chargeCounter = 0
                }

                // Stop momentum to make it easyer to run away:
                rook.vel = {}

            } else {
                // Transition to vertical/horisontal attack
                if abs(direction.x) < tileSize.x/2 {
                    rook.state = .CHARGE
                    rook.attackDir = direction
                    rook.attackDir.x = 0
                } else if abs(direction.y) < tileSize.y/2 {
                    rook.state = .CHARGE
                    rook.attackDir = direction
                    rook.attackDir.y = 0
                }
            }
            direction.x = 0;

            // Update velocity:
            decelerationVec := Vec2_GetScaled(rook.vel, -1 * deceleration)
            rook.vel += direction * acceleration * dt
            rook.vel += decelerationVec *dt

            speed := Vec2_GetLength(rook.vel)
            if speed > Rook_MaxSpeed {
                Vec2_Scale(&rook.vel, Rook_MaxSpeed)
            }

            // Update position & stay inside limits:
            rook.pos += rook.vel

            limitTop:f32 = tileMapPos.y + rookRadius*2
            limitBot:f32 = tileMapPos.y + (cast(f32)tileRows*tileSize.y) - rookRadius*2
            distanceFromTop:f32 = rook.pos.y - limitTop
            distanceFromBot:f32 = limitBot - rook.pos.y
            
            if distanceFromTop < 0 {
                rook.pos.y -= distanceFromTop
            } else if distanceFromBot < 0 {
                rook.pos.y += distanceFromBot
            }

            // Stop rook when sliding too slow:
            if speed < 0.5 do rook.vel = {}
        }
        case .DEFEND: {

        }
        case .ATTACK: {
            fmt.println("{}", rook.attackDir)
            chargeMultiplyer: f32 = 5
            acceleration := Rook_Acceleration * chargeMultiplyer * FPS
            deceleration := (Rook_Acceleration / chargeMultiplyer) * FPS

            // Update velocity:
            decelerationVec := Vec2_GetScaled(rook.vel, -1 * deceleration)
            rook.vel += rook.attackDir * (acceleration * dt)
            rook.vel += decelerationVec * dt
            
            speed := Vec2_GetLength(rook.vel)
            if speed > chargeMultiplyer*Rook_MaxSpeed {
                Vec2_Scale(&rook.vel, chargeMultiplyer*Rook_MaxSpeed)
            }

            // Update position & stay inside limits:
            rook.pos += rook.vel

            paddingX :f32 = 0.95
            leftStopPosX  := tileMapPos.x + (rookRadius * paddingX)
            rightStopPosX := tileMapPos.x + (cast(f32)tileCols * tileSize.x) - (rookRadius*paddingX)
            paddingTop: f32 = 1.25
            paddingBot: f32 = 0.7
            topStopPosY  := tileMapPos.y + (rookRadius * paddingTop)
            botStopPosY := tileMapPos.y + (cast(f32)tileRows * tileSize.y) - (rookRadius*paddingBot)

            if  (rook.attackDir.x == 0 &&
                (botStopPosY <= rook.pos.y ||
                 rook.pos.y <= topStopPosY)) ||
                (rook.attackDir.y == 0 &&
                (rook.pos.x <= leftStopPosX ||
                 rightStopPosX <= rook.pos.x)) {
                    rook.vel = {}
                    rook.attackDir = {}
                    rook.state = .SLIDE
            }

        }
        case: {}
    }
}