globals
[
  tick-delta                         ;; how much we advance the tick counter this time through
  max-tick-delta                     ;; the largest tick-delta is allowed to be
  min-tick-delta                     ;; the smallest tick-delta is allowed to be
  init-avg-speed init-avg-energy     ;; initial averages
  avg-speed avg-energy               ;; current averages
  fast medium slow                   ;; current counts
  percent-fast percent-medium        ;; percentage of the counts
  percent-slow                       ;; percentage of the counts

  collision-times                    ;; a list that of times of pending collisions
]

breed [ particles particle ]

particles-own
[
  vx vy vz                   ;; velocities rel axes
  speed mass energy          ;; particle info
  collision-time             ;; to determine when collision is
  collision-with             ;; to determine who the collision is with
  last-collision             ;; so they don't collide with one another many times
]

to setup
  ca
  set-default-shape particles "circle"
  set tick-delta .01
  set min-tick-delta .0000001
  make-particles
  check-initial-positions
  update-variables
  set init-avg-speed avg-speed
  set init-avg-energy avg-energy
  setup-histograms
  do-plotting
  if trace?
  [ ask one-of particles [ pd ] ]
end

to go
  set collision-times [] ;; empty this out for new input
  ask particles
  [
    set collision-time tick-delta
    set collision-with nobody
    if collide? [ detect-collisions ]
  ]

  ifelse( empty? collision-times )
  [ set collision-times lput ( tick-delta ) collision-times ]
  [ set collision-times ( sort collision-times ) ]

    ifelse ( first collision-times ) < tick-delta   ;; if something will collide before the tick
    [
      ask particles [ jump speed * ( first collision-times ) ] ; most particles to first collision
      tick-advance ( first collision-times ) ;; now, collide all the particles that are ready
      ask particles with [ collision-time = ( first collision-times ) ] [
        if collision-with > who [ ;; so that we don't collide the same particles twice
            collide ( turtle collision-with )
            set last-collision collision-with
            ask turtle collision-with [ set last-collision [who] of myself ]
        ]
      ]
    ] [
      ask particles [ jump speed * tick-delta ]
      tick-advance tick-delta
    ]

  ask particles [
    if last-collision != nobody
    [
      if distance turtle last-collision > ( ( ( [size] of turtle last-collision ) / 2 ) + ( size / 2 ) ) * 1.5
      [ set last-collision nobody ]
    ]
  ]

  if floor ticks > floor (ticks - tick-delta) [
    update-variables
    do-plotting
  ]

  display
end

to update-variables
  set medium count particles with [ speed < ( 1.5 * 10 ) and speed > ( 0.5 * 10 ) ]
  set slow count particles with [ speed < ( 0.5 * 10 ) ]
  set fast count particles with [ speed > ( 1.5 * 10 ) ]
  set percent-medium (medium / count particles) * 100
  set percent-slow (slow / count particles) * 100
  set percent-fast (fast / count particles) * 100
  set avg-speed  mean [speed] of particles
  set avg-energy  mean [energy] of particles
end


;;;
;;; distance and collision procedures
;;;

to detect-collisions ; particle procedure

