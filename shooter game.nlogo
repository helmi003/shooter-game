extensions [sound]

breed [obstacle]
breed [enemies-base]
breed [ammos]
breed [player]
breed [player-bullet]
breed [enemy-bullet]
breed [enemies]
breed [explosion]

breed [final]
globals [
  mouse-was-down
  stop-game
  max-bullets
  play-music
]

player-own [health]
enemies-own [health]

to setup
  clear-all
  reset-ticks
  setup-obstacles
  set play-music false
  set mouse-was-down false
  set stop-game false
  setup-player
  setup-enemies-base
  setup-enemies
  ask patches with [count neighbors != 8] [set pcolor brown]
  set max-bullets 40
end

to setup-player
  create-player 1 [
    set color blue
    set shape "person soldier"
    set size 3
    setxy 22 10
    set heading 0
    set health 100
  ]
end

to setup-obstacles
  let obstacle-positions [
    [22 22] [21 22] [20 22] [2 18] [3 18] [10 30] [11 30] 
    [30 30] [15 35] [25 30] [40 18] [39 18]
  ]
  
  foreach obstacle-positions [
    let obstacle-position ?
    let obstacle-xcor item 0 obstacle-position
    let obstacle-ycor item 1 obstacle-position
    
    create-obstacle 1 [
      set color red
      set shape "crate"
      set size 2
      setxy obstacle-xcor obstacle-ycor
    ]
  ]
end


to setup-enemies-base
  let x 0
  create-enemies-base 4 [
    set color random 140
    set shape "base"
    set size 5
    set x (x + 9)
    setxy x (max-pycor - 3)
    hatch-enemies 1 [
      create-link-from myself [
        set color black
      ]
    ]
  ]
end

to setup-enemies
  ask enemies [
    set heading 0
    set shape "monster"
    set size 2
    set color magenta
    set health 100
  ]
end

to play
  spawn-ammo
  tick
  if stop-game = true [
    stop
  ]
  if ticks mod 6000 = 0 [
    change-color
  ]
  
  ask player [
    player-pickup-ammo
    player-attack
  ]
  
  setup-player-bullets
  chase-player
  explosion-cinematic
  check-mouse-down
  setup-enemy-bullets
end

to check-mouse-down
  if mouse-down? and mouse-was-down = false [
    set mouse-was-down true
    ask player [
      ifelse max-bullets > 0 [
        hatch-player-bullet 1 [
          set size 1.5
          set shape "bullet"
          set label ""
        ]
        sound:play-note "Gunshot" 65 64 2
        set max-bullets max-bullets - 1
      ][
        sound:play-note "Agogo" 60 64 2  ; Play a different sound when out of bullets
      ]
    ]
  ]
  if not mouse-down? [
    set mouse-was-down false
  ]
end



to change-color
  ask enemies-base [
    set color random 140
  ]
end

to player-attack
  ask player [
    if health <= 0 [
      game-over
    ]
    set label round(health)
    facexy mouse-xcor mouse-ycor
  ]
end

to chase-player
  if count enemies = 0 [
    game-win
  ]
  ask enemies [
    if health <= 0 [
      explode
      die
    ]
    set label round(health)
    ifelse distance one-of player < 20 [
      set heading towards one-of player
      fd 0.0001
      if ticks mod 10000 = 0 [
        hatch-enemy-bullet 1 [
          set size 1
          set shape "drop"
          set color blue
          set label ""
        ]
        sound:play-note "Gunshot" 65 64 2
      ]
    ] [
      face one-of in-link-neighbors
      
      ifelse distance one-of in-link-neighbors < 1 [
        move-to one-of in-link-neighbors
        set heading 180
      ] [
        fd 0.0001
      ]
    ]
  ]
end

to setup-player-bullets
  ask player-bullet [
    fd 0.01
    if [pcolor] of patch-here = brown [
      die
    ]
    if distance one-of enemies-base < 3 [
      die
    ]
    if distance one-of obstacle < 1 [
      die
    ]
    ask enemies in-radius 3 [
      set health (health - 0.01)
    ]
  ]
end

to setup-enemy-bullets
  ask enemy-bullet [
    fd 0.01
    if [pcolor] of patch-here = brown [
      die
    ]
    if distance one-of obstacle < 1 [
      die
    ]
    ask player in-radius 3 [
      set health (health - 0.003)
    ]
  ]
end

to explode
  hatch-explosion 25 [
    set shape "fire"
    set size 1
    set heading random 360
    set label ""
  ]
  sound:play-note "Gunshot" 0 64 2
end

to explosion-cinematic
  ask explosion [
    fd 0.001
    if [pcolor] of patch-here = brown [
      die
    ]
  ]
end

