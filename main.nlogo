; #################
; BREED DEFINITIONS
; #################


breed [ humans human ]
breed [ zombies zombie ]
breed [ projectiles projectile ]
breed [ dead-humans dead-human ]
breed [ dead-zombies dead-zombie ]
breed [ dead-projectiles dead-projectile ]

directed-link-breed [ zombie-targets zombie-target ]


humans-own [ run-speed move-style projectile-type projectile-range projectile-speed projectile-inaccuracy projectiles-remaining projectile-cooldown cooldown-timer jam-rate launch-range jammed ]
zombies-own [run-speed move-style ]
projectiles-own [ hit projectile-type projectile-range projectile-speed projectile-inaccuracy projectiles-remaining traveled ]
dead-humans-own [ projectile-type ]
dead-projectiles-own [ hit projectile-type ]

; ################
; SETUP PROCEDURES
; ################

; Sets all values on interface screen to defaults
to reset
  set ticks-per-second (30)
  set show-number-projectiles (true)
  set show-zombie-targets (true)
  set real-time (true)
  set scenario ("charge")
  set human-charge-spread (15)
  set zombie-charge-spread (25)
  set human-move-style ("hit-and-run")
  set human-jammed-move-style ("nearest-zombie")
  set human-zone-evasion-radius (20)
  set human-launch-style ("shot-leading")
  set sock-launch-range (35)
  set dart-launch-range (50)
  set zombie-move-style ("nearest-human")
  set horde-target-style ("CG")
  set num-sock-humans (5)
  set num-blaster-humans (5)
  set num-zombies (50)
  set human-speed (15)
  set zombie-speed (20)
  set zombie-tag-range (2)
  set zombie-hitbox-radius (2)
  set starting-socks (10)
  set sock-speed (35)
  set sock-range (35)
  set sock-cooldown (1.5)
  set sock-inaccuracy (5)
  set sock-jam-rate (0)
  set starting-darts (30)
  set dart-speed (80)
  set dart-range (50)
  set dart-cooldown (1)
  set dart-inaccuracy (25)
  set dart-jam-rate (1)
end

; Prepares simulation for running
to setup
  clear-all
  ; Setup patches
  ask patches [ set pcolor green ]
  ; Setup humans and zombies
  create-humans num-sock-humans [ init-sock-human ]
  create-humans num-blaster-humans [ init-blaster-human ]
  create-zombies num-zombies [ init-zombie ]
  ; Places humans and zombies
  place-humans-and-zombies
  ; Reset ticks to 0
  reset-ticks
end

; Places all humans and zombies according to scenario
to place-humans-and-zombies
  (ifelse
    ; Distribute all humans and zombies according to normal distributions, seperated by a quarter of the field
    (scenario = "charge") [
      ask humans [ random-normal-placement (0) (human-charge-spread) (0) (human-charge-spread / 4) ]
      ask zombies [ random-normal-placement (0) (zombie-charge-spread) (max-pycor * 3 / 4) (zombie-charge-spread / 4) ]
    ]
    ; Distributes all humans and zombies randomly.
    (scenario = "random") [
      ask humans [setxy random-xcor random-ycor]
      ask zombies [setxy random-xcor random-ycor]
    ]
  )
end

; ###############
; INIT PROCEDURES
; ###############

; Creates a human
to init-human
  set shape "person"
  set size patch-size ; 1 foot (think top of head)
  set run-speed (human-speed / ticks-per-second)
  set move-style (human-move-style)
  set cooldown-timer 0
  set jammed false
  ifelse show-number-projectiles
  [ set label projectiles-remaining ]
  [ set label "" ]
end

; Creates a sock human
to init-sock-human
  set projectile-type "sock"
  set color blue + 1
  set projectile-range (sock-range)
  set projectile-speed (sock-speed / ticks-per-second)
  set projectile-inaccuracy (sock-inaccuracy)
  set projectiles-remaining (starting-socks)
  set projectile-cooldown (sock-cooldown)
  set jam-rate (sock-jam-rate / 100)
  set launch-range (sock-launch-range)
  init-human
end

; Creates a blaster human
to init-blaster-human
  set projectile-type "blaster"
  set color blue
  set projectile-range (dart-range)
  set projectile-speed (dart-speed / ticks-per-second)
  set projectile-inaccuracy (dart-inaccuracy)
  set projectiles-remaining (starting-darts)
  set projectile-cooldown (dart-cooldown)
  set jam-rate (dart-jam-rate) / 100
  set launch-range (dart-launch-range)
  init-human
end

; Creates a zombie
to init-zombie
  set shape "person"
  set size patch-size ; 1 foot (think top of head)
  set color red
  set run-speed (zombie-speed / ticks-per-second)
  set move-style (zombie-move-style)
end