;; detect-collisions is a particle procedure that determines the time it takes to the collision between
;; two particles (if one exists).  It solves for the time by representing the equations of motion for
;; distance, velocity, and time in a quadratic equation of the vector components of the relative velocities
;; and changes in position between the two particles and solves for the time until the next collision

  let my-x xcor
  let my-y ycor
  let my-z zcor
  let my-particle-size size
  let my-x-speed (x-velocity heading pitch speed )
  let my-y-speed (y-velocity heading pitch speed )
  let my-z-speed (z-velocity pitch speed )
  let my-last-collision last-collision

  ask other particles with [who != my-last-collision]
  [
    let dpx 0
    let dpy 0
    let dpz 0

    ;; since our world is wrapped, we can't just use calcs like xcor - my-x. Instead, we take the smallest
    ;; of either the wrapped or unwrapped distance for each dimension

    ifelse ( abs ( xcor - my-x ) <= abs ( ( xcor - my-x ) - world-width ) )
      [ set dpx (xcor - my-x) ]
      [ set dpx (xcor - my-x) - world-width ]  ;; relative distance between particles in the x direction
    ifelse ( abs ( ycor - my-y ) <= abs ( ( ycor - my-y ) - world-height ) )
      [ set dpy (ycor - my-y) ]
      [ set dpy (ycor - my-y) - world-height ]    ;; relative distance between particles in the y direction
    ifelse ( abs ( zcor - my-z ) <= abs ( ( zcor - my-z ) - world-depth ) )
      [ set dpz (zcor - my-z) ]
      [ set dpz (zcor - my-z) - world-depth ]       ;; relative distance between particles in the z direction

    let x-speed (x-velocity heading pitch speed ) ;; speed of other particle in the x direction
    let y-speed (y-velocity heading pitch speed ) ;; speed of other particle in the y direction
    let z-speed (z-velocity pitch speed )         ;; speed of other particle in the z direction

    let dvx (x-speed - my-x-speed) ;; relative speed difference between particles in the x direction
    let dvy (y-speed - my-y-speed) ;; relative speed difference between particles in the y direction
    let dvz (z-speed - my-z-speed) ;; relative speed difference between particles in the z direction

    let sum-r (((my-particle-size) / 2 ) + (([size] of self) / 2 )) ;; sum of both particle radii

    ;; To figure out what the difference in position (P1) between two particles at a future time (t) would be,
    ;; one would need to know the current difference in position (P0) between the two particles
    ;; and the current difference in the velocity (V0) between of the two particles.

    ;; The equation that represents the relationship would be:   P1 = P0 + t * V0

    ;; we want find when in time (t), P1 would be equal to the sum of both the particle's radii (sum-r).
    ;; When P1 is equal to is equal to sum-r, the particles will just be touching each other at
    ;; their edges  (a single point of contact).

    ;; Therefore we are looking for when:   sum-r =  P0 + t * V0

    ;; This equation is not a simple linear equation, since P0 and V0 should both have x and y components
    ;;  in their two dimensional vector representation (calculated as dpx, dpy, and dvx, dvy).

    ;; By squaring both sides of the equation, we get:     (sum-r) * (sum-r) =  (P0 + t * V0) * (P0 + t * V0)

    ;;  When expanded gives:   (sum-r ^ 2) = (P0 ^ 2) + (t * PO * V0) + (t * PO * V0) + (t ^ 2 * VO ^ 2)

    ;;  Which can be simplified to:    0 = (P0 ^ 2) - (sum-r ^ 2) + (2 * PO * V0) * t + (VO ^ 2) * t ^ 2

    ;;  Below, we will let p-squared represent:   (P0 ^ 2) - (sum-r ^ 2)
    ;;  and pv represent: (2 * PO * V0)
    ;;  and v-squared represent: (VO ^ 2)

    ;;  then the equation will simplify to:     0 = p-squared + pv * t + v-squared * t^2

    let p-squared   ((dpx * dpx) + (dpy * dpy) + (dpz * dpz)) - (sum-r ^ 2)   ;; p-squared represents difference of the
    ;; square of the radii and the square
    ;; of the initial positions

    let pv  (2 * ((dpx * dvx) + (dpy * dvy) + (dpz * dvz)))  ;;the vector product of the position times the velocity
    let v-squared  ((dvx * dvx) + (dvy * dvy) + (dvz * dvz)) ;; the square of the difference in speeds
    ;; represented as the sum of the squares of the x-component
    ;; and y-component of relative speeds between the two particles

    ;; p-squared, pv, and v-squared are coefficients in the quadratic equation shown above that
    ;; represents how distance between the particles and relative velocity are related to the time,
    ;; t, at which they will next collide (or when their edges will just be touching)

    ;; Any quadratic equation that is the function of time (t), can represented in a general form as:
    ;;   a*t*t + b*t + c = 0,
    ;; where a, b, and c are the coefficients of the three different terms, and has solutions for t
    ;; that can be found by using the quadratic formula.  The quadratic formula states that if a is not 0,
    ;; then there are two solutions for t, either real or complex.

    ;; t is equal to (b +/- sqrt (b^2 - 4*a*c)) / 2*a

    ;; the portion of this equation that is under a square root is referred to here
    ;; as the determinant, D1.   D1 is equal to (b^2 - 4*a*c)
    ;; and:   a = v-squared, b = pv, and c = p-squared.

    let D1 pv ^ 2 -  (4 * v-squared * p-squared)

    ;; the next line next line tells us that a collision will happen in the future if
    ;; the determinant, D1 is >= 0,  since a positive determinant tells us that there is a
    ;; real solution for the quadratic equation.  Quadratic equations can have solutions
    ;; that are not real (they are square roots of negative numbers).  These are referred
    ;; to as imaginary numbers and for many real world systems that the equations represent
    ;; are not real world states the system can actually end up in.

    ;; Once we determine that a real solution exists, we want to take only one of the two
    ;; possible solutions to the quadratic equation, namely the smaller of the two the solutions:

    ;;  (b - sqrt (b^2 - 4*a*c)) / 2*a
    ;;  which is a solution that represents when the particles first touching on their edges.

    ;;  instead of (b + sqrt (b^2 - 4*a*c)) / 2*a
    ;;  which is a solution that represents a time after the particles have penetrated
    ;;  and are coming back out of each other and when they are just touching on their edges.


    let time-to-collision  -1

    if D1 >= 0
      [set time-to-collision (- pv - sqrt D1) / (2 * v-squared) ]        ;;solution for time step

    ;; if time-to-collision is still -1 there is no collision in the future - no valid solution
    ;; note:  negative values for time-to-collision represent where particles would collide
    ;; if allowed to move backward in time.
    ;; if time-to-collision is greater than 1, then we continue to advance the motion
    ;; of the particles along their current trajectories.  They do not collide yet.
    ;; to keep the model from slowing down too much, if the particles are going to collide
    ;; at a time before min-tick-delta, just collide them a min-tick-delta instead

    if ( time-to-collision < tick-delta and time-to-collision > min-tick-delta ) [
      set collision-with ( [who] of myself )
      set collision-time ( time-to-collision )
      set collision-times ( lput ( time-to-collision ) collision-times )
    ]
    if ( time-to-collision < min-tick-delta and time-to-collision > 0 ) [
      set collision-with ( [who] of myself )
      set collision-time ( min-tick-delta )
      set collision-times ( lput ( min-tick-delta ) collision-times )
    ]
  ]
