extensions [gis table csv rnd]
turtles-own [PRO_COM]
breed [hospital hospitals]
breed [women womens]
breed [counselcenter counselcenters]
globals [tuscany distservices distservicesnorm]
counselcenter-own [ID capacity utility womencounsel]
hospital-own [ID hospitalizations utility capacity womenhospital mobilitiesemp ]
women-own [pregnant givenbirth selcounsel counselstay rankinglist selectedhospital selectedhospitalemp xval]



to setup
;  random-seed 10
  clear-all
  ask patches [set pcolor white]
  gis:load-coordinate-system "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/output/comuni_consultori_2019.prj"
  set tuscany gis:load-dataset "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/output/comuni_consultori_2019.shp"
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of tuscany))
  displaymap
  set distservices csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/matrice_distanze_consultori.csv"
  set distservicesnorm csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/normalized_distance.csv"
  create-counselcenters
  create-hospitals
  create-womens
  let sorted-hospitals sort-by [[a b] -> [hospitalizations] of a > [hospitalizations] of b] hospital

 output-print (word " Hospital choice  " )
  foreach sorted-hospitals [ h ->
  output-print (word [who] of h " = " [hospitalizations] of h)
]
  output-print (word "  " )
 foreach sorted-hospitals [ h ->
    output-print (word [who] of h " = " [id] of h " = " [hospitalizations] of h)
]


  ask women [options_hospital]
  plot-hospitals
  reset-timer
  reset-ticks
end

to displaymap
  clear-drawing
  gis:set-drawing-color black
  gis:draw tuscany 1
end




to create-counselcenters
let consul2019 csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/elenco_consultori_2019FILTERED_used.csv"
  foreach but-first consul2019 [ x ->
   create-counselcenter 1 [set shape "square"
      set id item 1 x
      set color cyan ;  item 0 x
      set pro_com item 0 x
      set capacity 20
    let loc gis:location-of gis:random-point-inside gis:find-one-feature tuscany "PRO_COM" item 0 x
    set xcor item 0 loc
    set ycor item 1 loc
]
  ]
end


to create-hospitals
let hospitals2023 csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/accessi_parto_ospedali_used.csv"
let listhospitals []
foreach but-first hospitals2023 [ row ->                           ; here to avoid duplicates in the hospital, since they appeared for each movement
  let key item 2 row                                               ; so I make first a list of the hospitals we have (24)
  if not member? key listhospitals [
    set listhospitals lput key listhospitals
  ]
]

  foreach listhospitals [x ->                                      ; for each hospital, one agent hospital is created
    create-hospital 1 [
      set id x
      set capacity 20
      set color green
    set shape "triangle"
      let list_effective filter [ [s] -> item 2 s = x ] but-first hospitals2023              ; it filters the movement rows in the dataset [here sublists] where it is mentioned
      set hospitalizations reduce + map [ [s] -> item 5 s ] list_effective                   ; the total hospitalizations per hospital across movements are computed
      set utility 0
      set pro_com  gis:property-value gis:find-one-feature tuscany "PRO_COM" item 4 item 0 list_effective "PRO_COM"     ; for relocation, the location with the first valid register of birth (to not repeat)
      let loc gis:location-of gis:random-point-inside gis:find-one-feature tuscany "PRO_COM" item 4 item 0 list_effective
      set xcor item 0 loc
      set ycor item 1 loc


    ]
  ]
end

to create-womens
let hosptlist csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/ricoveri_parti_2023.csv"

let my-table table:make