; Creates a projectile
to init-projectile
  set shape "circle"
  set size 0.25 * patch-size ; 0.25 ft
  set color yellow
  set hit (false)
  set traveled 0
  rt ((random projectile-inaccuracy) - projectile-inaccuracy / 2) ; Randomly turn +/-(inacccuracy/2)
  set label ""
end

; Create dead human
to init-dead-human
  set shape "person"
  set color blue - 3
end

; Create dead zombie
to init-dead-zombie
  set shape "person"
  set color red - 3
end

; Create dead projectile
to init-dead-projectile
  set shape "circle"
  set color yellow - 3
end

; ##############
; RUN PROCEDURES
; ##############

; Function repeats until end
to go
  ; Resets time for loop
  reset-timer
  ; If there are no humans or no zombies, stop.
  if (count (humans) = 0) or (count (zombies) = 0) [ stop ]
  ; Ask each breed to perform their actions, presuming there are enemies remaining
  ask zombies [ if count (humans) > 0 [ zombie-ai ] ]
  ask humans [ if count (zombies) > 0 [ human-ai ] ]
  ask projectiles [ if count (zombies) > 0 [ projectile-ai ] ]
  ; If real time, Loops until timer runs out
  if (real-time) [ while [ timer < (1 / ticks-per-second) ] [ ] ]
  ; Iterate
  tick
end

; ################
; HUMAN PROCEDURES
; ################

; Human decision making
to human-ai
  human-move
  human-launch
  update-human-label
end

; Human moves according to movement mode
to human-move
  (ifelse
    (move-style = "nearest-zombie") [ human-move-nearest-zombie ]
    (move-style = "zone-evasion") [ human-move-zone-evasion ]
    (move-style = "hit-and-run") [ human-move-hit-and-run ]
  )
end

; Human moves directly away from nearest zombie
to human-move-nearest-zombie
  let nearest-zombie (min-one-of zombies [distance myself])
  face nearest-zombie
  rt 180
  fd run-speed
end

; Human moves away from center-of-mass of nearby zombies.
to human-move-zone-evasion
  ; Select all zombies within radius
  let zone-zombies zombies in-radius human-zone-evasion-radius
  if any? zone-zombies [
    let xy (agentset-center-of-mass (zombies))
    ; Face CG then turn around and run
    facexy (item 0 xy) (item 1 xy)
    rt 180
    fd run-speed
  ]
end

; Human moves towards zombies if they are out of range and away if they are in range
to human-move-hit-and-run
  let nearest-zombie (min-one-of zombies [ distance myself ])
  ; Face zombie. Then move forwards or backwards to set distance (nearest-zombie) = launch-range
  face nearest-zombie
  fd min (list (run-speed) (max (list (- run-speed) ( distance (nearest-zombie) - launch-range ) ) ) )
end

; Human shoots according to shooting mode
to human-launch
  ; Only execute if cooldown is over and projectiles remain.
  if (cooldown-timer <= 0) and (projectiles-remaining > 0) and (not jammed) [
    (ifelse
      (human-launch-style = "nearest-zombie") [ human-launch-nearest-zombie ]
      (human-launch-style = "shot-leading") [ human-launch-shot-leading ]
      ; TODO Add more launch styles
    )
  ]
  ; Reduce cooldown, regardless of firing
  set cooldown-timer (cooldown-timer - 1 / ticks-per-second)
end

; Human launches a projectile at nearest zombie in launch range
to human-launch-nearest-zombie
  let nearest-zombie (min-one-of zombies [distance myself])
  if (distance nearest-zombie <= launch-range) [
    human-launch-utility (towards nearest-zombie)
  ]
end

; Human launches a projectile at nearest zombie in launch range, accounting for shot leading.
to human-launch-shot-leading
  ; Identify nearest zombie
  let nearest-zombie (min-one-of zombies [distance myself])
  ; Initialize variables
  let x ( ([xcor] of nearest-zombie) - xcor )
  let y ( ([ycor] of nearest-zombie) - ycor )
  let h ( subtract-headings (90) ([heading] of nearest-zombie) )
  let sz ( [run-speed] of nearest-zombie )
  let sp ( projectile-speed )
  ; Calculate impact time and location
  let impact-time ( - ( 2 * x * sz * Cos (h) + 2 * y * sz * Sin (h) ) - Sqrt ( ( 2 * x * sz * Cos (h) + 2 * y * sz * Sin(h) ) ^ 2 - 4 * ( sz ^ 2 - sp ^ 2 ) * ( x ^ 2 + y ^ 2 ) ) ) / ( 2 * ( sz ^ 2 - sp ^ 2 ) )
  let xt ( x + Cos (h) * sz * impact-time )
  let yt ( y + Sin (h) * sz * impact-time )
  ; Identify shot angle
  let theta ( Atan (xt) (yt) )
  ; If impact location is within range, shoot.
  if Sqrt ( xt ^ 2 + yt ^ 2 ) <= launch-range [
    human-launch-utility ( theta )
  ]
