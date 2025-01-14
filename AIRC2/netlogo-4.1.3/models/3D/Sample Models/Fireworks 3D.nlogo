turtles-own [ col               ;sets color of an explosion particle
              x-vel             ;x-velocity
              y-vel             ;y-velocity
              z-vel             ;z-velocity
             ]

breed [ rockets rocket ]
breed [ frags frag ]

rockets-own [ terminal-z-vel ] ;velocity at which rocket will explode
frags-own [ dim ]              ;used for fading particles

;SETUP
;-----
;This function clears the graphics window of all patches and turtles.

to setup
  ca
  orbit-down 90
end

;GO
;--
;If there are no turtles, then it creates a random number
;according to the slider FIREWORKS and sets all the initial
;values for each firework.
;It then calls PROJECTILE-MOTION, which launches and explodes the fireworks.

to go
  every delay
  [ launch-rockets ]

 ;we don't want the model to run too quickly because otherwise,
 ;you wouldn't be able to see the fireworks
  every 0.06
  [
    if spin-observer?
      [ orbit-right 2 ]
  ]
  every 0.03
  [
    fall-down
    display
  ]
  if not any? turtles
  [ tick ]
end

to launch-rockets
  if not any? turtles
  [
    cd
    create-rockets random (fireworks + 1)
    [ setxyz random-xcor
      random-ycor
      min-pzcor
      set shape "circle"
      set size 0.1
      set x-vel ((random-float (2 * initial-x-vel)) - (initial-x-vel))
      set y-vel ((random-float (2 * initial-y-vel)) - (initial-y-vel))
      set z-vel ((random-float initial-z-vel) + initial-z-vel * 2 )
      set col ((random 14) + 1) * 10 - 5    ;; reports a random 'primary' color   i.e. 5, 15, 25, etc.
      set color (col + 2)
      set terminal-z-vel (random-float 2.0)     ;; at what speed does the rocket explode?
    ]
  ]
end

to fall-down
  ask rockets [ projectile-motion ]
  ask frags [ projectile-motion ]
  if trails?
  [
    ask frags
      [ set pen-size 2 pd ]
  ]
end

;PROJECTILE-MOTION
;-----------------
;This function simulates the actual free-fall motion of the turtles.
;If a turtle is a rocket it checks if it has slowed down enough to explode.

to projectile-motion               ;; turtle procedure
  set z-vel (z-vel - (gravity / 5))
  kill-wrapped
  setxyz xcor + (x-vel / 10) ycor + (y-vel / 10) zcor + (z-vel / 10)
  ifelse (breed = rockets)
    [ if (z-vel < terminal-z-vel)
       [ explode
         die ]
    ]
    [ fade ]
end


;EXPLODE
;-------
;This is where the explosion is created.
;EXPLODE calls hatch a number of times indicated by the slider FRAGMENTS.

to explode                 ;; turtle procedure
  hatch-frags fragments
    [ set dim 0
      set size 0.1
      set shape "circle"
      tilt-up asin (1.0 - random-float 2.0)
      roll-right random-float 360
      set x-vel (x-vel * .5 + (random-float 2.0) - 1)
      set y-vel (y-vel * .5 + (random-float 2.0) - 1)
      set z-vel (random-float 2.0)
      ifelse trails?
        [ pd ]
        [ pu ]
     ]
end


;FADE
;----
;This function changes the color of a frag.
;Each frag fades its color by an amount proportional to FADE-AMOUNT.

to fade                    ;; frag procedure
  set dim dim - (fade-amount / 10)
  set color scale-color col dim -5 .5
  if ( color < col - 1 )
    [die]
end


;KILL-WRAPPED
;--------
;This function is used to keep the turtles within the vertical bounds of the world.
;If they go above or below the top or bottom of the world kill them.

to kill-wrapped             ;; turtle procedure
  if (zcor + z-vel / 10) > (max-pzcor + 0.4)
    [ die ]
  if (zcor + z-vel / 10) < (min-pzcor - 0.4)
    [ die ]
end


; Copyright 2006 Uri Wilensky. All rights reserved.
; The full copyright notice is in the Information tab.
@#$#@#$#@
GRAPHICS-WINDOW
0
0
197
218
5
5
9.0
1
10
1
1
1
0
1
1
1
-5
5
-5
5
-3
3
1
1
1
ticks

BUTTON
76
76
156
109
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
157
76
237
109
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

SWITCH
35
116
125
149
trails?
trails?
0
1
-1000

SLIDER
37
36
157
69
fireworks
fireworks
1
15
15
1
1
NIL
HORIZONTAL

SLIDER
158
36
278
69
fragments
fragments
5
50
50
1
1
NIL
HORIZONTAL

SLIDER
35
153
155
186
initial-x-vel
initial-x-vel
0.0
2
1
0.1
1
NIL
HORIZONTAL

SLIDER
35
187
155
220
initial-y-vel
initial-y-vel
0.0
2
1
0.1
1
NIL
HORIZONTAL

SLIDER
156
153
276
186
gravity
gravity
0.0
3.0
1
0.1
1
NIL
HORIZONTAL