end

to collide [ particle2 ] ;; turtle procedure
  update-component-vectors
  ask particle2 [ update-component-vectors ]

  ;; find heading and pitch from the center of particle1 to the center of particle2
  let theading towards particle2
  let tpitch towards-pitch particle2

  ;; use these to determine the x, y, z components of theta
  let tx x-velocity theading tpitch 1
  let ty y-velocity theading tpitch 1
  let tz z-velocity tpitch 1

  ;; find the speed of particle1 in the direction of n
  let particle1totheta ortho-projection vx vy vz tx ty tz

  ;; express particle1's movement along theta in terms of xyz
  let x1totheta particle1totheta * tx
  let y1totheta particle1totheta * ty
  let z1totheta particle1totheta * tz

  ;; now we can find the x, y and z components of the particle's velocity that
  ;; aren't in the direction of theta by subtracting the x, y, and z
  ;; components of the velocity in the direction of theta from the components
  ;; of the overall velocity of the particle
  let x1opptheta ( ( vx ) - ( x1totheta ) )
  let y1opptheta ( ( vy ) - ( y1totheta ) )
  let z1opptheta ( ( vz ) - ( z1totheta ) )

  ;; do the same for particle2
  let particle2totheta ortho-projection [vx] of particle2 [vy] of particle2 [vz] of particle2 tx ty tz

  let x2totheta particle2totheta * tx
  let y2totheta particle2totheta * ty
  let z2totheta particle2totheta * tz

  let x2opptheta ( ( [vx] of particle2 ) - ( x2totheta ) )
  let y2opptheta ( ( [vy] of particle2 ) - ( y2totheta ) )
  let z2opptheta ( ( [vz] of particle2 ) - ( z2totheta ) )

  ;; calculate the velocity of the center of mass along theta
  let vcm ( ( ( mass * particle1totheta ) + ( [mass] of particle2 * particle2totheta ) )
      / ( mass + [mass] of particle2 ) )

  ;; switch momentums along theta
  set particle1totheta (2 * vcm - particle1totheta)
  set particle2totheta (2 * vcm - particle2totheta)

  ;; determine the x, y, z components of each particle's new velocities
  ;; in the direction of theta
  set x1totheta particle1totheta * tx
  set y1totheta particle1totheta * ty
  set z1totheta particle1totheta * tz

  set x2totheta particle2totheta * tx
  set y2totheta particle2totheta * ty
  set z2totheta particle2totheta * tz

  ;; now, we add the new velocities along theta to the unchanged velocities
  ;; opposite theta to determine the new heading, pitch, and speed of each particle
  set vx x1totheta + x1opptheta
  set vy y1totheta + y1opptheta
  set vz z1totheta + z1opptheta
  set heading vheading vx vy vz
  set pitch vpitch vx vy vz
  set speed vspeed vx vy vz
  set energy ( 0.5 * mass * speed ^ 2 )
  if particle-color = "red-green-blue" [ recolor ]
  if particle-color = "purple shades" [ recolorshade ]
  if particle-color = "one color" [ recolornone ]

  ask particle2 [
    set vx x2totheta + x2opptheta
    set vy y2totheta + y2opptheta
    set vz z2totheta + z2opptheta
    set heading vheading vx vy vz
    set pitch vpitch vx vy vz
    set speed vspeed vx vy vz
    set energy ( 0.5 * mass * speed ^ 2 )
    if particle-color = "red-green-blue" [ recolor ]
    if particle-color = "purple shades" [ recolorshade ]
    if particle-color = "one color" [ recolornone ]
  ]