foreach but-first hosptlist [ x ->
  table:put my-table item 0 x  item 1 x
]
  foreach gis:feature-list-of tuscany [ this-municipality ->                                                                         ; each municipality, if included in the table [and it is only once],
    if member? gis:property-value this-municipality "PRO_COM" table:keys my-table [                                                  ; will produce as many women in their area as the number of hospitalizations
    gis:create-turtles-inside-polygon this-municipality women (table:get my-table gis:property-value this-municipality "PRO_COM") [  ; women derive their pro_com from the municipality
     set shape "circle"

 ifelse any? hospital with [dist self myself distservices <= 0] [set color red]
        [
ifelse any? hospital with [dist self myself distservices > 0 and dist self myself distservices <= 15] [set color yellow]
        [
ifelse any? hospital with [dist self myself distservices > 15 and dist self myself distservices <= 30] [set color orange]
          [
ifelse any? hospital with  [dist self myself distservices > 30 and dist self myself distservices <= 45] [set color brown]
              [
ifelse any? hospital with  [dist self myself distservices > 45 and dist self myself distservices <= 60] [set color violet]
                [set color blue]
              ]
            ]
          ]
          ]


     set size 0.2
     set pregnant false
     set selcounsel false
     set givenbirth false
     set counselstay 0
     set PRO_COM gis:property-value this-municipality "PRO_COM"
    ]
  ]
  ]

  let hospitals2023 csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/accessi_parto_ospedali_used.csv"


 foreach but-first hospitals2023[ i ->
 ask n-of item 5 i women with [pro_com = item 0 i and selectedhospitalemp = 0][
 set selectedhospitalemp [who] of one-of hospital with [id = item 2 i ]
    ]
 ]

; resize the population
foreach gis:feature-list-of tuscany [ this-municipality ->
ask n-of round(count women with [pro_com = gis:property-value this-municipality "PRO_COM"] * (1 - size_population)) women with [pro_com = gis:property-value this-municipality "PRO_COM"] [die]
]

end

to options_hospital

set rankinglist table:make
foreach sort hospital [ x ->
table:put rankinglist [who] of x 0
]


end

to go
if not any? women with [givenbirth = false] [stop]


  ask one-of women with [pregnant = false and givenbirth = false] [
   set pregnant true
   if selectedhospital = 0 [select_hospital]
      ]


  plot-hospitals

  tick
end


to select_hospital

let friends  rnd:weighted-n-of n_network other women [exp(distweight * (dist myself self distservices ))]

  ask hospital [
    ; ranking of the alter friends for each hospital (min = 0, max = 1)
    let ranking_othweight []
    foreach sort friends [ z ->
    set ranking_othweight lput (table:get [rankinglist] of z [who] of self) ranking_othweight

   ]

    set utility ( (weight_distance_hospital * dist myself self distservices ) + (social_multiplier * (reduce +   ranking_othweight / count friends )))

  ]

  set selectedhospital [who] of rnd:weighted-one-of hospital [exp(utility - max [utility] of hospital)]
  ; the "ranking experience" is 1 by default
  table:put rankinglist selectedhospital 1

 if show_networks [
  create-link-with one-of hospital with [who = [selectedhospital] of myself]
  ask my-out-links [set color [color] of myself]
  ]

 set givenbirth true
 set pregnant false

end

to plot-hospitals
;    set-current-plot "Hospital choice"
;    clear-plot

; if plot_show = "hospitalizations" [
  ; Sort hospitals by real hospitalizations
;   let sorted-hospitals sort-by [[a b] -> [hospitalizations] of a < [hospitalizations] of b] hospital

  ; First plot: real hospitalizations
  ; set-current-plot-pen "actual"
  ; let index 0
  ; foreach sorted-hospitals [
   ; t ->
    ;  let yval [hospitalizations] of t
     ; plotxy index 0
      ; plotxy index yval
      ; set index index + 1
  ; ]

  ; Now compute simulated hospital choices per hospital
;   ask hospital [
;     set womenhospital count women with [selectedhospital = [who] of myself]
;   ]

  ; Sort hospitals again in the same order to match indexing
;   let sorted-womenhospital sort-by [[a b] -> [womenhospital] of a < [womenhospital] of b] hospital

  ; Second plot: simulated choices (overlay on same x)
;   set-current-plot-pen "simulated"
;   let indexsim 0
;   foreach sorted-womenhospital [
;     t ->
;       let yval [womenhospital] of t
;       plotxy indexsim 0
;       plotxy indexsim yval
;       set indexsim indexsim + 1
;   ]
;   ]

