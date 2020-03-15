; TODO:
; * Make world resizale with resize-world and set-patch-size
; * Implement shot leading

; #################
; BREED DEFINITIONS
; #################

breed [ zombies zombie ]
breed [ humans human ]
breed [ projectiles projectile ]
breed [ dead-zombies dead-zombie ]
breed [ dead-humans dead-human ]
breed [ dead-projectiles dead-projectile ]

directed-link-breed [ zombie-targets zombie-target ]

zombies-own [run-speed attack-style target]
humans-own [ run-speed projectile-type projectile-range projectile-speed projectile-inaccuracy projectiles-remaining projectile-cooldown cooldown-timer jam-rate ]
projectiles-own [ hit projectile-type projectile-range projectile-speed projectile-inaccuracy projectiles-remaining traveled ]
dead-projectiles-own [ hit projectile-type ]

; ################
; SETUP PROCEDURES
; ################

; Sets all values on interface screen to defaults
to reset
  set ticks-per-second (15)
  set show-number-projectiles (true)
  set scenario ("charge")
  set zombie-charge-clumpness (25)
  set human-charge-clumpness (25)
  set zombie-attack-style ("nearest-human")
  set human-move-style ("zone-evasion")
  set human-zone-evasion-radius (20)
  set human-launch-style ("nearest")
  set num-zombies (50)
  set num-sock-humans (5)
  set num-blaster-humans (5)
  set zombie-speed (20)
  set human-speed (15)
  set zombie-tag-range (2)
  set zombie-hit-box-radius (2)
  set starting-socks (10)
  set sock-speed (35)
  set sock-range (35)
  set sock-cooldown (1)
  set sock-inaccuracy (5)
  set sock-jam-rate (0)
  set starting-darts (30)
  set dart-speed (80)
  set dart-range (50)
  set dart-cooldown (0.5)
  set dart-inaccuracy (25)
  set dart-jam-rate (5)
  ; TODO: Set all value to defaults
end

; Prepares simulation for running
to setup
  clear-all
  ; Setup patches
  ask patches [ set pcolor green ]
  ; Setup humans and zombies
  create-zombies num-zombies [ init-zombie ]
  create-humans num-sock-humans [ init-sock-human ]
  create-humans num-blaster-humans [ init-blaster-human ]
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
      ask zombies [ random-normal-placement (0) (zombie-charge-clumpness) (max-pycor / 2) (zombie-charge-clumpness / 4) ]
      ask humans [ random-normal-placement (0) (human-charge-clumpness) (0) (human-charge-clumpness / 4) ]
    ]
    ; Distributes all humans and zombies randomly.
    (scenario = "random") [
      ask zombies [setxy random-xcor random-ycor]
      ask humans [setxy random-xcor random-ycor]
    ]
  )
end

; ###############
; INIT PROCEDURES
; ###############

; Creates a zombie
to init-zombie
  set shape "person"
  set size 6 ; 6 feet tall
  set color red
  set run-speed (zombie-speed / ticks-per-second)
  set attack-style (zombie-attack-style)
end

; Creates a human
to init-human
  set shape "person"
  set size 6 ; 6 feet tall
  set run-speed (human-speed / ticks-per-second)
  set cooldown-timer 0
end

; Creates a sock human
to init-sock-human
  init-human
  set projectile-type "sock"
  set color blue + 1
  set projectile-range (sock-range)
  set projectile-speed (sock-speed / ticks-per-second)
  set projectile-inaccuracy (sock-inaccuracy)
  set projectiles-remaining (starting-socks)
  set projectile-cooldown (sock-cooldown)
  set jam-rate (sock-jam-rate) / 100
  ifelse show-number-projectiles
  [ set label projectiles-remaining ]
  [ set label "" ]
end

; Creates a blaster human
to init-blaster-human
  init-human
  set projectile-type "blaster"
  set color blue
  set projectile-range (dart-range)
  set projectile-speed (dart-speed / ticks-per-second)
  set projectile-inaccuracy (dart-inaccuracy)
  set projectiles-remaining (starting-darts)
  set projectile-cooldown (dart-cooldown)
  set jam-rate (dart-jam-rate) / 100
  ifelse show-number-projectiles
  [ set label projectiles-remaining ]
  [ set label "" ]