to go-up
  ask player [
    let new-ycor (ycor + 1)
    if not obstacle-at-patch 0 1 and new-ycor <= max-pycor - 2 [
      set ycor new-ycor
    ]
    set heading 0
  ]
end

to go-down
  ask player [
    let new-ycor (ycor - 1)
    if not obstacle-at-patch 0 -1 and new-ycor >= min-pycor + 2 [
      set ycor new-ycor
    ]
    set heading 180
  ]
end

to go-left
  ask player [
    let new-xcor (xcor - 1)
    if not obstacle-at-patch -1 0 and new-xcor >= min-pxcor + 1 [
      set xcor new-xcor
    ]
    set heading -90
  ]
end

to go-right
  ask player [
    let new-xcor (xcor + 1)
    if not obstacle-at-patch 1 0 and new-xcor <= max-pxcor - 1 [
      set xcor new-xcor
    ]
    set heading 90
  ]
end



to game-over
  hatch-final 1 [
    set shape "x"
    setxy 22 22
    set size 30
    set label ""
    set color red
  ]
  set stop-game true
  user-message "Opps! Game over, you lost!"
end

to game-win
  create-final 1 [
    set shape "cup"
    setxy 22 22
    set size 30
    set label ""
  ]
  set stop-game true
  user-message "Congratulations! You won the game!"
end

to spawn-ammo
  if ticks mod 100000 = 0 [
    create-ammos 1 [
      set color yellow
      set size 2
      setxy random-xcor random-ycor
      set shape "logs"
    ]
  ] 
end

to player-pickup-ammo
  let nearby-ammo ammos-on patch-here
  if any? nearby-ammo [
    let ammo-picked one-of nearby-ammo
    set max-bullets max-bullets + 20
    ask ammo-picked [ die ]
  ]
end

to-report obstacle-at-patch [x y]
  let next-patch patch-at x y
  report any? obstacle with [pxcor = [pxcor] of next-patch and pycor = [pycor] of next-patch]
end

to start-song
  sound:loop-sound "pirates.wav"
end

to stop-song
  sound:stop-sound
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
805
626
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
44
0
44
0
0
1
ticks
30.0

BUTTON
22
57
86
90
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
102
57
165
90
Play
play
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
26
225
89
258
Left
go-left
NIL
1
T
OBSERVER
NIL
Q
NIL
NIL
1

BUTTON
90
225
153
258
Right
go-right
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
55
259
118
292
Down
go-down
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
56
191
119
224
Up
go-up
NIL
1
T
OBSERVER
NIL
Z
NIL
NIL
1

BUTTON
9
121
94
154
play song
start-song
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
104
123
191
156
Stop song
stop-song
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
55
347
112
392
Bullets
max-bullets
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is a shooter game where you play as a soldier tasked with defeating monsters. The objective is to eliminate the monsters while avoiding getting killed. The monsters can only be attacked when they are out of their base. The game also features obstacles that both you and the monsters cannot shoot through. You need to collect ammunition to be able to fire at the monsters and win the game. If you run out of ammunition or if your health reaches zero, you lose the game.

## HOW IT WORKS

The game is implemented using the NetLogo modeling environment. The agents in the game include the player (soldier), enemies, obstacles, enemy bases, ammunition, bullets, and explosions. The player can move around the game world using the Z, Q, S, and D keys to move up, left, down, and right respectively. The enemies will start chasing the player when they are within a certain range. The player can attack by clicking on the game window, firing bullets towards the enemies. The game keeps track of the player's health and ammunition, as well as the enemies' health. The game ends when either the player's health reaches zero or all enemies are defeated.

## HOW TO USE IT

1-Start the game by clicking the "Setup" button.
2-Use the Z, Q, S, and D keys to move the player up, left, down, and right respectively.
3-Click inside the game window to fire bullets at the enemies. Note that bullets can only hit enemies outside their base and cannot pass through obstacles.
4-Collect ammunition that spawns randomly in the game world to replenish your ammunition stock.
5-Avoid getting hit by enemy bullets or coming into close proximity with enemies.
6-Continue playing until either your health reaches zero or all enemies are defeated.

## THINGS TO NOTICE

*Pay attention to your ammunition level. Make sure to collect ammunition to maintain your firepower.
*Observe the behavior of the enemies. They will chase you when you're within a certain range and try to attack you.
*Take note of the obstacles in the game world. They provide cover and block bullets from passing through.

## THINGS TO TRY

*Experiment with different movement strategies using the Z, Q, S, and D keys to avoid enemy bullets and navigate through the game world effectively.
*Try to eliminate all the enemies as quickly as possible to achieve a high score.
*Observe how enemy behavior changes as their health decreases.
*Explore different ways to use the obstacles to your advantage, such as using them as shields or creating barriers to block enemy paths.