end

; Utility function used by all launchers
to human-launch-utility [direction]
  ; Checks for random jam
  ifelse (random-float (1) <= jam-rate) [
    set jammed (true)
    set projectiles-remaining (0)
  ]
  [  ; If blaster doesn't jam, "Hatch projectile", inheriting all relevant properties of Human, including position and projectile properties
    hatch-projectiles 1 [
      init-projectile
      set heading direction
    ]
    set cooldown-timer (projectile-cooldown)
    set projectiles-remaining (projectiles-remaining - 1)
  ]
  ; If human can no longer fire, swap movement.
  if (jammed) or (projectiles-remaining = 0) [
    set move-style (human-jammed-move-style)
  ]

end

to update-human-label
  ifelse (not show-number-projectiles) [
    set label ""
  ]
  [ ifelse jammed [
    set label ("X")
    ]
    [
      set label projectiles-remaining
    ]
  ]
end

; #####################
; PROJECTILE PROCEDURES
; #####################

to projectile-ai
  ; Creates agentset of zombies within hitbox of the projectile or in the direct line of fire within range.
  let agentset-1 ( zombies in-radius (zombie-hitbox-radius))
  let agentset-2 ( zombies in-cone min( list (projectile-speed) (projectile-range - traveled) ) 180 with [ (distance-from-line (xcor) (ycor) (heading)) <= zombie-hitbox-radius ] )
  let nearby-zombies ( turtle-set (agentset-1) (agentset-2) )
  ; If there are any nearby zombies, select nearest one to stun.
  ifelse count (nearby-zombies) > 0 [
    let nearest-zombie (min-one-of nearby-zombies [distance myself])
    fd (distance nearest-zombie) ; Not 100% accurate, but close enough as the implement then dies.
    stun-zombie nearest-zombie
  ]
  [ ; If no nearby zombies, move forwards and update. Limit movement to total range
    fd (min (list (projectile-speed) (projectile-range - traveled)) )
    set traveled (traveled + projectile-speed)
    if traveled >= projectile-range [
      hatch-dead-projectiles (1) [ init-dead-projectile ]
      die
    ]
  ]
end

to stun-zombie [target-zombie]
  ask target-zombie [
    hatch-dead-zombies (1) [ init-dead-zombie ]
    die
  ]
  hatch-dead-projectiles (1) [
    init-dead-projectile
    set hit true
  ]
  die
end

; ################
; ZOMBIE PROCEDURES
; ################

; Zombie decision making
to zombie-ai
  zombie-move
  zombie-tag
  zombie-update-links
end

; Zombie moves according to movement mode
to zombie-move
  (ifelse
    (move-style = "nearest-human") [ zombie-move-nearest-human ]
    (move-style = "horde-target") [ zombie-move-horde-target ]
  )
end

; Zombie finds nearest human and runs at them
to zombie-move-nearest-human
  let nearest-human (min-one-of humans [distance myself])
  ; If there is not a link with the nearest human, kill my links and create one to nearest human
  if not (zombie-target-neighbor? nearest-human)[
    ask my-zombie-targets [ die ]
    create-zombie-target-to nearest-human
  ]
  ; Run towards nearest human
  face nearest-human
  fd run-speed
end

; All zombies pick a single target and chases them
to zombie-move-horde-target
  ; If there is no target, create one if it is the first tick.
  if ( count (zombie-target-neighbors) = 0) [
    ifelse ( ticks = 0 ) [
      zombie-pick-horde-target
    ]
    [ ; Otherwise, revert to nearest-human.
      ask zombies [
        set move-style ("nearest-human")
        create-zombie-target-to (min-one-of humans [distance myself])
      ]
    ]
  ]
  ; Face zombie-target and charge them
  face one-of zombie-target-neighbors
  fd run-speed
end

; Pick horde target according to target-style
to zombie-pick-horde-target
  (ifelse
    (horde-target-style = "random") [
      let horde-target one-of humans
      ask zombies [ create-zombie-target-to ([horde-target] of myself) ]
    ]
    (horde-target-style = "CG") [
      let horde-CG (agentset-center-of-mass (zombies))
      let horde-target min-one-of humans [ distancexy ([item (0) (horde-CG) ] of myself) ([item (1) (horde-CG) ] of myself) ]
      ask zombies [ create-zombie-target-to ([horde-target] of myself) ]
    ]
    (horde-target-style = "nearest-human") [
      let horde-target min-one-of humans [ distance ( min-one-of zombies [ distance myself ] ) ]
      ask zombies [ create-zombie-target-to ([horde-target] of myself) ]
    ]
  )
end