end


;;;
;;; drawing procedures
;;;

;; creates initial particles
to make-particles
  create-particles number-of-particles
  [
    setup-particle
    random-position
    if particle-color = "red-green-blue" [ recolor ]
    if particle-color = "purple shades" [ recolorshade ]
    if particle-color = "one color" [ recolornone ]
  ]
end

to setup-particle  ;; particle procedure
  set speed init-particle-speed
  set mass particle-mass
  set energy (0.5 * mass * (speed ^ 2))
end

;; makes sure particles aren't overlapped at setup
to check-initial-positions
  let check-again? false
  ask particles [
    if particle-overlap? [
      random-position
      set check-again? true
    ]
  ]
  if check-again? [ check-initial-positions ]
end

to-report particle-overlap? ; particle procedure
  let me ( self )
  let overlap false
  ask other particles [
    if distance ( me ) < ( ( size / 2 ) + ( [size] of me / 2 ) + .1 ) [
      set overlap true
    ]
  ]
  report overlap
end


;; place particle at random location inside the box.
to random-position ;; particle procedure
  setxyz ((1 + min-pxcor) + random-float ((2 * max-pxcor) - 2))
         ((1 + min-pycor) + random-float ((2 * max-pycor) - 2))
         ((1 + min-pzcor) + random-float ((2 * max-pzcor) - 2)) ;; added for 3d
  set heading random-float 360
  set pitch random-float 360
end

to move  ;; particle procedure
  jump (speed * tick-delta)
end