end

; Creates a projectile
to init-projectile
  set shape "circle"
  set size 1
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
  ; If there are no humans or no zombies, stop.
  if (count (humans) = 0) or (count (zombies) = 0) [ stop ]
  ; Ask each breed to perform action, presuming there are enemies remaining
  ask zombies [ if count (humans) > 0 [ zombie-ai ] ]
  ask humans [ if count (zombies) > 0 [ human-ai ] ]
  ask projectiles [ if count (zombies) > 0 [ projectile-ai ] ]
  ; Iterate
  tick
end

; ################
; ZOMBIE PROCEDURES
; ################

; Zombie decision making
to zombie-ai
  zombie-move
  kill-human
end

; Zombie moves according to movement mode
to zombie-move
  (ifelse
    (attack-style = "nearest-human") [ zombie-move-nearest-human ]
    (attack-style = "targeting-individual") [ zombie-move-targeting-individual ]
  )
end

; Zombie finds nearest human and runs at them
to zombie-move-nearest-human
  let nearest-human (min-one-of humans [distance myself])
  ; If there is not a link with the nearest human, kill all links and create one
  if not (zombie-target-neighbor? nearest-human)[
    ask my-zombie-targets [ die ]
    create-zombie-target-to nearest-human
  ]
  ; Run towards nearest human
  face nearest-human
  fd run-speed
end

; All zombies pick a single target and chases them
to zombie-move-targeting-individual
  ; If there is no target, pick a new horde target
  ; TODO: Pick human closest to Horde center of gravity
  ; TODO: Pick human closest to any zombie
  if ( count (zombie-target-neighbors) = 0 ) [ pick-new-horde-target ]
  ; Face zombie-target and charge them
  face one-of zombie-target-neighbors
  fd run-speed
end

; Horde selects a single target randomly and charges them
to pick-new-horde-target
  ask zombie-targets [ die ]
  let horde-target one-of humans
  ask zombies [ create-zombie-target-to ([horde-target] of myself) ]
end

; Kills target if in range
to kill-human
  if distance (one-of zombie-target-neighbors) <= zombie-tag-range [
    ask one-of zombie-target-neighbors [
      hatch-dead-humans 1 [ init-dead-human ]
      die
    ]
  ]
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
    (human-move-style = "nearest") [ human-move-nearest ]
    (human-move-style = "zone-evasion") [ human-move-zone-evasion ]
  )
end

; Human moves directly away from nearest zombie
to human-move-nearest
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

; Human shoots according to shooting mode
to human-launch
  ; Only execute if cooldown is over and projectiles remain.
  if (cooldown-timer <= 0) and (projectiles-remaining > 0) [
    (ifelse
      (human-launch-style = "nearest") [ human-launch-nearest ]
      ; TODO Add more launch styles
    )
  ]
  ; Reduce cooldown, regardless of firing
  set cooldown-timer (cooldown-timer - 1 / ticks-per-second)
end

; Human launches a projectile at a zombie if within range
to human-launch-nearest
  let nearest-zombie (min-one-of zombies [distance myself])
  if (distance nearest-zombie <= projectile-range) [
    human-launch-utility (towards nearest-zombie)
  ]
end