; Kills target if in range
to zombie-tag
  if distance (one-of zombie-target-neighbors) <= zombie-tag-range [
    ask one-of zombie-target-neighbors [
      hatch-dead-humans 1 [ init-dead-human ]
      die
    ]
  ]
end

; Shows or hides link based on user input
to zombie-update-links
  ifelse show-zombie-targets [
    ask zombie-targets [ show-link ]
  ]
  [
    ask zombie-targets [ hide-link ]
  ]
end

; ##################
; UTILITY PROCEDURES
; ##################

to-report agentset-center-of-mass [agentset]
  let xcg mean ([xcor] of agentset )
  let ycg mean ([ycor] of agentset )
  report list (xcg) (ycg)
end

to-report distance-from-line [x y h]
  report sqrt( ((xcor - x) - sin(h) * ((ycor - y) * cos(h) + (xcor - x) * sin(h))) ^ 2 + ((ycor - y) - cos(h) * ((ycor - y) * cos(h) + (xcor - x) * sin(h))) ^ 2)
end

; Randomly places turtles according to normal distribution, limited by boundaries
to random-normal-placement [xmean xstd ymean ystd]
  let x min (list (max (list (random-normal (xmean) (xstd)) (min-pxcor))) (max-pxcor))
  let y min (list (max (list (random-normal (ymean) (ystd)) (min-pycor))) (max-pycor))
  setxy (x) (y)
end
@#$#@#$#@
GRAPHICS-WINDOW
647
10
1219
583
-1
-1
4.0
1
12
1
1
1
0
0
0
1
-70
70
-70
70
1
1
1
ticks
60.0

BUTTON
144
36
267
69
Reset Simulation
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
281
35
393
68
Run Simulation
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
228
170
425
203
num-zombies
num-zombies
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
228
102
425
135
num-sock-humans
num-sock-humans
0
25
5.0
1
1
NIL
HORIZONTAL

SLIDER
228
268
425
301
zombie-speed
zombie-speed
0
50
20.0
1
1
ft/s
HORIZONTAL

SLIDER
228
234
425
267
human-speed
human-speed
0
50
15.0
1
1
ft/s
HORIZONTAL

SLIDER
228
302
425
335
zombie-tag-range
zombie-tag-range
0
5
2.0
0.1
1
ft
HORIZONTAL

SLIDER
228
336
425
369
zombie-hitbox-radius
zombie-hitbox-radius
0
5
2.0
0.1
1
ft
HORIZONTAL

SLIDER
440
170
637
203
sock-range
sock-range
0
100
35.0
1
1
ft
HORIZONTAL

SLIDER
440
136
637
169
sock-speed
sock-speed
0
100
35.0
1
1
ft/s
HORIZONTAL

SLIDER
440
204
637
237
sock-cooldown
sock-cooldown
0
5
1.5
0.1
1
s
HORIZONTAL

SLIDER
12
100
209
133
ticks-per-second
ticks-per-second
1
100
30.0
1
1
ticks/s
HORIZONTAL

CHOOSER
12
421
209
466
human-move-style
human-move-style
"nearest-zombie" "zone-evasion" "hit-and-run"
2

SLIDER
12
513
209
546
human-zone-evasion-radius
human-zone-evasion-radius
0
50
20.0
1
1
ft
HORIZONTAL

SLIDER
440
102
637
135
starting-socks
starting-socks
0
100
10.0
1
1
NIL
HORIZONTAL

CHOOSER
10
275
207
320
scenario
scenario
"charge" "random"
0

SWITCH
12
134
209
167
show-number-projectiles
show-number-projectiles
0
1
-1000

SLIDER
440
238
637
271
sock-inaccuracy
sock-inaccuracy
0
45
5.0
1
1
degrees
HORIZONTAL

MONITOR
1236
17
1311
62
Shots Fired
count projectiles + count dead-projectiles
17
1
11

MONITOR
1236
63
1311
108
Shots Hit
count dead-projectiles with [ hit ]
17
1
11