SLIDER
156
187
276
220
fade-amount
fade-amount
0.0
10.0
2
0.1
1
NIL
HORIZONTAL

SLIDER
35
221
155
254
initial-z-vel
initial-z-vel
0
3
1.5
0.1
1
NIL
HORIZONTAL

SWITCH
127
116
278
149
spin-observer?
spin-observer?
0
1
-1000

SLIDER
156
221
276
254
delay
delay
1
10
5
1
1
NIL
HORIZONTAL

@#$#@#$#@
WHAT IS IT?
-----------
This program models the action of fireworks.  Rockets begin at the bottom of the world, shoot upwards into the sky and then explode, emitting showers of falling sparks.


HOW IT WORKS
------------
Each rocket, represented by a turtle, is launched upward with an initial x y and z velocity.  At a certain point in the sky, an explosion occurs, which is represented by a series of turtle hatches.  Each hatched turtle inherits the velocity from the original rocket in addition to velocity from the explosion itself.  The result is a simulation of a fireworks display.


HOW TO USE IT
-------------
SETUP creates FIREWORKS rockets at the bottom of the screen (MIN-PZCOR). Pressing the GO forever button executes the model continually, launching the rockets. When a rocket hits its peak velocity, it explodes into FRAGMENTS pieces.

GRAVITY determines the gravitational strength in the environment.  A larger value will give a greater gravitational acceleration, meaning that particles will be forced to the ground at a faster rate.  The inverse is true for smaller values.

INITIAL-X-VEL sets the initial x-velocity of each rocket to a random number between the negative and positive value of the number indicated on the slider.

INITIAL-Y-VEL sets the initial y-velocity of each rocket to a random number between the negative and positive value of the number indicated on the slider.

INITIAL-Z-VEL sets the initial z-velocity of each rocket to a random number between 0 and the number indicated on the slider plus ten.  This is to ensure that there is a range of difference in the initial z-velocities of the fireworks.

FADE-AMOUNT determines the rate at which the explosion particles fade after the explosion.

If TRAILS? is true the fragments of each explosion will have their pens down so the paths of each fragment are visible (and they look like real fireworks).

If SPIN-OBSERVER? is on the Observer will spin around the world as the model runs.

The model will launch a new set of rockets every DELAY seconds.

This model has been constructed so that all changes in the sliders and switches will take effect in the model during execution.  So, while the GO button is still down, you can change the values of the sliders and the switch, and you can see these changes in the world.


THINGS TO NOTICE
----------------
Experiment with the INITIAL-X-VEL, INITIAL-Y-VEL, and INITIAL-Z-VEL sliders.  Observe that initial x and y velocities of zero launch the rockets straight upwards.  When the initial x or y velocities are increased, notice that some rockets make an arc in the sky.

With the initial z-velocity, observe that, on a fixed GRAVITY value, the heights of the fireworks are lower on smaller initial z-velocities and higher on larger ones.  Also observe that each rocket explodes at a height equal to or a little less than its apex.


THINGS TO TRY
-------------
Observe what happens to the model when the GRAVITY slider is set to different values.  Watch what happens to the model when GRAVITY is set to zero.  Can you explain what happens to the fireworks in the model?  Can you explain why this phenomenon occurs?  What does this say about the importance of gravity?  Now set the GRAVITY slider to its highest value.  What is different about the behavior of the fireworks at this setting?  What can you conclude about the relationship between gravity and how objects move in space?


EXTENDING THE MODEL
-------------------
The fireworks represented in this model are only of one basic type.  A good way of extending this model would be to create other more complex kinds of fireworks.  Some could have multiple explosions, multiple colors, or a specific shape engineered into their design.


NETLOGO FEATURES
----------------
An important aspect of this model is the fact that each particle from an explosion inherits the properties of the original firework.  This informational inheritance allows the model to adequately represent the projectile motion of the firework particles since their initial x, y, and z velocities are relative to their parent firework.

To visually represent the fading property of the firework particles, this model made use of the reporter 'scale-color'.  As the turtle particles fall to the ground, they hold their pens down and gradually scale their color to black.  As mentioned above, the rate of fade can be controlled using the FADE-AMOUNT slider.


HOW TO CITE
-----------
If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:
- Wilensky, U. (2006).  NetLogo Fireworks 3D model.  http://ccl.northwestern.edu/netlogo/models/Fireworks3D.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

In other publications, please use:
- Copyright 2006 Uri Wilensky. All rights reserved. See http://ccl.northwestern.edu/netlogo/models/Fireworks3D for terms of use.


COPYRIGHT NOTICE
----------------
Copyright 2006 Uri Wilensky. All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:
a) this copyright notice is included.
b) this model will not be redistributed for profit without permission from Uri Wilensky. Contact Uri Wilensky for appropriate licenses for redistribution for profit.

This is a 3D version of the 2D model Fireworks.

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

cylinder
false
0
Circle -7500403 true true 30 30 240

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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 3D 4.1pre10
@#$#@#$#@
set trails? true
set fireworks 30
setup
repeat 50 [ launch-rockets fall-down ]
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
