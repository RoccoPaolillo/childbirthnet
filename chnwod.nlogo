extensions [gis table csv rnd]
turtles-own [PRO_COM]
breed [hospital hospitals]
breed [women womens]
breed [counselcenter counselcenters]
globals [tuscany distservices]
counselcenter-own [ID capacity utility]
hospital-own [ID hospitalizations utility capacity]
women-own [pregnant givenbirth selcounsel counselstay rankinglist selectedhospital]



to setup
  random-seed 10
  clear-all
  ask patches [set pcolor white]
  gis:load-coordinate-system "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/output/comuni_consultori_2019.prj"
  set tuscany gis:load-dataset "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/output/comuni_consultori_2019.shp"
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of tuscany))
  displaymap
  create-womens
  create-counselcenters
  create-hospitals
  output-print (word "women: " count women "; counselcenters: " count counselcenter "; hospitals: " count hospital)
  output-print (word "  " )
  output-print (word "hospitalizations per hospital ")
  output-print (word "  " )
  ask hospital [output-print (word id " = " hospitalizations)]
  set distservices csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/matrice_distanze_consultori.csv"
  reset-timer
  reset-ticks
end

to displaymap
  clear-drawing
  gis:set-drawing-color black
  gis:draw tuscany 1
end


to create-womens
let hosptlist csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/ricoveri_parti_2023.csv"
let my-table table:make

foreach but-first hosptlist [ x ->
  table:put my-table item 0 x  item 1 x
]
  foreach gis:feature-list-of tuscany [ this-municipality ->                                                                        ; each municipality, if included in the table [and it is only once],
    if member? gis:property-value this-municipality "PRO_COM" table:keys my-table [                                                 ; will produce as many women in their area as the number of hospitalizations
    gis:create-turtles-inside-polygon this-municipality women  table:get my-table gis:property-value this-municipality "PRO_COM" [  ; women derive their pro_com from the municipality
     set shape "circle"
     set color gis:property-value this-municipality "PRO_COM"
     set size 0.2
     set pregnant false
     set selcounsel false
     set counselstay 0
     set PRO_COM gis:property-value this-municipality "PRO_COM"
    ]
  ]
  ]
end

to create-counselcenters                                                                                   ; here better was to extract from the csv, not table nor gis,
let consul2019 csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/elenco_consultori_2019FILTERED_used.csv"                                        ; since the same municipality can have different counselcenters,
  foreach but-first consul2019 [ x ->                                                                       ; each with separate id [see GitHub issue for question]
   create-counselcenter 1 [set shape "square"                                                               ; then the agent counsel center gets the cooordinates from the municipality it is associated with
      set id item 1 x
      set color gray ;  item 0 x
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
      set color gray
    set shape "triangle"
      let list_effective filter [ [s] -> item 2 s = x ] but-first hospitals2023              ; it filters the movement rows in the dataset [here sublists] where it is mentioned
      set hospitalizations reduce + map [ [s] -> item 5 s ] list_effective                             ; the total hospitalizations per hospital across movements are computed
      set utility 0
;      set color gis:property-value gis:find-one-feature tuscany "PRO_COM" item 4 item 0 list_effective "PRO_COM"        ; the color and relocation are computed
      set pro_com  gis:property-value gis:find-one-feature tuscany "PRO_COM" item 4 item 0 list_effective "PRO_COM"     ; for relocation, the location with the first valid register of birth (to not repeat)
      let loc gis:location-of gis:random-point-inside gis:find-one-feature tuscany "PRO_COM" item 4 item 0 list_effective
      set xcor item 0 loc
      set ycor item 1 loc

    ]
  ]
end