MONITOR
1388
155
1463
200
Dart Hit Rate
count dead-projectiles with [ (hit) and (projectile-type = \"blaster\") ] / count dead-projectiles with [ projectile-type = \"blaster\" ]
3
1
11

PLOT
1238
214
1575
462
Projectiles
Time (s)
Projectiles
0.0
0.1
0.0
0.1
true
true
"" ""
PENS
"Projectiles Fired" 1.0 0 -13345367 true "" "plotxy (ticks / ticks-per-second) (count projectiles + count dead-projectiles)"
"Projectiles Hit" 1.0 0 -2674135 true "" "plotxy (ticks / ticks-per-second) (count dead-projectiles with [ hit ])"
"Projectiles Missed" 1.0 0 -7500403 true "" "plotxy (ticks / ticks-per-second) (count dead-projectiles with [ not hit ])"
"Projectiles In Air" 1.0 0 -955883 true "" "plotxy (ticks / ticks-per-second) (count projectiles)"
"Projectiles Remaining" 1.0 0 -6459832 true "" "plotxy (ticks / ticks-per-second) (sum [projectiles-remaining] of humans)"

SLIDER
228
136
425
169
num-blaster-humans
num-blaster-humans
0
25
5.0
1
1
NIL
HORIZONTAL

SLIDER
438
339
635
372
starting-darts
starting-darts
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
438
373
635
406
dart-speed
dart-speed
0
100
80.0
1
1
ft/s
HORIZONTAL

SLIDER
438
407
635
440
dart-range
dart-range
0
100
50.0
1
1
ft
HORIZONTAL

SLIDER
438
441
636
474
dart-cooldown
dart-cooldown
0
5
1.0
0.1
1
s
HORIZONTAL

SLIDER
438
475
636
508
dart-inaccuracy
dart-inaccuracy
0
45
25.0
1
1
degrees
HORIZONTAL

MONITOR
1388
17
1463
62
Darts Fired
count projectiles with [ projectile-type = \"blaster\" ] + count dead-projectiles with [ projectile-type = \"blaster\" ]
17
1
11

MONITOR
1312
17
1387
62
Socks Fired
count projectiles with [ projectile-type = \"sock\" ] + count dead-projectiles with [ projectile-type = \"sock\" ]
17
1
11

MONITOR
1388
63
1463
108
Darts Hit
count dead-projectiles with [ (hit) and (projectile-type = \"blaster\") ]
17
1
11

MONITOR
1312
63
1387
108
Socks Hit
count dead-projectiles with [ (hit) and ( projectile-type = \"sock\" ) ]
17
1
11

MONITOR
1312
155
1387
200
Sock Hit Rate
count dead-projectiles with [ (hit) and (projectile-type = \"sock\") ] / count dead-projectiles with [ projectile-type = \"sock\" ]
3
1
11

MONITOR
1236
155
1311
200
Hit Rate
count dead-projectiles with [ hit ] / count dead-projectiles
3
1
11

PLOT
1586
466
1876
711
Zombies Remaining
Time (s)
Zombies
0.0
0.1
0.0
0.1
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plotxy (ticks / ticks-per-second) (count zombies)"

PLOT
1584
215
1878
461
Humans Remaining
Time (s)
Humans
0.0
0.1
0.0
0.1
true
true
"" ""
PENS
"Humans" 1.0 0 -13345367 true "" "plotxy (ticks / ticks-per-second) (count humans)"
"Sock Humans" 1.0 0 -13840069 true "" "plotxy (ticks / ticks-per-second) ( count humans with [ projectile-type = \"sock\" ] )"
"Blaster Humans" 1.0 0 -5825686 true "" "plotxy (ticks / ticks-per-second) ( count humans with [ projectile-type = \"blaster\" ] )"

MONITOR
1587
18
1700
63
Humans Dead
count dead-humans
17
1
11

MONITOR
1587
64
1700
109
Sock Humans Dead
count dead-humans with [ projectile-type = \"sock\" ]
17
1
11

MONITOR
1587
110
1700
155
Blaster Humans Dead
count dead-humans with [ projectile-type = \"blaster\" ]
17
1
11

MONITOR
1470
18
1586
63
Humans Alive
count humans
17
1
11

MONITOR
1470
64
1586
109
Sock Humans Alive
count humans with [ projectile-type = \"sock\" ]
17
1
11

MONITOR
1470
110
1586
155
Blaster Humans Alive
count humans with [ projectile-type = \"blaster\" ]
17
1
11

MONITOR
1701
18
1813
63
Fatailty Rate
count dead-humans / ( count humans + count dead-humans )
3
1
11

MONITOR
1701
64
1813
109
Sock Fataility Rate
count dead-humans with [ projectile-type = \"sock\" ] / ( count humans with [ (projectile-type = \"sock\") ] + count dead-humans with [ (projectile-type = \"sock\") ])
3
1
11

MONITOR
1701
110
1813
155
Blaster Fataility Rate
count dead-humans with [ projectile-type = \"blaster\" ] / ( count humans with [ projectile-type = \"blaster\" ] + count dead-humans with [ projectile-type = \"blaster\" ] )
17
1
11

SLIDER
440
272
637
305
sock-jam-rate
sock-jam-rate
0
10
0.0
0.1
1
%
HORIZONTAL

SLIDER
438
509
636
542
dart-jam-rate
dart-jam-rate
0
10
1.0
0.1
1
%
HORIZONTAL

CHOOSER
12
661
209
706
zombie-move-style
zombie-move-style
"nearest-human" "horde-target"
0

TEXTBOX
14
78
224
100
Simulation Settings
18
0.0
1

TEXTBOX
11
251
161
273
Scenario Settings
18
0.0
1

TEXTBOX
13
398
163
422
AI Settings
18
0.0
1

TEXTBOX
228
80
426
103
Faction Count Settings
18
0.0
1

TEXTBOX
228
211
413
235
Player Abillity Settings
18
0.0
1

TEXTBOX
440
78
590
100
Sock Settings
18
0.0
1

TEXTBOX
438
312
588
334
Blaster Settings
18
0.0
1

BUTTON
19
36
131
69
Reset Settings
reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
12
547
209
592
human-launch-style
human-launch-style
"nearest-zombie" "shot-leading"
1

SLIDER
10
355
207
388
zombie-charge-spread
zombie-charge-spread
0
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
10
321
207
354
human-charge-spread
human-charge-spread
0
50
15.0
1
1
NIL
HORIZONTAL

TEXTBOX
132
10
332
32
Simulation Controls
18
0.0
1

CHOOSER
12
467
209
512
human-jammed-move-style
human-jammed-move-style
"nearest-zombie" "zone-evasion" "hit-and-run"
0

SLIDER
12
593
209
626
sock-launch-range
sock-launch-range
0
sock-range
35.0
1
1
ft
HORIZONTAL

SLIDER
12
627
209
660
dart-launch-range
dart-launch-range
0
dart-range
50.0
1
1
ft
HORIZONTAL

SWITCH
12
168
209
201
show-zombie-targets
show-zombie-targets
0
1
-1000

MONITOR
1236
109
1311
154
Shots Missed
count dead-projectiles with [ not hit ]
17
1
11

MONITOR
1312
109
1387
154
Socks Missed
count dead-projectiles with [ (not hit) and (projectile-type = \"sock\") ]
17
1
11

MONITOR
1388
109
1463
154
Darts Missed
count dead-projectiles with [ (not hit) and (projectile-type = \"blaster\") ]
17
1
11

SWITCH
12
202
209
235
real-time
real-time
0
1
-1000

CHOOSER
12
707
209
752
horde-target-style
horde-target-style
"random" "CG" "nearest-human"
1

@#$#@#$#@
# HUMANS VS ZOMBIES

# TO DO LIST

## Implement realistic movement
#### Description
Currently, humans and zombies move at up to their max run-speed in any direction. In reality, it takes time to change speed and direction.
#### Challenges
* Finding literature on how quickly people can move in different directions
* Implmenting velocity and acceleration

## Implement realistic targeting
#### Description
Currently, humans can fire in any direction on a dime. In reality, blaster users have a significant disadvantage compared to sock users do to the challenge of shooting behind them.
#### Potential solutions
* Implementing "firing arcs" and "turret heading" that reset every time a shot is fired.

## Implement realistic awareness
#### Description
Currently, humans and zombies are aware of all other humans and zombies. In reality, people have blind spots.

## Make world resizale with resize-world and set-patch-size
#### Challenges
* Changes size of world in interface
#### Potential Solutions
* Make categorical work sizes. Don't give those pesty users full control.

## Make players not stick to walls
#### Potential Solutions
* Implementing a "deterance" from being close to the wall
* May use "can-move?"

## Implement "Anti-gravity" human AI

## Implement more sophisticated zombie AI
#### Potential Solutions
* Look into "Birb" flocking mechanics 

# MODEL DESCRIPTION

This model simulates the popular campus game Humans vs Zombies. The model is intended to simulate a single fight between the Humans and Zombies.

## Quick Start

The model starts out unloaded. Start by pressing “Reset Simulation”. This will setup the agents to run a single simulation. Press “Run Simulation” to run the model. When the simulation is complete, press “Reset Simulation” to revert. Press “Reset Settings” to set settings to default values.

## Humans vs Zombies Quick Rules
Humans vs Zombies is a campus-wide game of tag. Players act as either a Human or a Zombie as they try to survive the Zombie Apocalypse or grow the size of the Horde. Zombies attempt to tag Humans to turn them into Zombies, while Humans defend themselves with stunning implements, including sock balls and Nerf blasters.

Zombies play by attempting to "tag" humans. When a Human is tagged by a Zombie, they die and are resurrected as a Zombie.

Humans play by defending themselves from Zombies by "stunning" them. A human either throws a sock or launches a dart from a blaster at a Zombie. If the zombie is hit by the projectile, they are "stunned" and wait a period of time before resurrecting. 

## Turtles

There are six breeds of turtles in the model: `human`, `zombie`, `projectile`, and a "dead" version for each of the previous breed.

# MODEL PROCEDURES

The model starts by initializing the setup. All the turtles are created and placed. The model the takes turns each tick executing zombie procedures, human procedures, and projectile procedures, in order. The simulation ends when when "Run Simulation" is turned off, there are no more humans, or there are no more zombies.

To best visualize the discrete, ordered nature of the simulation, set "view updates" on the top ribbon to "continuous" and set "speed" to "slower", around 25%. This will show that the zombies move, then the humans, then the projectiles.

## Initialization

The model starts the simulation by creating and placing the humans and zombies. The humans and zombies are placed according to *scenario*. There are two scenarios currently implemented: `charge` and `random`.

#### Scenario: `charge`

Humans and zombies are set up on in two separate clumps according to a normal distribution. The zombies are set up around the point `(0, max-xcor / 2)` while the humans are set up around the point `(0, 0)`. The standard deviation of the distribution in the x direction is given as `zombie/human-charge-spread` while the y direction is given as `zombie/human-charge-spread / 4`. This difference in standard deviations creates the "gun-line" spread normally experienced in charges.

#### Scenario: `random`

Humans and zombies are set up at completely random x and y coordinates. This could be used to simulate a chaotic encounter without structure. 

## Human

During each iteration, humans follow the following procedure:

1. Move according to procedure dictated by `human-move-style`
2. Attempt to launch a projectile according to procedure dictated by `human-launch-style`

### Human Movement

#### Human Move Style

Humans move according to procedure defined by `human-move-style`. There are three move styles currently implemented: `nearest-zombie`, `zone-evasion`, and `hit-and-run`.

If a human runs out of ammo or is jammed, they update their `move-style` to the move style defined by `human-jammed-move-style`.

#### Human Move Style: `nearest-zombie`

The human moves directly away from the nearest zombie. 

#### Human Move Style: `zone-evasion`

The human identifies all zombies within a radius defined by `human-zone-evasion-radius` and moves directly away from the center of mass of the zombies.

#### Human Move Style: `hit-and-run`

The human moves to keep the nearest zombie at a distance equivalent to `launch-range`. The human moves backward or forwards until the nearest zombie is exactly on the launch range.

### Human Launching

To launch a projectile, the human must meet the following criteria:

1. The human is not "cooling down"
2. The human still has projectiles to launch

If a human meets both of these criteria, it will attempt to launch a projectile according to procedure defined by `human-launch-style`. There is one launch style currently implemented: `nearest-zombie-in-range`.

#### Cooldown

Every time a human launches a projectile, it's `cooldown-timer` will reset to `projectile-cooldown`. This represents the amount of time that must pass before the human can take another shot. Every time a human attempts to launch a projectile, even if it fails, the cooldown timer is reduced by the time step. A human is considered "cooled down" when `cooldown-timer <= 0`.

#### Jams

Every time a human attempts to launch a projectile, there is a random chance that they "jam". This represents the random chance that blaster misfires during an engagement. This is not usually a case for sock users, though it could model them dropping all their socks on accident.

Each human is assigned a `jam-rate` according to their projectile type. The jam is modeled by comparing `jam-rate` to a randomly generated number between 0 and 1. If the number is less than the `jam-rate`, `jammed` is set to `true` and `projectiles-remaining` is set to `0`.

A `jam-rate` of 5% corresponds to a jam on average every 12.5 shots while a `jam-rate` of 1% corresponds to a jam on average every 68.0 shots. The equation for average number of shots before jam for a given jam rate is `shots = ( ln(0.5) / ln(1 - jam-rate) ) - 1`. This equation is the inverse of the geometric cumulative distribution function.

#### Human Launch Style: `nearest-zombie`

The human will identify the closest zombie that is within `launch-range`. If there exists a zombie within this range, the human will launch a projectile at its current location. If not, the human will not launch a projectile. This procedure uses `launch-range` instead of `projectile-range` to allow for finer tuning of shot doctrine.

#### Human Launch Style: `shot-leading`

The human will identify the closest zombie. The human will identify the `impact-time`, location (`xt` and `yt`), and direction (`theta`) of hitting the closest zombie if they do not change their direction. If the distance is within `launch-range`, the human will alunch a projectile at the impact location. If not, the human will not launch a projectile.

## Zombie

During each iteration, zombies follow the following procedure:

1. Move according to procedure dictated by `zombie-move-style`
2. Attempt to tag target human

### Zombie Targets

At the moment, all zombie move styles use a mechanic for identifying its target using a `zombie-target` link. A zombie target link is a directional link between the zombie and a human that it is currently targeting. Currently, zombie target links are created in the movement procedures according to `zombie-move-style`.

### Zombie Movement

Zombies move according to procedure defined by `zombie-move-style`. There are two move styles currently implemented: `nearest-human` and `targeting`.

#### Zombie Move Style: `nearest-human`

The zombie will identify the closest human. The closes human will be set as the zombie's only `zombie-target` link. The zombie will move directly towards the closest human.

#### Zombie Move Style: `horde-targeting`

A single human will be identified as the horde target according to procedure defined by `horde-target-style`. All zombies will create a `zombie-target` link with this single human. When this human is tagged, zombies will revert to `nearest-human` move style. There are three targeting styles currently implemented: `random`, `CG`, and `nearest-human`.

* `random`: The horde target will be chosen at random from all available humans.

* `CG`: The human closest to the "center of gravity" of the horde will be chosen as the horde target.

* `nearest-human`: The human closest to any given zombie will be chosen as the horde target.

### Zombie Tagging

The zombie will attempt to tag its currently targeted human. If the targeted human is within range dictated by `zombie-tag-range`, the human is marked as dead and replaced with a `dead-human`.

## Projectiles

During each iteration, projectiles follow the following procedure:

The projectile starts by identifying all zombies that satisfy either of the following criteria:

   * Zombie is within `zombie-hitbox-radius` of projectiles starting point.
   * Zombie is within a cone of radius `min of (projectile-speed) and (projectile-range - traveled)` and withing `zombie-hitbox-radius` of the line of travel of the projectile.

The first criteria ensures that all zombies that might slip past the projectile due to the discrete event nature of the simulation are considered. The second criteria ensure that all zombies along the line of path of the projectile are considered. A cone combined with distance from line are used as rotated rectangular area selection of zombies is not included in NetLogo. The radius of the cone is selected as the minimum of `projectile-speed` and `projectile-range - traveled` to ensure that the implement does not stun a zombie outside of it's range.

If there is a zombie that satisfies these criteria, the projectile finds the closest one, moves to it, and stuns it. The zombie is marked as dead and is replaced with a `dead-zombie`.

If there is not a zombie that satisfies these criteria, the projectile travels forwards the minimum of `projectile-speed` and `projectile-range - traveled`. The distance traveled is updated. If `projectile-range = traveled`, the projectile dies and is replaced with a `dead-projectile`.


# MODEL SETTINGS

The function of all the settings on the interface tab are described below. Default values are shown in (parentheses). Units are shown in [brackets].

## Simulation Settings
* **ticks-per-second (15)**: Number of discrete time-steps that occur per second (Hz).
* **show-number-projectiles (true)**: Show number of remaining projectiles next to human sprite. Shows *X* if human experiences a jam.
* **show-zombie-targets (true)**: Shows links between zombies and their target humans.

## Scenario Settings
* **scenario ("charge")**: Select setup of humans and zombies. Options: "charge", "random".
* **zombie/human-charge-spread (25)**: Measure of how spread out the humans and zombies are in "charge" scenario. Directly related to standard deviation of a normal function.

## AI Settings
* **zombie-attack-style ("nearest-human")**: Select attack style of zombies.  Options: "nearest-human", "targeting".
* **human-move-style ("hit-and-run")**: Select movement style of humans. Options: "nearest-zombie", "zone-evasion", "hit-and-run".
* **human-jammed-move-style ("zone-evasion")**: Select movement style of a human when out of ammo. Options: "nearest-zombie", "zone-evasion", "hit-and-run".
* **human-zone-evasion-radius (20) [ft]**: Radius of circle detailing which zombies the human will evade in "zone-evasion" mode. 
* **human-launch-style ("nearest-zombie-in-range")**: Select launch style of humans. Options: "nearest-zombie-in-range".
* **sock/dart-launch-range [%]**: Range where a human will launch projectile. Defaulted to range of projectile.
 
## Faction Count Settings
* **num-zombies (50)**: Number of zombies
* **num-sock-humans (5)**: Number of sock humans
* **num-blaster-humans (5)**: Number of blaster humans

## Player Ability Settings
* **zombie-speed (20) [ft/s]**: Movement speed of a zombie
* **human-speed (15) [ft/s]**: Movement speed of a human
* **zombie-tag-range (2) [ft]**: Distance a zombie can tag a human from
* **zombie-hitbox-radius (2) [ft]**: Distance a stunning implement can stun a zombie from

## Sock/Blaster Settings
* **starting-socks/darts (10 / 30)**: Number of socks/darts a human starts with
* **sock/dart-speed (35 / 80) [ft/s]**: Movement speed of socks/darts
* **sock/dart-range (35 / 50) [ft]**: Total range of socks/darts
* **sock/dart-cooldown (1 / 0.5) [s]**: How long a human must wait to fire sock/dart
* **sock/dart-inaccuracy (5 / 25) [degrees]**: Range of inaccuracy for sock/dart
* **sock/dart-jam-rate (0 / 3) [%]**: How often firing a sock/dart results in a jam

# CREDITS AND REFERENCES

Website: https://scottnealon.github.io/HumansVsZombies/
GitHub Repository: https://github.com/ScottNealon/HumansVsZombies/

Special thanks to Scott Nealon, Josh Netter, Sriram Ganesan, and Adithya Nott
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
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

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

line half
true
0
Line -7500403 true 150 0 150 150

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
NetLogo 6.1.1
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