;    if plot_show = "mobilities" [
  ; Sort hospitals by real hospitalizations
;      ask hospital [
;        set mobilitiesemp count women with [selectedhospitalemp = [who] of myself and pro_com != [pro_com] of myself]]
;    let sorted-hospitals sort-by [[a b] -> [mobilitiesemp] of a < [mobilitiesemp] of b] hospital

  ; First plot: real hospitalizations
;    set-current-plot-pen "actual"
;    let index 0
;    foreach sorted-hospitals [
;      t ->
 ;        let yval [mobilitiesemp] of t
 ;      plotxy index 0
  ;      plotxy index yval
 ;      set index index + 1
;   ]

  ; Now compute simulated hospital choices per hospital
;   ask hospital [
;       set womenhospital count women with [selectedhospital = [who] of myself and pro_com != [pro_com] of myself]
;   ]

  ; Sort hospitals again in the same order to match indexing
;   let sorted-womenhospital sort-by [[a b] -> [womenhospital] of a < [womenhospital] of b] hospital

  ; Second plot: simulated choices (overlay on same x)
;   set-current-plot-pen "simulated"
;   let indexsim 0
;   foreach sorted-womenhospital [
;     t ->
 ;      let yval [womenhospital] of t
;        plotxy indexsim 0
;       plotxy indexsim yval
;       set indexsim indexsim + 1
;   ]
;    ]

 set-current-plot "Selection hospital"
clear-plot
set-current-plot-pen "actual"

let womenselecthosp women with [selectedhospitalemp = [who] of hospitals hospital_id]
let xs [ dist self hospitals hospital_id distservices ] of womenselecthosp
set-plot-x-range 0 200

histogram xs


set-current-plot-pen "simulated"

let womenselecthospsim women with [selectedhospital = [who] of hospitals hospital_id]
let xsim [ dist self hospitals hospital_id distservices] of womenselecthospsim
set-plot-x-range 0 200

histogram xsim


end

to-report dist [origin destination matrix]
let destinationpos position [pro_com] of destination item 0 matrix
report item destinationpos item 0 filter [x -> first x = [pro_com] of origin] matrix
end

to-report normal [means std-devs maxlim minlim]
  let value random-normal means std-devs
  ;; Clamp to -1 to 1
  if value > maxlim [ set value maxlim ]
  if value < minlim [ set value minlim]
  report value
end

to-report distchoicezero [idd]
  report count women with [selectedhospital = [who] of idd and dist self idd distservices <= 0]
end

to-report distchoice [idd distmin distmax]
  report count women with [selectedhospital = [who] of idd and dist self idd distservices > distmin and dist self idd distservices <= distmax]
end

to-report distchoicemax [idd distmax]
  report count women with [selectedhospital = [who] of idd and dist self idd distservices > distmax]
end

to-report womenwhoselected [idd]
  report count women with [selectedhospital = [who] of idd ]
end
@#$#@#$#@
GRAPHICS-WINDOW
220
10
723
514
-1
-1
15.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
73
21
136
54
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
1

BUTTON
1200
400
1294
433
hide women
ask women [hide-turtle]
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
1089
401
1195
434
hide counselcenter
ask counselcenter [ hide-turtle]
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
1089
438
1196
471
show counselcenter
ask counselcenter [set color cyan show-turtle]
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
1201
437
1296
470
show women
ask women [show-turtle]
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
1300
399
1378
432
hide hospitals
ask hospital [hide-turtle]
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
1299
437
1380
470
show hospital
ask hospital [set color green show-turtle]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1046
418
1086
459
three actors
10
0.0
1

OUTPUT
1047
18
1498
387
10

BUTTON
937
521
1009
554
testdistances
print dist turtle origin_from turtle destination_to distservices
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
765
524
841
584
origin_from
48.0
1
0
Number

INPUTBOX
843
524
928
584
destination_to
1797.0
1
0
Number

BUTTON
71
428
136
461
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
1

MONITOR
252
518
319
563
given birth
count women with [givenbirth = true]
17
1
11

SLIDER
28
220
180
253
social_multiplier
social_multiplier
-10
10
0.0
1
1
max
HORIZONTAL

