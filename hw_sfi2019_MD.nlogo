globals
[
  polarizedn ;; how many agents are polarized?
  infected-size ;;the size of the infected agents
]

turtles-own
[
  polarized?  ;; true if agent has been infected
              ;; prob-infected
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;


to generate-topology
  clear-all
  set infected-size 3
  set-default-shape turtles "outlined circle"
  create-turtles num-nodes [reset-node]
  ;; distribute starting conditions

  build-network                                 ;; select network type and build it
  infect-two                                    ;; infect num-nodes nodes and one neighbor for each
  repeat 100 [ layout ]
  reset-ticks                                   ;; reset tick marks
end

;; connects the two nodes
to make-link-between [node1 node2]
  ask node1 [
    create-link-with node2
      [ set color gray + 1.5]                   ;; is this necessary?
  ]
end

to infect-two
    ask turtles
    [reset-node]                                ;; clears colors and polarization
    ask links
    [set color gray + 1.5]

  ;; infect a single agent
  repeat init [ask one-of turtles
  [
    set polarized? true
    ;set prob-infected 1
    set color red
    set size infected-size
    ask one-of link-neighbors [
          set polarized? true
         ;; set prob-infected 1
          set color red
          set size infected-size
    ]
  ] ]
  set polarizedn count turtles with [color = red]
end

to reset-node
    set color white
    set size 2
    set polarized? false
    ;set prob-infected 0
    rt random-float 360
    fd max-pxcor
end

to build-network
  (ifelse
    network-sw = "Small World" [
      create-lattice
      rewire-network
    ]
    network-sw = "Scale-Free" [
      create-scalefree
    ]
    ; elsecommands
    [
      ask patches [ set pcolor gray ]
  ])
end

;; creates a new lattice
to create-lattice
  ;; iterate over the nodes
  let n 0
  while [n < count turtles]                           ;; iterate from 0 to n nodes
  [
    make-link-between turtle n                        ;; these links are undirected
              turtle ((n + 1) mod count turtles)      ;; make links with the next two neighbors
    make-link-between turtle n                        ;; mod count seems unnecessary?
              turtle ((n + 2) mod count turtles)      ;; lattice has average degree 4
    set n n + 1
  ]

   ; ask links [set color gray + 1.5]

layout
display

end

;; WARNING: the simplified rewiring algorithm does not certain checks (ie disconnected graph)
;; for large networksthis shouldn't be too much of an issue.
to rewire-network
  ask links
  [
    if (random-float 1) < rewiring-probability      ;; rewire with p < random-float
    [
      ask end1
      [
        create-link-with one-of other turtles with [not link-neighbor? myself ]
          [set color gray + 1.5]
      ]
      die                                           ;; and kill the old link
    ]
  ]
end

;; creates a new lattice
to create-scalefree
  ;; start from two nodes and an edge
  let friend nobody
  let first-node one-of turtles
  let second-node one-of turtles with [self != first-node]
  ;; add the first edge
  ask first-node [ create-link-with second-node [set color white]]
  ;; randomly select unattached node to add to network
  let new-node one-of turtles with [not any? link-neighbors]
  ;; connect it to a partner already in the network
  while [new-node != nobody][
    set friend find-friend
    ask new-node [create-link-with friend [set color white]]
    layout
    set new-node one-of turtles with [not any? link-neighbors]
  ]

  ;; layout
  ;; display
end

to layout
  (ifelse
    network-sw = "Small World" [
        ;; Layout turtles:
      layout-circle (sort turtles) max-pxcor - 20
      ;; space out turtles to see clustering
      ask turtles
      [
        facexy 0 0
        if who mod 2 = 0 [fd 7]                             ;; move every other turtle forward a bit
      ]
    ]
    network-sw = "Scale-Free" [
      layout-spring (turtles with [any? link-neighbors]) links 0.4 6 1
    ]
    ; elsecommands
    [
      ask patches [ set pcolor gray ]
  ])
end

;; Making the network
;; This code is borrowed from Lottery Example, from the Code Examples section of the Models Library.
;; The idea behind this procedure is as the following.
;; The sum of the sizes of the turtles is set as the number of "tickets" we have in our lottery.
;; Then we pick a random "ticket" (a random number), and we step through the
;; turtles to find which turtle holds that ticket.
to-report find-friend
  let pick random-float sum [count link-neighbors] of (turtles with [any? link-neighbors])
  let friend nobody
  ask turtles
  [ ;; if there's no winner yet
    if friend = nobody
    [ ifelse count link-neighbors > pick
      [ set friend self]
      [ set pick pick - (count link-neighbors)]
    ]
  ]
  report friend
end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to spread
  ;; or if every agent has already been infected
  if all? turtles [polarized?]
    [stop]
    if all? turtles [not polarized?]
    [stop]

  ask turtles [
    ifelse UseThresholds?
    [threshold-spread]
    [individual-spread]

    do-plotting
    set polarizedn count turtles with [polarized? = true]


  ]
  tick

end

to threshold-spread
  let polarization-one-sum count link-neighbors with [polarized?]
  (ifelse polarization-one-sum >= threshold and random-float 1 <= (1 - skepticism)
  [
    set polarized? true
    set color red
    set size 3

  ]
    polarization-one-sum >= 1 and (polarized?)            ;; if this is the threshold, you just get all white nodes. Sups boring.
  [
  set polarized? true
    set color red
    set size 3
  ]
  ; elsecommands
  ; allow reversion
  [ set polarized? false
    set color white
    set size 2
  ])

end

to individual-spread
  set polarized? [polarized?] of one-of link-neighbors
  ifelse (polarized?) and random-float 1 <= (1 - skepticism)
  [set color red
    set size 3]
  [set color white
    set size 2]
end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Reporting ;;;
;;;;;;;;;;;;;;;;;;;;;;;


to-report pct-infected
  report 100 * (polarizedn ) / (count turtles)                   ;; areport out percent polarized
end

to do-plotting
     ;; plot the number of infected individuals at each step
     set-current-plot "% infected"                              ;; plot title
     set-current-plot-pen "inf"                                 ;; name for the plot

     let percent-inf 100 * (polarizedn ) / (count turtles)       ;; estimate plot quantity
     plotxy ticks percent-inf                                   ;; plot plot quantity
end

;;layout all nodes and links
to do-layout
  repeat 5 [layout-spring turtles links 0.2 4 0.9]
  display
end

@#$#@#$#@
GRAPHICS-WINDOW
295
10
881
597
-1
-1
3.5901
1
10
1
1
1
0
0
0
1
-80
80
-80
80
1
1
1
ticks
30.0

SLIDER
8
164
188
197
num-nodes
num-nodes
10
500
100.0
10
1
NIL
HORIZONTAL

SLIDER
7
200
188
233
rewiring-probability
rewiring-probability
0
1
0.398
0.001
1
NIL
HORIZONTAL

PLOT
7
276
284
470
% infected
time
n
0.0
1.0
0.0
100.0
true
false
"" ""
PENS
"inf" 1.0 0 -2674135 true "" ""

SLIDER
7
235
188
268
skepticism
skepticism
0
1
0.4
0.01
1
NIL
HORIZONTAL

BUTTON
7
85
256
119
spread once
spread
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
135
47
256
81
spread
spread
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
193
215
286
260
Polarized
polarizedn
17
1
11

BUTTON
6
10
256
44
setup a new network
generate-topology
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
9
47
133
82
NIL
infect-two
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1017
60
1189
93
init
init
2
20
20.0
2
1
NIL
HORIZONTAL

SLIDER
891
123
1063
156
threshold
threshold
1
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
938
208
1110
241
echo
echo
0
1
0.1
0.1
1
NIL
HORIZONTAL

BUTTON
1000
324
1063
357
NIL
move
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
8
119
146
164
network-sw
network-sw
"Small World" "Scale-Free"
1

SWITCH
6
475
199
508
UseThresholds?
UseThresholds?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?


## HOW IT WORKS



## HOW TO USE IT



## THINGS TO TRY



## RELATED MODELS



## CREDITS AND REFERENCES
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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

outlined circle
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 false false -1 -1 301

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
NetLogo 6.1.0
@#$#@#$#@
setup
repeat 5 [rewire-one]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="vary-rewiring-probability" repetitions="5" runMetricsEveryStep="false">
    <go>generate-topology</go>
    <timeLimit steps="1"/>
    <exitCondition>rewiring-probability &gt; 1</exitCondition>
    <metric>average-path-length</metric>
    <metric>clustering-coefficient</metric>
    <steppedValueSet variable="rewiring-probability" first="0" step="0.01" last="1"/>
  </experiment>
  <experiment name="time-to-spread-simple" repetitions="30" runMetricsEveryStep="false">
    <setup>generate-topology
infect-two</setup>
    <go>spread</go>
    <timeLimit steps="999"/>
    <exitCondition>rewiring-probability &gt; 1</exitCondition>
    <metric>ticks</metric>
    <metric>pct-infected</metric>
    <steppedValueSet variable="rewiring-probability" first="0" step="0.01" last="1"/>
    <enumeratedValueSet variable="num-nodes">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-infection">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complex-contagion?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="time-to-spread-complex" repetitions="30" runMetricsEveryStep="false">
    <setup>generate-topology
infect-two</setup>
    <go>spread</go>
    <timeLimit steps="999"/>
    <exitCondition>rewiring-probability &gt; 1</exitCondition>
    <metric>ticks</metric>
    <metric>pct-infected</metric>
    <enumeratedValueSet variable="rewiring-probability">
      <value value="0.001"/>
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-infection">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-spread-one">
      <value value="0.001"/>
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complex-contagion?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="MidnightRuns" repetitions="20" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>generate-topology</setup>
    <go>spread</go>
    <timeLimit steps="40"/>
    <metric>count turtles</metric>
    <metric>polarizedn</metric>
    <enumeratedValueSet variable="UseThresholds?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-sw">
      <value value="&quot;Small World&quot;"/>
      <value value="&quot;Scale-Free&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewiring-probability">
      <value value="0"/>
      <value value="0.11"/>
      <value value="0.21"/>
      <value value="0.31"/>
      <value value="0.51"/>
      <value value="0.71"/>
      <value value="0.91"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skepticism">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="init">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
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
0
@#$#@#$#@