to recolor  ;; particle procedure
  ifelse speed < (0.5 * 10)
  [
    set color blue
  ]
  [
    ifelse speed > (1.5 * 10)
      [ set color red ]
      [ set color green ]
  ]
end

to recolorshade ;; particle procedure
  ifelse speed < 27
  [ set color 111 + speed / 3 ]
  [ set color 119.999 ]
end

to recolornone ;; particle procedure
  set color blue + 1
end


;;;
;;; math procedures
;;;

;; makes sure that the values stored in vx, vy, vz actually reflect
;; the appropriate heading, pitch, speed
to update-component-vectors ;; particle procedure
  set vx ( speed * sin ( heading ) * cos ( pitch ) )
  set vy ( speed * cos ( heading ) * cos ( pitch ) )
  set vz ( speed * sin ( pitch ) )
end

;; reports velocity of a vector at a given angle and pitch
;; in the direction of x.
to-report x-velocity [ vector-angle vector-pitch vector-speed ]
  let xvel sin( vector-angle ) * abs( cos( vector-pitch ) ) * vector-speed
  report xvel
end

;; reports velocity of a vector at a given angle and pitch
;; in the direction of y.
to-report y-velocity [ vector-angle vector-pitch vector-speed ]
  let yvel cos( vector-angle ) * abs( cos( vector-pitch ) ) * vector-speed
  report yvel
end

;; reports velocity of a vector at a given angle and pitch
;; in the direction of z.
to-report z-velocity [ vector-pitch vector-speed ]
  let zvel ( sin( vector-pitch ) * vector-speed )
  report zvel
end

;; reports speed of a vector given xyz coords
to-report vspeed [ x y z ]
  report ( sqrt( x ^ 2 + y ^ 2 + z ^ 2 ) )
end

;; reports xt heading of a vector given xyz coords
to-report vheading [ x y z ]
  report atan x y
end

;; reports pitch of a vector given xyz coords
to-report vpitch [ x y z ]
  report round asin ( z / ( vspeed x y z ) )
end

;; called by ortho-projection
to-report dot-product [ x1 y1 z1 x2 y2 z2 ]
  report ( ( x1 * x2 ) + ( y1 * y2 ) + ( z1 * z2 ) )
end

;; component of 1 in the direction of 2 (Note order)
to-report ortho-projection [ x1 y1 z1 x2 y2 z2 ]
  let dproduct dot-product x1 y1 z1 x2 y2 z2
  let speed-of-2 ( vspeed x2 y2 z2 )
  ;; if speed is 0 then there's no projection anyway
  ifelse ( speed-of-2 > 0 )
  [ report ( dproduct / speed-of-2 ) ]
  [ report 0 ]
end

;;;
;;; plotting procedures
;;;

to setup-histograms
  set-current-plot "Speed Histogram"
  set-plot-x-range 0 (init-particle-speed * 2)
  set-plot-y-range 0 ceiling (number-of-particles / 6)
  set-current-plot-pen "medium"
  set-histogram-num-bars 40
  set-current-plot-pen "slow"
  set-histogram-num-bars 40
  set-current-plot-pen "fast"
  set-histogram-num-bars 40
  set-current-plot-pen "init-avg-speed"
  draw-vert-line init-avg-speed

  set-current-plot "Energy Histogram"
  set-plot-x-range 0 (0.5 * (init-particle-speed * 2) * (init-particle-speed * 2) * particle-mass)
  set-plot-y-range 0 ceiling (number-of-particles / 6)
  set-current-plot-pen "medium"
  set-histogram-num-bars 40
  set-current-plot-pen "slow"
  set-histogram-num-bars 40
  set-current-plot-pen "fast"
  set-histogram-num-bars 40
  set-current-plot-pen "init-avg-energy"
  draw-vert-line init-avg-energy
end