SLIDER
30
182
183
215
weight_distance_hospital
weight_distance_hospital
-10
0
-5.0
1
1
NIL
HORIZONTAL

TEXTBOX
69
159
155
177
selection hospital
10
0.0
1

TEXTBOX
1150
479
1328
570
women color - min distance hospital\n0 = red: 8512, 42%\n1 - 15 = yellow: 6343, 31%\n16 - 30 = orange: 3162, 15%\n31 - 45 = brown: 1754, 8%\n46 - 60 = violet: 326, 1%\n+ 61 = blue: 80, 0.4%
10
0.0
1

BUTTON
938
556
1008
589
hide links
ask links [die]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1332
479
1481
583
women, distance counselcenter\n[ not visualize]\n(<= 0) 10088, 49.99%\n(0-15) 7489, 37.11%\n(15-30) 2379, 11.7%\n(30-45) 213, 1.05%\n(45-60) 7, 0.03%\n(+ 60) 1, 0.004%
10
0.0
1

SLIDER
8
99
100
132
distweight
distweight
-1
1
0.6
0.1
1
NIL
HORIZONTAL

BUTTON
42
385
165
418
vis_pop_concentration
ask women [hide-turtle]\nask counselcenter [hide-turtle]\nforeach gis:feature-list-of tuscany [ this-municipality ->  \nlet n-women   count women with [ pro_com = gis:property-value this-municipality \"PRO_COM\" ]\nlet tot       count women\nlet p (n-women / tot)\nlet col scale-color red p 1 0\ngis:set-drawing-color col\ngis:fill this-municipality col\nprint(word gis:property-value this-municipality \"PRO_COM\" \" : \" \ncount women with [pro_com = gis:property-value this-municipality \"PRO_COM\"])\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
43
351
165
384
show_networks
show_networks
1
1
-1000

PLOT
727
367
1036
517
Mobility hospital origin (proportion)
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"0" 1.0 0 -2674135 true "" "if womenwhoselected hospitals hospital_id > 0 [ plot (distchoicezero hospitals hospital_id / womenwhoselected hospitals hospital_id)]\n"
"1-15" 1.0 0 -1184463 true "" "if womenwhoselected hospitals hospital_id > 0 [ plot (distchoice hospitals hospital_id 0 15 / womenwhoselected hospitals hospital_id)]\n"
"16-30" 1.0 0 -955883 true "" "if womenwhoselected hospitals hospital_id > 0 [ plot (distchoice hospitals hospital_id 15 30 / womenwhoselected hospitals hospital_id)]\n"
"31-45" 1.0 0 -6459832 true "" "if womenwhoselected hospitals hospital_id > 0 [ plot (distchoice hospitals hospital_id 30 45 / womenwhoselected hospitals hospital_id)]\n"
"46-60" 1.0 0 -8630108 true "" "if womenwhoselected hospitals hospital_id > 0 [ plot (distchoice hospitals hospital_id 45 60 / womenwhoselected hospitals hospital_id)]\n"
"61+" 1.0 0 -13345367 true "" "if womenwhoselected hospitals hospital_id > 0 [ plot (distchoicemax hospitals hospital_id 60 / womenwhoselected hospitals hospital_id)]\n"

CHOOSER
740
10
832
55
hospital_id
hospital_id
50 61 58 60 48 63 53 64 69 56 66 51 59 65 57 62 55 49 52 54 71 68 67 70
6

BUTTON
570
524
665
557
highlight hospital
ask hospitals hospital_id [set color blue]\nplot-hospitals
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
729
213
1037
363
Mobility hospital origin (raw numbers)
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"0" 1.0 0 -2674135 true "" "plot (distchoicezero hospitals hospital_id)"
"1-15" 1.0 0 -1184463 true "" "plot (distchoice hospitals hospital_id 0 15)"
"16-30" 1.0 0 -955883 true "" "plot (distchoice hospitals hospital_id 15 30 )"
"31-45" 1.0 0 -6459832 true "" "plot (distchoice hospitals hospital_id 30 45)"
"46-60" 1.0 0 -8630108 true "" "plot (distchoice hospitals hospital_id 45 60)"
"61+" 1.0 0 -13345367 true "" "plot (distchoicemax hospitals hospital_id 60)"

TEXTBOX
54
73
140
91
network formation
10
0.0
1

PLOT
730
60
1038
210
Selection hospital
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"actual" 1.0 1 -2674135 true "" ""
"simulated" 1.0 1 -13345367 true "" ""

TEXTBOX
1046
483
1142
527
women: 20177\nhospitals: 24\ncounselcenters: 48
10
0.0
1

MONITOR
833
10
921
55
actual affluence
count women with [selectedhospitalemp = [who] of hospitals hospital_id]
2
1
11

MONITOR
923
10
1028
55
simulated affluence
count women with [selectedhospital = [who] of hospitals hospital_id]
2
1
11

MONITOR
324
518
407
563
NIL
count women
2
1
11

SLIDER
108
99
200
132
n_network
n_network
0
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
411
523
470
556
networks
ask links [die]\nask women [hide-turtle]\nask counselcenter [hide-turtle]\nifelse emp_net \n[ask women [create-link-with one-of hospital with [who = [selectedhospitalemp] of myself]]]\n[ask women [create-link-with one-of hospital with [who = [selectedhospital] of myself]]]\nask women [ask my-out-links [set color [color] of myself]]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
474
523
564
556
emp_net
emp_net
1
1
-1000

SLIDER
19
280
191
313
size_population
size_population
0
1
0.25
0.05
1
NIL
HORIZONTAL

TEXTBOX
140
315
219
340
1 = full original dataset
10
0.0
1

@#$#@#$#@
## WHAT IS IT?

Hospital choice based on social multiplier of formed networks. Actors of the simulation are women, counselcenters and hospitals. Random utility models applied for the selection hospitals.

## NOTES ON HOSPITALS

* San Rossore: private
* Serristore Figlini: not a maternity department

## HOW IT WORKS

In this version, in each cycle one woman is set to be pregnant and search for an hospital. The woman selects n_network other agents based on the distance in space modeled with discrete choice probability. At time 0, each agent holds 0 as ranking for each hospital. When the agent selects an hospital, the assessment is based on the distance (closer has higher probability) and ranking of the hospital from the agent in their network. By default, the ranking of the hospital where an agent has given birth is 1. The social multiplier includes the average of agents in the network that have experience of the hospital, weighted by a parameter modeling the effect of social influence. When an agent has selected the hospital, givenbirth is set to true. The simulation ends when no women with givenbirth false are available.

The utility is computed as ((-weightdistance * distance) + (weightsocialinfluence * (rankingalter/sumalter))
sumalter refers to the number of other people in the network of the caller agent.

This strategy is aimed at explaining mechanisms and inequalities in hospital selection through the interaction of distance and social influence, leveraging the modeling of cascade effects and relative weights between distance and social influence in the decisional process.

Initialized with data from Tuscany, results are bounded to spatial inequalities in the distribution of services and proximity of services.  


## HOW TO USE IT

SETUP
Color of women show the minimum distance to reach one hospital

* show_networks: to show mobilities through networks during the simulation
* distweight: weight of distance for network selection in the word of mouth
(-1 preference for closer people; 0 random; 1 preference for further people)
* n_network: number of people in the network
The network is an agentset from which the average rating is computed
* weight_distance_hospital: the weight of distance to hospital selection (negative value since the less distance is better)
* social_multiplier: weight of social influence in the hospital selection
* resizepop: to scale down to *resizescale* input value (in decimal).
* popconcentration: to show the concentration of women in that municipality compared to the whole region


## THINGS TO NOTICE

The three plots show results for the individual hospital to select (hospital_id)
* Selection hospital: the number of women who selected the hospital distributed by distance on x-axis. Red line the actual data, blue line the simulation results
* Mobility hospital origin (raw numbers): the number of women in the simulation that select hospital id, signaling the distance from the hospital
* Mobility hospital origin (proportion): the proportion of women that selected the hospital in the simulation by distance

* networks button: to show all networks mobolities from empirical data (emp_net set to on) or from the simulation

# NOTE 

Effect of concentration of the population and distribution of services reflecting the concentration. In fact, slow mobility from further zones (Val di Chiana to Grosset).

## CREDITS AND REFERENCES

Rocco Paolillo
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

women
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Polygon -7500403 true true 135 180 180 195 225 255 60 255
Polygon -7500403 true true 120 15 90 75 210 75 180 15 180 45

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>distchoicezero hospitals 50</metric>
    <metric>distchoicezero hospitals 61</metric>
    <metric>distchoicezero hospitals 58</metric>
    <metric>distchoicezero hospitals 60</metric>
    <metric>distchoicezero hospitals 48</metric>
    <metric>distchoicezero hospitals 63</metric>
    <metric>distchoicezero hospitals 53</metric>
    <metric>distchoicezero hospitals 64</metric>
    <metric>distchoicezero hospitals 69</metric>
    <metric>distchoicezero hospitals 56</metric>
    <metric>distchoicezero hospitals 66</metric>
    <metric>distchoicezero hospitals 51</metric>
    <metric>distchoicezero hospitals 59</metric>
    <metric>distchoicezero hospitals 65</metric>
    <metric>distchoicezero hospitals 57</metric>
    <metric>distchoicezero hospitals 62</metric>
    <metric>distchoicezero hospitals 55</metric>
    <metric>distchoicezero hospitals 49</metric>
    <metric>distchoicezero hospitals 52</metric>
    <metric>distchoicezero hospitals 54</metric>
    <metric>distchoicezero hospitals 71</metric>
    <metric>distchoicezero hospitals 68</metric>
    <metric>distchoicezero hospitals 67</metric>
    <metric>distchoicezero hospitals 70</metric>
    <metric>distchoice hospitals 50 0 15</metric>
    <metric>distchoice hospitals 61 0 15</metric>
    <metric>distchoice hospitals 58 0 15</metric>
    <metric>distchoice hospitals 60 0 15</metric>
    <metric>distchoice hospitals 48 0 15</metric>
    <metric>distchoice hospitals 63 0 15</metric>
    <metric>distchoice hospitals 53 0 15</metric>
    <metric>distchoice hospitals 64 0 15</metric>
    <metric>distchoice hospitals 69 0 15</metric>
    <metric>distchoice hospitals 56 0 15</metric>
    <metric>distchoice hospitals 66 0 15</metric>
    <metric>distchoice hospitals 51 0 15</metric>
    <metric>distchoice hospitals 59 0 15</metric>
    <metric>distchoice hospitals 65 0 15</metric>
    <metric>distchoice hospitals 57 0 15</metric>
    <metric>distchoice hospitals 62 0 15</metric>
    <metric>distchoice hospitals 55 0 15</metric>
    <metric>distchoice hospitals 49 0 15</metric>
    <metric>distchoice hospitals 52 0 15</metric>
    <metric>distchoice hospitals 54 0 15</metric>
    <metric>distchoice hospitals 71 0 15</metric>
    <metric>distchoice hospitals 68 0 15</metric>
    <metric>distchoice hospitals 67 0 15</metric>
    <metric>distchoice hospitals 70 0 15</metric>
    <metric>distchoice hospitals 50 15 30</metric>
    <metric>distchoice hospitals 61 15 30</metric>
    <metric>distchoice hospitals 58 15 30</metric>
    <metric>distchoice hospitals 60 15 30</metric>
    <metric>distchoice hospitals 48 15 30</metric>
    <metric>distchoice hospitals 63 15 30</metric>
    <metric>distchoice hospitals 53 15 30</metric>
    <metric>distchoice hospitals 64 15 30</metric>
    <metric>distchoice hospitals 69 15 30</metric>
    <metric>distchoice hospitals 56 15 30</metric>
    <metric>distchoice hospitals 66 15 30</metric>
    <metric>distchoice hospitals 51 15 30</metric>
    <metric>distchoice hospitals 59 15 30</metric>
    <metric>distchoice hospitals 65 15 30</metric>
    <metric>distchoice hospitals 57 15 30</metric>
    <metric>distchoice hospitals 62 15 30</metric>
    <metric>distchoice hospitals 55 15 30</metric>
    <metric>distchoice hospitals 49 15 30</metric>
    <metric>distchoice hospitals 52 15 30</metric>
    <metric>distchoice hospitals 54 15 30</metric>
    <metric>distchoice hospitals 71 15 30</metric>
    <metric>distchoice hospitals 68 15 30</metric>
    <metric>distchoice hospitals 67 15 30</metric>
    <metric>distchoice hospitals 70 15 30</metric>
    <metric>distchoice hospitals 50 30 45</metric>
    <metric>distchoice hospitals 61 30 45</metric>
    <metric>distchoice hospitals 58 30 45</metric>
    <metric>distchoice hospitals 60 30 45</metric>
    <metric>distchoice hospitals 48 30 45</metric>
    <metric>distchoice hospitals 63 30 45</metric>
    <metric>distchoice hospitals 53 30 45</metric>
    <metric>distchoice hospitals 64 30 45</metric>
    <metric>distchoice hospitals 69 30 45</metric>
    <metric>distchoice hospitals 56 30 45</metric>
    <metric>distchoice hospitals 66 30 45</metric>
    <metric>distchoice hospitals 51 30 45</metric>
    <metric>distchoice hospitals 59 30 45</metric>
    <metric>distchoice hospitals 65 30 45</metric>
    <metric>distchoice hospitals 57 30 45</metric>
    <metric>distchoice hospitals 62 30 45</metric>
    <metric>distchoice hospitals 55 30 45</metric>
    <metric>distchoice hospitals 49 30 45</metric>
    <metric>distchoice hospitals 52 30 45</metric>
    <metric>distchoice hospitals 54 30 45</metric>
    <metric>distchoice hospitals 71 30 45</metric>
    <metric>distchoice hospitals 68 30 45</metric>
    <metric>distchoice hospitals 67 30 45</metric>
    <metric>distchoice hospitals 70 30 45</metric>
    <metric>distchoice hospitals 50 45 60</metric>
    <metric>distchoice hospitals 61 45 60</metric>
    <metric>distchoice hospitals 58 45 60</metric>
    <metric>distchoice hospitals 60 45 60</metric>
    <metric>distchoice hospitals 48 45 60</metric>
    <metric>distchoice hospitals 63 45 60</metric>
    <metric>distchoice hospitals 53 45 60</metric>
    <metric>distchoice hospitals 64 45 60</metric>
    <metric>distchoice hospitals 69 45 60</metric>
    <metric>distchoice hospitals 56 45 60</metric>
    <metric>distchoice hospitals 66 45 60</metric>
    <metric>distchoice hospitals 51 45 60</metric>
    <metric>distchoice hospitals 59 45 60</metric>
    <metric>distchoice hospitals 65 45 60</metric>
    <metric>distchoice hospitals 57 45 60</metric>
    <metric>distchoice hospitals 62 45 60</metric>
    <metric>distchoice hospitals 55 45 60</metric>
    <metric>distchoice hospitals 49 45 60</metric>
    <metric>distchoice hospitals 52 45 60</metric>
    <metric>distchoice hospitals 54 45 60</metric>
    <metric>distchoice hospitals 71 45 60</metric>
    <metric>distchoice hospitals 68 45 60</metric>
    <metric>distchoice hospitals 67 45 60</metric>
    <metric>distchoice hospitals 70 45 60</metric>
    <metric>distchoicemax hospitals 50 60</metric>
    <metric>distchoicemax hospitals 61 60</metric>
    <metric>distchoicemax hospitals 58 60</metric>
    <metric>distchoicemax hospitals 60 60</metric>
    <metric>distchoicemax hospitals 48 60</metric>
    <metric>distchoicemax hospitals 63 60</metric>
    <metric>distchoicemax hospitals 53 60</metric>
    <metric>distchoicemax hospitals 64 60</metric>
    <metric>distchoicemax hospitals 69 60</metric>
    <metric>distchoicemax hospitals 56 60</metric>
    <metric>distchoicemax hospitals 66 60</metric>
    <metric>distchoicemax hospitals 51 60</metric>
    <metric>distchoicemax hospitals 59 60</metric>
    <metric>distchoicemax hospitals 65 60</metric>
    <metric>distchoicemax hospitals 57 60</metric>
    <metric>distchoicemax hospitals 62 60</metric>
    <metric>distchoicemax hospitals 55 60</metric>
    <metric>distchoicemax hospitals 49 60</metric>
    <metric>distchoicemax hospitals 52 60</metric>
    <metric>distchoicemax hospitals 54 60</metric>
    <metric>distchoicemax hospitals 71 60</metric>
    <metric>distchoicemax hospitals 68 60</metric>
    <metric>distchoicemax hospitals 67 60</metric>
    <metric>distchoicemax hospitals 70 60</metric>
    <metric>womenwhoselected hospitals 50</metric>
    <metric>womenwhoselected hospitals 61</metric>
    <metric>womenwhoselected hospitals 58</metric>
    <metric>womenwhoselected hospitals 60</metric>
    <metric>womenwhoselected hospitals 48</metric>
    <metric>womenwhoselected hospitals 63</metric>
    <metric>womenwhoselected hospitals 53</metric>
    <metric>womenwhoselected hospitals 64</metric>
    <metric>womenwhoselected hospitals 69</metric>
    <metric>womenwhoselected hospitals 56</metric>
    <metric>womenwhoselected hospitals 66</metric>
    <metric>womenwhoselected hospitals 51</metric>
    <metric>womenwhoselected hospitals 59</metric>
    <metric>womenwhoselected hospitals 65</metric>
    <metric>womenwhoselected hospitals 57</metric>
    <metric>womenwhoselected hospitals 62</metric>
    <metric>womenwhoselected hospitals 55</metric>
    <metric>womenwhoselected hospitals 49</metric>
    <metric>womenwhoselected hospitals 52</metric>
    <metric>womenwhoselected hospitals 54</metric>
    <metric>womenwhoselected hospitals 71</metric>
    <metric>womenwhoselected hospitals 68</metric>
    <metric>womenwhoselected hospitals 67</metric>
    <metric>womenwhoselected hospitals 70</metric>
    <metric>[id] of hospitals 50</metric>
    <metric>[id] of hospitals 61</metric>
    <metric>[id] of hospitals 58</metric>
    <metric>[id] of hospitals 60</metric>
    <metric>[id] of hospitals 48</metric>
    <metric>[id] of hospitals 63</metric>
    <metric>[id] of hospitals 53</metric>
    <metric>[id] of hospitals 64</metric>
    <metric>[id] of hospitals 69</metric>
    <metric>[id] of hospitals 56</metric>
    <metric>[id] of hospitals 66</metric>
    <metric>[id] of hospitals 51</metric>
    <metric>[id] of hospitals 59</metric>
    <metric>[id] of hospitals 65</metric>
    <metric>[id] of hospitals 57</metric>
    <metric>[id] of hospitals 62</metric>
    <metric>[id] of hospitals 55</metric>
    <metric>[id] of hospitals 49</metric>
    <metric>[id] of hospitals 52</metric>
    <metric>[id] of hospitals 54</metric>
    <metric>[id] of hospitals 71</metric>
    <metric>[id] of hospitals 68</metric>
    <metric>[id] of hospitals 67</metric>
    <metric>[id] of hospitals 70</metric>
    <steppedValueSet variable="social_multiplier" first="0" step="1" last="10"/>
    <steppedValueSet variable="weight_distance_hospital" first="-10" step="1" last="0"/>
    <enumeratedValueSet variable="distfriend">
      <value value="-1"/>
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd_ranking">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plot_show">
      <value value="&quot;hospitalizations&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="area_municipality">
      <value value="48017"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean_ranking">
      <value value="-9.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emp_tgt">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="destination_to">
      <value value="1797"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inspectcounselcenter">
      <value value="20345"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="weight_distance_counsel">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="origin_from">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="weight_socialinfluence">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hospital_id">
      <value value="61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MUNICIPALITY_name">
      <value value="&quot;Firenze&quot;"/>
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