; Utility function used by all launchers
to human-launch-utility [direction]
  ; Checks for random jam
  ifelse (random-float (1) <= jam-rate) [
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
end

to update-human-label
  ifelse show-number-projectiles [
    set label projectiles-remaining
  ]
  [
    set label ""
  ]
end

; #####################
; PROJECTILE PROCEDURES
; #####################

to projectile-ai
  ; Creates agentset of zombies within hitbox of the projectile or in the direct line of fire.
  let agentset-1 ( zombies in-radius (zombie-hit-box-radius))
  let agentset-2 ( zombies in-cone projectile-speed 180 with [ (distance-from-line (xcor) (ycor) (heading)) <= zombie-hit-box-radius ] )
  let nearby-zombies ( turtle-set (agentset-1) (agentset-2) )
  ; If there are any nearby zombies, select nearest one to stun.
  ifelse count (nearby-zombies) > 0 [
    let nearest-zombie (min-one-of nearby-zombies [distance myself])
    ; If the nearest zombie is within projectile range, stun it.
    ifelse ((distance nearest-zombie) <= (projectile-range - traveled)) [
      fd (distance nearest-zombie) ; Not 100% accurate, but close enough as the implement then dies.
      stun-zombie nearest-zombie
    ]
    [ ; If not in range, projectile moves then dies.
      fd (projectile-range - traveled)
      hatch-dead-projectiles (1) [ init-dead-projectile ]
      die
    ]
  ]
  [ ; If no nearby zombies, move forwards and update
    fd (projectile-speed)
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

; ##################
; UTILITY PROCEDURES
; ##################

to-report agentset-center-of-mass [agentset]
  let xcg mean ([xcor] of agentset )
  let ycg mean ([ycor] of agentset )
  report list (xcg) (ycg)
end

to-report distance-from-line [x y h]
  report 1
  ; report sqrt(((xcor - x) - sin(h) * ((ycor - y) * cos(h) + (xcor - x) * sin(h) ) )^2 + ((ycor - y) - cos(h) * ((ycor - y) * cos(h) + (xcor - x) * sin(h)))^2)
end

; Randomly places turtles according to normal distribution, limited by boundaries
to random-normal-placement [xmean xstd ymean ystd]
  let x min (list (max (list (random-normal (xmean) (xstd)) (min-pxcor))) (max-pxcor))
  let y min (list (max (list (random-normal (ymean) (ystd)) (min-pycor))) (max-pycor))
  setxy (x) (y)
end
@#$#@#$#@
GRAPHICS-WINDOW
441
19
1013
832
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
-100
100
1
1
1
ticks
60.0

BUTTON
156
51
279
84
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
293
50
405
83
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
239
123
436
156
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
239
157
436
190
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
240
256
437
289
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
240
290
437
323
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
240
324
437
357
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
240
358
437
391
zombie-hit-box-radius
zombie-hit-box-radius
0
5
3.7
0.1
1
ft
HORIZONTAL

SLIDER
26
641
223
674
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
26
607
223
640
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
26
675
223
708
sock-cooldown
sock-cooldown
0
5
1.0
0.1
1
s
HORIZONTAL

SLIDER
24
115
221
148
ticks-per-second
ticks-per-second
1
100
15.0
1
1
ticks/s
HORIZONTAL

CHOOSER
26
411
223
456
human-move-style
human-move-style
"nearest" "zone-evasion"
1

SLIDER
26
457
223
490
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
26
573
223
606
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
24
217
221
262
scenario
scenario
"charge" "random"
0

SWITCH
24
149
221
182
show-number-projectiles
show-number-projectiles
0
1
-1000

SLIDER
26
709
223
742
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
1044
35
1119
80
Shots Fired
count projectiles + count dead-projectiles
17
1
11

MONITOR
1044
80
1119
125
Shots Hit
count dead-projectiles with [ hit ]
17
1
11

MONITOR
1194
125
1268
170
Dart Hit Rate
(count dead-projectiles with [ (hit) and (projectile-type = \"blaster\") ]) / ( count projectiles with [ projectile-type = \"blaster\" ] + count dead-projectiles with [ projectile-type = \"blaster\" ])
3
1
11

PLOT
1046
181
1288
429
Shots Fired vs Shots Hit
Ticks
Count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Shots Fired" 1.0 0 -13345367 true "" "plot (count projectiles + count dead-projectiles)"
"Shots Hit" 1.0 0 -2674135 true "" "plot count dead-zombies"

SLIDER
239
190
436
223
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
236
573
433
606
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
236
607
433
640
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
236
641
433
674
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
236
675
434
708
dart-cooldown
dart-cooldown
0
5
0.5
0.1
1
s
HORIZONTAL

SLIDER
236
709
434
742
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
1192
35
1266
80
Darts Fired
count projectiles with [ projectile-type = \"blaster\" ] + count dead-projectiles with [ projectile-type = \"blaster\" ]
17
1
11

MONITOR
1117
35
1192
80
Socks Fired
count projectiles with [ projectile-type = \"sock\" ] + count dead-projectiles with [ projectile-type = \"sock\" ]
17
1
11

MONITOR
1193
80
1266
125
Darts Hit
count dead-projectiles with [ (hit) and (projectile-type = \"blaster\") ]
17
1
11

MONITOR
1118
80
1193
125
Socks Hit
count dead-projectiles with [ (hit) and ( projectile-type = \"sock\" ) ]
17
1
11

MONITOR
1118
125
1194
170
Sock Hit Rate
(count dead-projectiles with [ (hit) and (projectile-type = \"sock\") ]) / ( count projectiles with [ projectile-type = \"sock\" ] + count dead-projectiles with [ projectile-type = \"sock\" ] )
3
1
11

MONITOR
1044
125
1118
170
Hit Rate
(count dead-projectiles with [ hit ]) / ( count projectiles + count dead-projectiles )
3
1
11

PLOT
1313
185
1513
430
Zombies Remaining
Count
Ticks
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count zombies"

PLOT
1526
187
1820
433
Humans Remaining
Count
Ticks
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Humans" 1.0 0 -13345367 true "" "plot count humans"
"Sock Humans" 1.0 0 -13840069 true "" "plot count humans with [ projectile-type = \"sock\" ]"
"Blaster Humans" 1.0 0 -5825686 true "" "plot count humans with [ projectile-type = \"blaster\" ]"

MONITOR
1424
37
1537
82
Humans Dead
count dead-humans
17
1
11

MONITOR
1424
82
1537
127
Sock Humans Dead
count dead-humans with [ projectile-type = \"sock\" ]
17
1
11

MONITOR
1424
127
1537
172
Blaster Humans Dead
count dead-humans with [ projectile-type = \"blaster\" ]
17
1
11

MONITOR
1308
37
1424
82
Humans Alive
count humans
17
1
11

MONITOR
1308
82
1424
127
Sock Humans Alive
count humans with [ projectile-type = \"sock\" ]
17
1
11

MONITOR
1308
127
1424
172
Blaster Humans Alive
count humans with [ projectile-type = \"blaster\" ]
17
1
11

MONITOR
1537
37
1649
82
Fatailty Rate
count dead-humans / ( count humans + count dead-humans )
3
1
11

MONITOR
1537
82
1649
127
Sock Fataility Rate
count dead-humans with [ projectile-type = \"sock\" ] / ( count humans with [ (projectile-type = \"sock\") ] + count dead-humans with [ (projectile-type = \"sock\") ])
3
1
11

MONITOR
1537
127
1649
172
Blaster Fataility Rate
count dead-humans with [ projectile-type = \"blaster\" ] / ( count humans with [ projectile-type = \"blaster\" ] + count dead-humans with [ projectile-type = \"blaster\" ] )
17
1
11

SLIDER
26
743
223
776
sock-jam-rate
sock-jam-rate
0
100
0.0
1
1
%
HORIZONTAL

SLIDER
236
743
434
776
dart-jam-rate
dart-jam-rate
0
100
3.0
1
1
%
HORIZONTAL

CHOOSER
26
365
223
410
zombie-attack-style
zombie-attack-style
"nearest-human" "targeting-individual"
0

TEXTBOX
26
93
236
115
Simulation Settings
18
0.0
1

TEXTBOX
25
193
175
215
Scenario Settings
18
0.0
1

TEXTBOX
27
340
177
364
AI Settings
18
0.0
1

TEXTBOX
240
95
438
118
Faction Count Settings
18
0.0
1

TEXTBOX
240
233
425
257
Player Abillity Settings
18
0.0
1

TEXTBOX
29
547
179
569
Sock Settings
18
0.0
1

TEXTBOX
236
546
386
568
Blaster Settings
18
0.0
1

BUTTON
31
51
143
84
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
26
491
223
536
human-launch-style
human-launch-style
"nearest"
0

SLIDER
24
263
221
296
zombie-charge-clumpness
zombie-charge-clumpness
0
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
24
296
221
329
human-charge-clumpness
human-charge-clumpness
0
50
25.0
1
1
NIL
HORIZONTAL

TEXTBOX
144
25
344
47
Simulation Controls
18
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