to do-plotting
  set-current-plot "Speed Counts"
  set-current-plot-pen "fast"
  plotxy ticks percent-fast
  set-current-plot-pen "medium"
  plotxy ticks percent-medium
  set-current-plot-pen "slow"
  plotxy ticks percent-slow

  plot-histograms
end

to plot-histograms
  set-current-plot "Energy histogram"
  set-current-plot-pen "fast"
  histogram [ energy ] of particles with [ speed > ( 1.5 * 10 ) ]
  set-current-plot-pen "medium"
  histogram [ energy ] of particles with [ speed < ( 1.5 * 10 ) and speed > ( 0.5 * 10 ) ]
  set-current-plot-pen "slow"
  histogram [ energy ] of particles with [ speed < ( 0.5 * 10 ) ]
  set-current-plot-pen "avg-energy"
  plot-pen-reset
  draw-vert-line avg-energy

  set-current-plot "Speed histogram"
  set-current-plot-pen "fast"
  histogram [ speed ] of particles with [ speed > ( 1.5 * 10 ) ]
  set-current-plot-pen "medium"
  histogram [ speed ] of particles with [ speed < ( 1.5 * 10 ) and speed > ( 0.5 * 10 ) ]
  set-current-plot-pen "slow"
  histogram [ speed ] of particles with [ speed < ( 0.5 * 10 ) ]
  set-current-plot-pen "avg-speed"
  plot-pen-reset
  draw-vert-line avg-speed
end

;; histogram procedure
to draw-vert-line [ xval ]
  plotxy xval plot-y-min
  plot-pen-down
  plotxy xval plot-y-max
  plot-pen-up
end


; Copyright 2006 Uri Wilensky. All rights reserved.
; The full copyright notice is in the Information tab.
@#$#@#$#@
GRAPHICS-WINDOW
0
0
199
220
5
5
5.0
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
-5
5
1
1
1
ticks

BUTTON
162
159
248
192
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
64
159
147
192
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
52
46
258
79
number-of-particles
number-of-particles
1
50
20
1
1
NIL
HORIZONTAL

MONITOR
328
11
468
56
average speed
avg-speed
2
1
11

PLOT
328
310
622
506
Energy Histogram
Energy
Number
0.0
400.0
0.0
10.0
false
true
PENS
"fast" 10.0 1 -2674135 true
"medium" 10.0 1 -10899396 true
"slow" 10.0 1 -13345367 true
"avg-energy" 1.0 0 -7500403 true
"init-avg-energy" 1.0 0 -16777216 true

MONITOR
328
264
477
309
average energy
avg-energy
2
1
11

PLOT
13
309
307
506
Speed Counts
time
count (%)
0.0
20.0
0.0
100.0
true
true
PENS
"fast" 1.0 0 -2674135 true
"medium" 1.0 0 -10899396 true
"slow" 1.0 0 -13345367 true

SWITCH
52
13
155
46
collide?
collide?
0
1
-1000

PLOT
328
57
622
254
Speed Histogram
Speed
Number
0.0
50.0
0.0
100.0
false
true
PENS
"fast" 5.0 1 -2674135 true
"medium" 5.0 1 -10899396 true
"slow" 5.0 1 -13345367 true
"avg-speed" 1.0 0 -7500403 true
"init-avg-speed" 1.0 0 -16777216 true

MONITOR
13
262
103
307
percent fast
percent-fast
0
1
11

MONITOR
104
262
203
307
percent medium
percent-medium
0
1
11

MONITOR
204
262
304
307
percent slow
percent-slow
0
1
11

SWITCH
155
13
258
46
trace?
trace?
1
1
-1000

SLIDER
52
79
258
112
init-particle-speed
init-particle-speed
1.0
20.0
10
1.0
1
NIL
HORIZONTAL

SLIDER
52
112
258
145
particle-mass
particle-mass
1.0
20.0
2
1.0
1
NIL
HORIZONTAL

CHOOSER
19
208
157
253
particle-color
particle-color
"red-green-blue" "purple shades" "one color"
0