## EXTENDING THE MODEL

*You can introduce different types of enemies with varying characteristics, such as different movement speeds or attack patterns.
*Add power-ups that provide temporary boosts to the player's health, ammunition, or shooting abilities.
*Implement additional levels with increasing difficulty, introducing new challenges and enemy types.
*Create more complex obstacle configurations or generate them procedurally.
*Add sound effects and background music to enhance the gaming experience.

## NETLOGO FEATURES

*This model utilizes breeds to represent different types of agents, such as the player, enemies, obstacles, etc.
*The game mechanics are implemented using agent behaviors, including movement, attacking, and collision detection.
*The game interface makes use of buttons, patches, and links to provide user interaction and visual feedback.

## RELATED MODELS

NetLogo Models Library: "Fire", "Base", "person soldier", "monster","Bullet", "crate"

## CREDITS AND REFERENCES

*Game developed by Helmi Ben Romdhane
*The NetLogo modeling environment: https://ccl.northwestern.edu/netlogo/
*NetLogo Models Library: https://ccl.northwestern.edu/netlogo/models/
*Classmates
*Youtubers
*ChatGpt
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

base
false
0
Polygon -2674135 true false 60 270 75 255 75 105 225 105 225 255 240 270 255 255 255 45 45 45 45 255 60 270 75 255
Polygon -10899396 true false 105 30 150 90 195 30 105 30
Circle -7500403 true true 45 225 30
Circle -7500403 true true 225 225 30

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

bullet
true
0
Circle -1184463 true false 120 75 60
Rectangle -1184463 true false 120 105 180 165
Polygon -1184463 true false 120 165 120 195 150 180 180 195 180 165

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

crate
false
0
Rectangle -7500403 true true 45 45 255 255
Rectangle -16777216 false false 45 45 255 255
Rectangle -16777216 false false 60 60 240 240
Line -16777216 false 180 60 180 240
Line -16777216 false 150 60 150 240
Line -16777216 false 120 60 120 240
Line -16777216 false 210 60 210 240
Line -16777216 false 90 60 90 240
Polygon -7500403 true true 75 240 240 75 240 60 225 60 60 225 60 240
Polygon -16777216 false false 60 225 60 240 75 240 240 75 240 60 225 60

cup
false
0
Rectangle -6459832 true false 45 255 255 300
Polygon -1184463 true false 75 255 75 240 105 225 120 210 120 180 135 165 120 150 90 105 75 60 90 45 210 45 225 60 210 105 180 150 165 165 180 180 180 210 195 225 225 240 225 255 75 255
Polygon -16777216 true false 105 45 90 60 105 75 195 75 210 60 195 45 105 45
Polygon -955883 true false 150 90 135 105 120 105 135 120 135 135 150 120 165 135 165 120 180 105 165 105 150 90
Rectangle -16777216 true false 90 270 210 285

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

drop
false
0
Circle -7500403 true true 73 133 152
Polygon -7500403 true true 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -7500403 true true 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

logs
false
0
Polygon -7500403 true true 15 241 75 271 89 245 135 271 150 246 195 271 285 121 235 96 255 61 195 31 181 55 135 31 45 181 49 183
Circle -1 true false 132 222 66
Circle -16777216 false false 132 222 66
Circle -1 true false 72 222 66
Circle -1 true false 102 162 66
Circle -7500403 true true 222 72 66
Circle -7500403 true true 192 12 66
Circle -7500403 true true 132 12 66
Circle -16777216 false false 102 162 66
Circle -16777216 false false 72 222 66
Circle -1 true false 12 222 66
Circle -16777216 false false 30 240 30
Circle -1 true false 42 162 66
Circle -16777216 false false 42 162 66
Line -16777216 false 195 30 105 180
Line -16777216 false 255 60 165 210
Circle -16777216 false false 12 222 66
Circle -16777216 false false 90 240 30
Circle -16777216 false false 150 240 30
Circle -16777216 false false 120 180 30
Circle -16777216 false false 60 180 30
Line -16777216 false 195 270 285 120
Line -16777216 false 15 240 45 180
Line -16777216 false 45 180 135 30

monster
false
0
Polygon -7500403 true true 75 150 90 195 210 195 225 150 255 120 255 45 180 0 120 0 45 45 45 120
Circle -16777216 true false 165 60 60
Circle -16777216 true false 75 60 60
Polygon -7500403 true true 225 150 285 195 285 285 255 300 255 210 180 165
Polygon -7500403 true true 75 150 15 195 15 285 45 300 45 210 120 165
Polygon -7500403 true true 210 210 225 285 195 285 165 165
Polygon -7500403 true true 90 210 75 285 105 285 135 165
Rectangle -7500403 true true 135 165 165 270

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -955883 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.5
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