to go
 ; every wave_pregnant [   ; alternative to ticks
    if ticks > 0 and ticks mod wave_pregnant = 0  [
    ask n-of count_pregnant women [set pregnant true]
  ]
  ask women [if pregnant = true [
    ifelse selcounsel = false [choice][set counselstay counselstay + 1]
    ]
  ]
  if ticks = stop_if [stop]
  tick
end

to choice

print (word "woman: " who " pro_com: " pro_com)
let radius 0.5

let counselsoptions no-turtles

while [count counselsoptions < 5] [
set counselsoptions other  counselcenter in-radius radius with [capacity > 0 ]
set radius radius + 1
]

ask  counselsoptions [
set color [color] of myself
set utility (weight_distance * dist myself self)

print (word "counselcenter: "  who " capacity: " capacity " utility: "  utility " distance: " dist myself self " pro_com: " pro_com)
  ]

set selcounsel [who] of rnd:weighted-one-of counselsoptions [exp( utility)]
ask counselcenter with [who = [selcounsel] of myself][set capacity capacity - 1 ]

print (word "woman: " who " pro_com: " pro_com " selcounsel: " selcounsel)
ask  counselsoptions [
print (word "counselcenter: "  who " capacity: " capacity " utility: "  utility " distance: " dist myself self " pro_com: " pro_com)
  ]

end


to choice_hospital
options_hospital
discuss_hospital
; select_hospital
end

to options_hospital

ask women with [selcounsel != false] [

let radius 1.5

let hospitalsoptions no-turtles

; to make up an own list of hospitals to select from based on proximity
while [count hospitalsoptions < 3] [
set hospitalsoptions other  hospital in-radius radius with [capacity > 0 ]
set radius radius + 1
]

; placeholder (irrelevant)
 ask  hospitalsoptions [
 set color [color] of myself
 print (word "hospital: "  who " woman: " [who] of myself " capacity: " capacity " distance: " dist myself self " pro_com: " pro_com)
   ]

; to make up for ranking given to each hospital in the list key: ID hospital, value: [0,1] with beta distribution
set rankinglist table:make
foreach sort hospitalsoptions [ x ->
   table:put rankinglist [who] of x beta-random 0.5 0.2
]

]
end

to discuss_hospital

ask women with [selcounsel != false] [

let hospa []
foreach sort women with [selcounsel = [selcounsel] of myself][ z ->
let dictall table:keys [rankinglist] of z
foreach dictall [x ->
 if not member? x hospa [
 set hospa lput x hospa ]
      ]
    ]

; print (word who " " selcounsel " rankinglist without missing: " rankinglist  " allist: " hospa )

 foreach hospa [y ->
 if not member? y table:keys rankinglist [
 table:put rankinglist y 0
 ]
 ]

 print (word who " " selcounsel " allist: " hospa " rankinglist updated: " rankinglist  )
 ]

end

;to select_hospital
;  ask women with [selcounsel != false][
;  let options hospital with [member? who  table:keys [rankinglist] of myself]
;    ask options [set utility table:get rankinglist [who] of self ]
;  ]
; end





to-report dist [origin destination]
let destinationpos position [pro_com] of destination item 0 distservices
report item destinationpos item 0 filter [x -> first x = [pro_com] of origin] distservices
end

to-report beta-random [means std-dev]
  let variances std-dev * std-dev
  let alpha means * ((means * (1 - means)) / variances - 1)
  let beta (1 - means) * ((means * (1 - means)) / variances - 1)

  if alpha <= 0 or beta <= 0 [
    user-message (word "Invalid alpha/beta parameters: mean=" means ", std-dev=" std-dev)
    report means ; fallback to mean
  ]

  let x random-gamma alpha 1
  let y random-gamma beta 1

  report x / (x + y)
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
1
1
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
24
12
87
45
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
1262
14
1490
47
show VectorDataset
show gis:feature-list-of tuscany
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
1301
485
1435
518
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
1161
485
1294
518
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
1384
122
1490
155
color_municipality
gis:set-drawing-color red gis:fill gis:find-one-feature tuscany \"PRO_COM\" area_municipality 5
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
1261
120
1375
190
area_municipality
45002.0
1
0
Number

INPUTBOX
1262
53
1377
113
MUNICIPALITY_name
Firenze
1
0
String (reporter)

BUTTON
1384
70
1489
103
codCOMUNE
print gis:property-value gis:find-one-feature tuscany \"COMUNE\" MUNICIPALITY_name \"PRO_COM\" 
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
1162
522
1295
555
show counselcenter
ask counselcenter [ show-turtle]
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
1302
522
1435
555
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
1385
157
1490
190
show VectorFeature
print gis:find-one-feature tuscany \"PRO_COM\" area_municipality
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
1442
485
1557
518
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
1441
523
1558
556
show hospital
ask hospital [show-turtle]
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
1318
464
1399
482
the three actors
10
0.0
1

OUTPUT
727
13
1142
417
10

BUTTON
1416
561
1488
594
testdistances
ask womens womens_who [\n\nlet counselspos position [pro_com] of counselcenters counsels_who item 0 distservices\nprint item counselspos item 0 filter [x -> first x = [pro_com] of self] distservices\n\n ]\n
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
1161
562
1295
622
womens_who
12886.0
1
0
Number

INPUTBOX
1297
562
1412
622
counsels_who
20186.0
1
0
Number

BUTTON
108
136
173
169
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

SLIDER
30
235
158
268
weight_distance
weight_distance
-100
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
25
285
173
330
capacity counselcenters
mean [capacity] of counselcenter
2
1
11

MONITOR
25
339
172
384
pregnant women
count women with [pregnant = true]
17
1
11

BUTTON
1494
560
1607
593
check ticks advance
if ticks mod 2 = 0 [\n  show (word \"Tick \" ticks \": This runs on even ticks\")\n]\ntick
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
13
122
76
182
stop_if
50.0
1
0
Number

INPUTBOX
12
57
96
117
count_pregnant
10.0
1
0
Number

INPUTBOX
102
56
201
116
wave_pregnant
4.0
1
0
Number

BUTTON
1290
290
1416
323
counsel_networks
ask counselcenter [if count women with [selcounsel = [who] of myself] > 1 [\nprint (word \" counselcenter: \" who \" women: \" [who] of women with [selcounsel = [who] of myself] )]]
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
1421
288
1529
348
inspectcounselcenter
20345.0
1
0
Number

BUTTON
1291
324
1416
357
inspect_counselcenter
ask counselcenters inspectcounselcenter [\nask women with [selcounsel = [who] of myself] [print (word \"woman: \" who \" counselstay: \" counselstay)]]
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
1149
15
1233
48
choice_hospital
choice_hospital
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
1150
54
1233
87
utility_influence
ask turtle 15176 [\n\nlet options hospital with [member? who  table:keys [rankinglist] of myself]\nlet womencompanion other women with [selcounsel = [selcounsel] of myself]\n\nask options [\n\n; make up a list of ranking for that option by other women in group\nlet ranking_others []\nlet ranking_othweight []\nlet sumtimetogether []\nforeach sort womencompanion [ z ->\nset ranking_others lput table:get [rankinglist] of z [who] of self ranking_others\nlet timetogether ifelse-value ([counselstay] of z / [counselstay] of myself >= 1) [1] [([counselstay] of z / [counselstay] of myself)]\nset ranking_othweight lput (table:get [rankinglist] of z [who] of self * timetogether) ranking_othweight\nset sumtimetogether lput timetogether sumtimetogether\nprint (word who \" timetogether: \" timetogether)\n\n]\nprint (word who \" ranking others: \" ranking_others)\nprint (word who \" ranking others weighted: \" ranking_othweight)\nprint (word \"sumtimetogether: \" reduce + sumtimetogether)\n; the total of utility given by ranking by other women in the group\nprint (word \" sum others ranking weighted \" reduce + ranking_othweight)\n\n; the total utility ranking given by own ranking and ranking by others, linked by sentence, then summed up\n; (to weight by influence)\n; let utility_othranking sentence table:get [rankinglist] of myself [who] of self ranking_othweight\n; set utility reduce + utility_ranking\n\nprint (word who \" own ranking: \" table:get [rankinglist] of myself [who] of self)\n\n; print (word who \" utility ranking: \" utility)\n\nset utility (((maxsocialmultiplier - social_multiplier) * table:get [rankinglist] of myself [who] of self) + (social_multiplier * ( (reduce + ranking_othweight)  / (reduce + sumtimetogether))))\n\nprint (word who \" utility ranking others: \" (social_multiplier * ( (reduce + ranking_othweight)  / (reduce + sumtimetogether))))\nprint (word who \" utility own ranking: \" ((maxsocialmultiplier - social_multiplier) * table:get [rankinglist] of myself [who] of self))\nprint (word who \" total utility: \" utility)\n; this is to test the utility assigned by other women in the group\n]\n\nset selectedhospital [who] of  rnd:weighted-one-of options [exp( utility)]\n\nprint (word \"own list: \" who \" : \" rankinglist)\nforeach sort womencompanion [y ->\nprint (word \"others: \" [who] of y \" : \" [rankinglist] of y)]\nprint (word \"selected hospital: \" selectedhospital)\n]
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
6
405
154
438
social_multiplier
social_multiplier
0
100
8.0
1
1
max
HORIZONTAL

INPUTBOX
5
441
108
501
maxsocialmultiplier
8.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

Test random utility model for counselcenter based on distance.
Each wave, an amount of women get pregnant and make a decision on the counselcenter.
They first scan in-radius 0.5 the available counselcenters, at each a utility is assigned based on distance and the one with closer distance is selected. The determinism of the choice is based on weighted parameter distance according to conditional logit.


## HOW IT WORKS

Each wave_pregnant, a total of count_pregnant women randomly extracted are assigned to be pregnant. They will execute the "choice" commmand. In the simulation, they will behave according to being "pregnant", until they "givebirth", which is a way to avoid extraction of the same woman twice. 
When called to execute "choice", they first scan the available counselcenters around them with in-radius 0.5, looking for at least 5 counselcenters (they can be more as long as match conditions); counselcenters have a capacity each (20 spots) that runs out as long as they are selected. If there are no counselcenters with empty spots, they enlarge the radius. This means the location is as local as possible. Once the set of possible counselcenters is available ( counselsoptions in choice block), the distance to the woman is calculated using dist reporter for each counselcenter (origin = woman, destination = counselcenter). For each counselcenter, a utility is computed by the individual woman as a weighted function of the distance, i.e.

Utility = weight_distance parameter * distance
Weight_distance parameter is negative because we need to select the option with lower distance, hence utility has to be negative [because higher utility for us means lower distance].
Note that the computed utility of the counselcenter will remain that one until a new woman will assign "her utility" to  that counselcenter based on the distance to her.

The actual selection of the closer counselcenter according to conditional logit (Pi = exp(Ui) / sum(exp(Uall)) is done with random-wheel-selection [rnd extension]:

rnd:weighted-one-of counselsoptions [exp( utility)]

this algorithm computes the weighted selection of options based on the size of a [reporter], in our case the exponentiation of the utility computed.
Note that with weight_distance = 0, all options have equal opportunity to be extracted, the lower weight_distance, the higher the chance of option with minimal lower distance will be selected. 

* What happens after the choice.

By "selection" here we mean that the woman will correct its own variable "selcounsel" in its mind to the ID (who) of the counselcenter selected. In this way, we can use this variable to map women assigned to the same counselcenter.
Once the woman has selected the counselcenter, it drops the available spots of the counselcenter by 1 unit, since the woman occupies one spot now. This will affect the options available to the next pregnant woman called to select a counselcenter, since the more time progresses, the fewer counselcenters spots are available.

## HOW TO USE IT

In this test, you can set the number of women who got pregnant at each wave with "count_pregnant". You can set how long a wave is with "wave_pregnant": it uses modulo based on ticks > 0 (mod check in NetLogo dictionary). "stop_it" sets how many ticks the simulation must run. For instance, with count_pregnant = 10 and wave_pregnant = 2 and stop_it 13, every 2 ticks 10 women get pregnant and select a counselcenter. This means 10 women are called at ticks = 2,4,6,8,10,12 = 60 women when the simulation stops.

## THINGS TO NOTICE

I let every pregnant woman to report their whoID, their location, the actual counselcenter it takes as possible options (they set the color of running woman), and report for each of them the distance to the woman, their capacity and their computed utility. After the selection is done, the woman reports her new selcounsel and updated values for counselcenters. Note that with lower weight_distance, the whoID of the counselcenter with lower distance should be now the selcounsel of woman, and that counselcenter report 1 unit less of capacity, With weight_distance = 0, every option should have the same probability to be extracted. You can also run in the command center:

ask womens who [choice] to test on the same woman specifically

## CAVEAT and next steps

* Considering utility = (weigthed_distance * distance), exp(utility) in NetLogo causes numbers too big, we need to normalize distance from 0 to 1 to avoid this
* In the next steps of modeling, women will occupy a spot as long as they are pregnant and then leave. In this step new women would come from a new wave of pregnancy. I wonder if with the current setting we risk women of the same cohort will attend counselcenters at the same time, though in different spaces. We should increase the chance of women of different cohorts to interact, either through randomness in starting selection or modulating the length of staying at the counselcenter
* Counselcenters now have a equal capacity, should this reflect the density of local population of gis area, or do we have the empirical actual capacity of each counselcenter?



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