BUTTON
177
215
267
248
clear trace
clear-drawing
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

@#$#@#$#@
WHAT IS IT?
-----------
This model is a 3D version of the 2D model Gas Lab Free Gas; it is one in a series of GasLab models.  They use the same basic rules for simulating the behavior of gases.  Each model integrates different features in order to highlight different aspects of gas behavior.

The basic principle of the models is that gas particles are assumed to have two elementary actions: they move and they collide - either with other particles or with any other objects such as walls.

This model is the simplest gas model in the suite of GasLab models.  The particles are moving and colliding with each other with no external constraints, such as gravity or containers. (The world is a torus which means that when a particle hits the edge of the world it "wraps" around to the other side.  The box surrounding the world in the 3D view are not walls but simply mark the edges of the world where the particles will wrap.)

In this model, particles are modeled as perfectly elastic ones with no energy except their kinetic energy -- which is due to their motion.  Collisions between particles are elastic.  Particles are colored according to their speed -- blue for slow, green for medium, and red for high.


HOW IT WORKS
------------
The basic principle of all GasLab models is the following algorithm (for more details, see the model "GasLab Gas in a Box"):

1) A particle moves in a straight line without changing its speed, unless it collides with another particle or bounces off the wall.
2) Two particles "collide" if their surfaces touch.  In this model, the time at which any collision is about to occur is measured, and particles move forward until the first pair to collide touch one another.  They are collided, and the cycle repeats.
3) The vector of collision for the particles describes the direction of the line connecting their centers.
4) The particles exchange momentum and energy only along this line, conforming to the conservation of momentum and energy for elastic collisions.
5) Each particle is assigned its new speed, direction and energy.


HOW TO USE IT
-------------
Initial settings:
- NUMBER-OF-PARTICLES: the number of gas particles.
- TRACE?: Draws the path of one individual particle.
- COLLIDE?: Turns collisions between particles on and off.
- INIT-PARTICLE-SPEED: the initial speed of each particle -- they all start with the same speed.
- PARTICLE-MASS: the mass of each particle -- they all have the same mass.
- PARTICLE-COLOR: indicates the coloring scheme for the particles.

As in most NetLogo models, the first step is to press SETUP. It puts in the initial conditions you have set with the sliders.  Be sure to wait till the SETUP button stops before pushing GO.
The GO button runs the models again and again.  This is a "forever" button.

Monitors:
- PERCENT FAST, PERCENT MEDIUM, PERCENT SLOW monitors: percent of particles with different speeds: fast (red), medium (green), and slow (blue).
- AVERAGE SPEED: average speed of the particles.
- AVERAGE ENERGY: average kinetic energy of the particles.

Plots:
- SPEED COUNTS: plots the number of particles in each range of speed (fast, medium or slow).
- SPEED HISTOGRAM: speed distribution of all the particles.  The gray line is the average value, and the black line is the initial average.  The displayed values for speed are ten times the actual values.
- ENERGY HISTOGRAM: the distribution of energies of all the particles, calculated as (m*v^2)/2.  The gray line is the average value, and the black line is the initial average.

Initially, all the particles have the same speed but random directions. Therefore the first histogram plots of speed and energy should show only one column each.  As the particles repeatedly collide, they exchange energy and head off in new directions, and the speeds are dispersed -- some particles get faster, some get slower, and the plot will show that change.


THINGS TO NOTICE
----------------
What is happening to the numbers of particles of different colors?  Why are there more blue particles than red ones?

Can you observe collisions and color changes as they happen?  For instance, when a red particle hits a green particle, what color do they each become?

Why does the average speed (avg-speed) drop?  Does this violate conservation of energy?

This gas is in "endless space" -- no boundaries, no obstructions, but still a finite size!  Is there a physical situation like this?

Watch the particle whose path is traced, notice how the path "wraps" around the world. Does the trace resemble Brownian motion? Can you recognize when a collision happens?  What factors affect the frequency of collisions?   What about the "angularity" of the path?  Could you get it to stay "local" or travel all over the world?

In what ways is this model an "idealization" of the real world?


THINGS TO TRY
-------------
Set all the particles in part of the world, or with the same heading -- what happens?  Does this correspond to a physical possibility?

Try different settings, especially the extremes.  Are the histograms different?  Does the trace pattern change?

Are there other interesting quantities to keep track of?

Look up or calculate the REAL number, size, mass and speed of particles in a typical gas.  When you compare those numbers to the ones in the model, are you surprised this model works as well as it does?  What physical phenomena might be observed if there really were a small number of big particles in the space around us?

We often say outer space is a vacuum.  Is that really true?  How many particles would there be in a space the size of this computer?


EXTENDING THE MODEL
-------------------
Could you find a way to measure or express the "temperature" of this imaginary gas?  Try to construct a thermometer.

What happens if there are particles of different masses?

How would you define and calculate pressure in this "boundless" space?

What happens if the gas is inside a container instead of a boundless space?

What happens if the collisions are non-elastic?

How does this 3D model differ from the 2D model?

Set up only two particles to collide head-on.  This may help to show how the collision rule works.  Remember that the axis of collision is being randomly chosen each time.

What if some of the particles had a "drift" tendency -- a force pulling them in one direction?  Could you develop a model of a centrifuge, or charged particles in an electric field?

Find a way to monitor how often particles collide, and how far they go, on average, between collisions.  The latter is called the "mean free path".  What factors affect its value?

In what ways is this idealization different from the one used to derive the Maxwell-Boltzmann distribution?  Specifically, what other code could be used to represent the two-body collisions of particles?

If MORE than two particles arrive on the same patch, the current code says they don't collide.  Is this a mistake?  How does it affect the results?

Is this model valid for fluids in any aspect?  How could it be made to be fluid-like?


NETLOGO FEATURES
-----------------
Notice the use of the histogram primitive.


CREDITS AND REFERENCES
----------------------
This was one of the original Connection Machine StarLogo applications (under the name GPCEE) and is now ported to NetLogo as part of the Participatory Simulations project.


HOW TO CITE
-----------
If you mention this model in an academic publication, we ask that you include these citations for the model itself and for the NetLogo software:
- Wilensky, U. (2006).  NetLogo GasLab Free Gas 3D model.  http://ccl.northwestern.edu/netlogo/models/GasLabFreeGas3D.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

In other publications, please use:
- Copyright 2006 Uri Wilensky. All rights reserved. See http://ccl.northwestern.edu/netlogo/models/GasLabFreeGas3D for terms of use.


COPYRIGHT NOTICE
----------------
Copyright 2006 Uri Wilensky. All rights reserved.

Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed:
a) this copyright notice is included.
b) this model will not be redistributed for profit without permission from Uri Wilensky. Contact Uri Wilensky for appropriate licenses for redistribution for profit.

This is a 3D version of the 2D model GasLab Free Gas.

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
Circle -7500403 true true 30 30 240

circle 2
false
0
Circle -7500403 true true 16 16 270
Circle -16777216 true false 46 46 210

clock
true
0
Circle -7500403 true true 30 30 240
Polygon -16777216 true false 150 31 128 75 143 75 143 150 158 150 158 75 173 75
Circle -16777216 true false 135 135 30

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

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
Polygon -7500403 true true 60 270 150 0 240 270 15 105 285 105
Polygon -7500403 true true 75 120 105 210 195 210 225 120 150 75

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
NetLogo 3D 4.1pre1
@#$#@#$#@
set trace? false
setup
orbit-down 45
orbit-right 45
repeat 2000 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="100 runs" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="150"/>
    <metric>percent-fast</metric>
    <metric>percent-medium</metric>
    <metric>percent-slow</metric>
    <enumeratedValueSet variable="trace?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="particle-mass">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-particles">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collide?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init-particle-speed">
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
