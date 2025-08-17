extensions [gis table csv rnd]
turtles-own [PRO_COM]
breed [hospital hospitals]
breed [women womens]
breed [counselcenter counselcenters]
globals [tuscany distservices]
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
  foreach gis:feature-list-of tuscany [ this-municipality ->                                                                        ; each municipality, if included in the table [and it is only once],
    if member? gis:property-value this-municipality "PRO_COM" table:keys my-table [                                                 ; will produce as many women in their area as the number of hospitalizations
    gis:create-turtles-inside-polygon this-municipality women  table:get my-table gis:property-value this-municipality "PRO_COM" [  ; women derive their pro_com from the municipality
     set shape "circle"
;     set color gis:property-value this-municipality "PRO_COM"
 ifelse any? hospital with [dist self myself <= 0] [set color red]
        [
ifelse any? hospital with [dist self myself > 0 and dist self myself <= 15] [set color yellow]
        [
ifelse any? hospital with [dist self myself > 15 and dist self myself <= 30] [set color orange]
          [
ifelse any? hospital with  [dist self myself > 30 and dist self myself <= 45] [set color brown]
              [
ifelse any? hospital with  [dist self myself > 45 and dist self myself <= 60] [set color violet]
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

end

to options_hospital

; let radius 1.5

; let hospitalsoptions no-turtles

; to make up an own list of hospitals to select from based on proximity
; while [count hospitalsoptions < 3] [
; set hospitalsoptions other  hospital in-radius radius with [capacity > 0 ]
; set radius radius + 1
; ]


;  ask  hospitalsoptions [
;  set color [color] of myself

;    ]

; to make up for ranking given to each hospital in the list key: ID hospital, value: [0,1] with beta distribution
; set rankinglist table:make
; foreach sort hospitalsoptions [ x ->
;    table:put rankinglist [who] of x normal mean_ranking sd_ranking
; ]
; ; ; ;  all options
set rankinglist table:make
foreach sort hospital [ x ->
    ifelse [who] of x = 50 [table:put rankinglist [who] of x normal 1 0 1 -1]
    [table:put rankinglist [who] of x normal mean_ranking sd_ranking 1 -1]

]


end

to go
if not any? women with [givenbirth = false] [stop]
    if ticks > 0 and ticks mod wave_pregnant = 0  [
    ask n-of count_pregnant women [set pregnant true]
  ]
  ask women [if pregnant = true and givenbirth = false [
    ifelse selcounsel = false
    [choice_counsel]
    [ifelse counselstay < 36
      [set counselstay counselstay + 1]
     [if selectedhospital = 0 [choice_hospital select_hospital]
      ]
    ]
  ]
  ]
  ask counselcenter [set capacity 20 - count women with [pregnant = true and selcounsel = [who] of myself and givenbirth = false]]
  plot-hospitals

  tick
end


to choice_counsel

 let radius 0.5

 let counselsoptions no-turtles

 while [count counselsoptions < 5] [
 set counselsoptions other  counselcenter in-radius radius with [capacity > 0 ]
 set radius radius + 1
  ]

ask  counselcenter [
; set color [color] of myself
set utility (weight_distance_counsel * dist myself self)
]

set selcounsel [who] of rnd:weighted-one-of counselcenter [exp( utility)]

end


to choice_hospital
; identify women member of the same counselsente (not necessary 36 weeks, but the command is executed by those with week 36)
let womencompanion other women with [pregnant = true and givenbirth = false and selcounsel = [selcounsel] of myself]

;; to set up the complete basket choice of hospitals in the conversation
; if the woman has not the hospital of another companion woman in mind, she will add
let hospa []
foreach sort womencompanion [ z ->
let dictall table:keys [rankinglist] of z
foreach dictall [x ->
 if not member? x hospa [
 set hospa lput x hospa ]
      ]
    ]

; hospitals who are not in the original rankinglist of the woman are given ranking 0 (each operation will have effect 0 for this hospital)
 foreach hospa [y ->
 if not member? y table:keys rankinglist [
 table:put rankinglist y 0
 ]
 ]

; also women in the circle of counselcenter are given the complete list with ranking 0 for hospitals not originally considered
  ask womencompanion [
    foreach table:keys [rankinglist] of myself [y ->
      if not member? y table:keys [rankinglist] of self [
 table:put [rankinglist] of self y 0
 ]
 ]
  ]
end

to select_hospital
let womencompanion other women with [pregnant = true and givenbirth = false and selcounsel = [selcounsel] of myself]
;; here the real choice
; basket choice of hospitals to select from: all those now in the rankinglist
  let options hospital with [member? who table:keys  [rankinglist] of myself]


; each hospital option is given an utility for that agent woman executing the command
  ask options [


   let ranking_othweight []
   let sumtimetogether []
   ; for each woman in the circle counselcenter, the time spent together and the ranking of the hospital in the group is computed, with weighted mean, weigthed by the time spent together
   foreach sort womencompanion [ z ->
    ; to compute time together <= 1
    let timetogether ifelse-value ([counselstay] of z / [counselstay] of myself >= 1) [1] [([counselstay] of z / [counselstay] of myself)]
    ; the weighted effect of ranking of the companion woman by time spent together
   set ranking_othweight lput (table:get [rankinglist] of z [who] of self * timetogether) ranking_othweight
    ; the sum of all time spent together with all women in circle counselcenter
   set sumtimetogether lput timetogether sumtimetogether

   ]

  ;; compute the system utility for random utility model
  ifelse any? womencompanion
    ; if there are other women, the utility is composed by (beta_ind * own ranking) plus (beta_soc * weighted mean) minus (weight_distance * distance)
    ; weighted mean is computed with sum ranking of others weighted by time together / sum time together (timetogether is weight of weighted mean). beta_ind and beta_soc are complementary
    [set utility (((weight_socialinfluence - social_multiplier) * table:get [rankinglist] of myself [who] of self) + (social_multiplier * (reduce +   ranking_othweight / (reduce + sumtimetogether + 0.0001))  ) + (weight_distance_hospital * dist myself self ))]
    ; in case there is not other companion, so the decision is based on own ranking and distance
    [set utility (((weight_socialinfluence - social_multiplier) * table:get [rankinglist] of myself [who] of self)  + (weight_distance_hospital * dist myself self ))]

  ]

 ; selection of hospital with random utility
 set selectedhospital [who] of rnd:weighted-one-of options [exp(utility)]
 ; at this step just for report counting
 set givenbirth true
 set pregnant false

 ; debug
; print(word who " selected hospital: " selectedhospital)


end

to plot-hospitals
  set-current-plot "Hospital choice"
  clear-plot

if plot_show = "hospitalizations" [
  ; Sort hospitals by real hospitalizations
  let sorted-hospitals sort-by [[a b] -> [hospitalizations] of a < [hospitalizations] of b] hospital

  ; First plot: real hospitalizations
  set-current-plot-pen "actual"
  let index 0
  foreach sorted-hospitals [
    t ->
      let yval [hospitalizations] of t
      plotxy index 0
      plotxy index yval
      set index index + 1
  ]

  ; Now compute simulated hospital choices per hospital
  ask hospital [
    set womenhospital count women with [selectedhospital = [who] of myself]
  ]

  ; Sort hospitals again in the same order to match indexing
  let sorted-womenhospital sort-by [[a b] -> [womenhospital] of a < [womenhospital] of b] hospital

  ; Second plot: simulated choices (overlay on same x)
  set-current-plot-pen "simulated"
  let indexsim 0
  foreach sorted-womenhospital [
    t ->
      let yval [womenhospital] of t
      plotxy indexsim 0
      plotxy indexsim yval
      set indexsim indexsim + 1
  ]
  ]

  if plot_show = "mobilities" [
  ; Sort hospitals by real hospitalizations
    ask hospital [
      set mobilitiesemp count women with [selectedhospitalemp = [who] of myself and pro_com != [pro_com] of myself]]
  let sorted-hospitals sort-by [[a b] -> [mobilitiesemp] of a < [mobilitiesemp] of b] hospital

  ; First plot: real hospitalizations
  set-current-plot-pen "actual"
  let index 0
  foreach sorted-hospitals [
    t ->
      let yval [mobilitiesemp] of t
      plotxy index 0
      plotxy index yval
      set index index + 1
  ]

  ; Now compute simulated hospital choices per hospital
  ask hospital [
      set womenhospital count women with [selectedhospital = [who] of myself and pro_com != [pro_com] of myself]
  ]

  ; Sort hospitals again in the same order to match indexing
  let sorted-womenhospital sort-by [[a b] -> [womenhospital] of a < [womenhospital] of b] hospital

  ; Second plot: simulated choices (overlay on same x)
  set-current-plot-pen "simulated"
  let indexsim 0
  foreach sorted-womenhospital [
    t ->
      let yval [womenhospital] of t
      plotxy indexsim 0
      plotxy indexsim yval
      set indexsim indexsim + 1
  ]
  ]

end

to-report dist [origin destination]
let destinationpos position [pro_com] of destination item 0 distservices
report item destinationpos item 0 filter [x -> first x = [pro_com] of origin] distservices
end

to-report normal [means std-devs maxlim minlim]
  let value random-normal means std-devs
  ;; Clamp to -1 to 1
  if value > maxlim [ set value maxlim ]
  if value < minlim [ set value minlim]
  report value
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
16
10
79
43
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
1636
54
1864
87
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
885
425
1019
458
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
745
425
878
458
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
1757
163
1863
196
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
1637
160
1751
230
area_municipality
48017.0
1
0
Number

INPUTBOX
1636
93
1751
153
MUNICIPALITY_name
Firenze
1
0
String (reporter)

BUTTON
1758
110
1863
143
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
746
462
879
495
show counselcenter
ask counselcenter [set color violet show-turtle]
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
886
462
1019
495
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
1759
197
1864
230
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
1026
425
1141
458
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
1023
463
1140
496
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
940
401
1021
419
the three actors
10
0.0
1

OUTPUT
728
14
1074
383
10

BUTTON
1000
501
1072
534
testdistances
print dist turtle origin_from turtle destination_to
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
745
502
879
562
origin_from
56.0
1
0
Number

INPUTBOX
881
502
996
562
destination_to
1797.0
1
0
Number

BUTTON
99
10
164
43
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
239
191
272
weight_distance_counsel
weight_distance_counsel
-100
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
1101
142
1234
187
capacity counselcenters
mean [capacity] of counselcenter
2
1
11

MONITOR
1241
143
1354
188
women given birth
count women with [givenbirth = true]
17
1
11

BUTTON
1078
500
1191
533
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
12
57
96
117
count_pregnant
100.0
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
1664
330
1790
363
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
1795
328
1903
388
inspectcounselcenter
20345.0
1
0
Number

BUTTON
1665
364
1790
397
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

SLIDER
36
341
188
374
social_multiplier
social_multiplier
0
100
0.0
1
1
max
HORIZONTAL

INPUTBOX
49
379
170
439
weight_socialinfluence
0.0
1
0
Number

SLIDER
12
162
115
195
mean_ranking
mean_ranking
-1
1
-9.9
0.1
1
NIL
HORIZONTAL

SLIDER
117
161
220
194
sd_ranking
sd_ranking
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
38
303
191
336
weight_distance_hospital
weight_distance_hospital
-50
50
-5.0
1
1
NIL
HORIZONTAL

PLOT
1089
10
1439
134
Hospital choice
NIL
NIL
0.0
10.0
0.0
2000.0
true
true
"" ""
PENS
"actual" 1.0 1 -2674135 true "" ""
"simulated" 1.0 1 -13345367 true "" ""

TEXTBOX
72
135
164
153
distribution ranking
10
0.0
1

TEXTBOX
77
280
163
298
selection hospital
10
0.0
1

TEXTBOX
53
213
163
231
selection counselcenter
10
0.0
1

BUTTON
1373
219
1465
252
show mobility
displaymap\nask links [die]\n ask counselcenter [ hide-turtle]\n ask women [ hide-turtle]\n; ask hospital [ set color gray]\nask hospitals hospital_id [\nshow-turtle\nset color blue\nif plot_show = \"hospitalizations\" [\n; ask women with [selectedhospitalemp = [who] of myself]\n; [show-turtle \n; set color scale-color 12 dist self myself 260 0  ]\n\nshow (word id \" municip: \" pro_com)\n\nforeach remove-duplicates [pro_com] of women with [selectedhospitalemp = [who] of myself][x ->\nshow (word x \" dist: \" dist self one-of women with [pro_com = x])\n\n]\n]\n\nif plot_show = \"mobilities\" [\n; ask women with [selectedhospitalemp = [who] of myself and pro_com != [pro_com] of myself]\n; [show-turtle \n; set color scale-color 12 dist self myself 260 0  ]\n\nshow (word id \" municip: \" pro_com)\n\nforeach remove-duplicates [pro_com] of women with [selectedhospitalemp = [who] of myself and pro_com != [pro_com] of myself][x ->\nshow (word x \" dist: \" dist self one-of women with [pro_com = x])\n\n]\n]\n\n\n\n]\n\n;;\nask links [die]\nifelse emp_tgt \n[if any? women with [selectedhospitalemp = hospital_id] [\nask women with [selectedhospitalemp = hospital_id][create-link-with one-of hospital with [ who = hospital_id]]]]\n[if any? women with [selectedhospital = hospital_id] [\nask women with [selectedhospital = hospital_id][create-link-with one-of hospital with [ who = hospital_id]]]]\nask women [ask my-out-links [set color [color] of myself]]\n\n\n\nset-current-plot \"mobilities hospital_id\"\nclear-plot\nset-current-plot-pen \"actual\"\nif plot_show = \"hospitalizations\" [\nlet womenselecthosp women with [selectedhospitalemp = [who] of hospitals hospital_id]\nlet xs [ dist self hospitals hospital_id ] of womenselecthosp\nset-plot-x-range 0 200\n\nhistogram xs\nprint sort xs]\nif plot_show = \"mobilities\" [\nlet womenselecthosp women with [selectedhospitalemp = [who] of hospitals hospital_id and pro_com != [pro_com] of hospitals hospital_id]\nlet xs [ dist self hospitals hospital_id ] of womenselecthosp\nset-plot-x-range 0 200\n\nhistogram xs\nprint sort xs]\n\nset-current-plot-pen \"simulated\"\nif plot_show = \"hospitalizations\" [\nlet womenselecthosp women with [selectedhospital = [who] of hospitals hospital_id]\nlet xs [ dist self hospitals hospital_id ] of womenselecthosp\nset-plot-x-range 0 200\n\nhistogram xs\nprint sort xs]\nif plot_show = \"mobilities\" [\nlet womenselecthosp women with [selectedhospital = [who] of hospitals hospital_id and pro_com != [pro_com] of hospitals hospital_id]\nlet xs [ dist self hospitals hospital_id ] of womenselecthosp\nset-plot-x-range 0 200\n\nhistogram xs\nprint sort xs]\n\n\n\n\n\nlet sorted-hospitals sort-by [[a b] -> [womenhospital] of a > [womenhospital] of b] hospital\n\n \n  foreach sorted-hospitals [ h ->\n print (word [who] of h \" :simul: \" [womenhospital] of h)\n]\n\n\n\n
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
1364
149
1442
209
hospital_id
65.0
1
0
Number

CHOOSER
1384
64
1484
109
plot_show
plot_show
"hospitalizations" "mobilities"
0

PLOT
1093
205
1362
359
mobilities hospital_id
NIL
NIL
0.0
100.0
0.0
200.0
true
true
"" ""
PENS
"actual" 1.0 1 -2674135 true "" ""
"simulated" 1.0 1 -13345367 true "" ""

BUTTON
1372
258
1467
291
link_all_hospitals
ask links [die]\nifelse emp_tgt \n[ask women [create-link-with one-of hospital with [who = [selectedhospitalemp] of myself]]]\n[ask women [create-link-with one-of hospital with [who = [selectedhospital] of myself]]]\nask women [ask my-out-links [set color [color] of myself]]
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
1372
294
1475
327
emp_tgt
emp_tgt
1
1
-1000

PLOT
21
454
206
577
distribution ranking
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

BUTTON
66
579
166
612
distribution ranking
set-current-plot \"distribution ranking\"\n  clear-plot\n  \n  ; collect n samples\n  let samples []\n  repeat 20177 [\n    set samples lput (normal mean_ranking sd_ranking 1 -1) samples\n  ]\n  \n  ; set axis ranges\n  ; set-plot-x-range -1 1\n   ;set-plot-y-range 0 22177 / 5   ;; rough guess for y max\n  \n  ; plot as histogram\n  set-histogram-num-bars 22177\n  set-plot-x-range -1.01 1.01 \n  histogram samples\n  print sort samples\n
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
267
518
449
609
women color - min distance hospital\n0 = red: 8512, 42%\n1 - 15 = yellow: 6343, 31%\n16 - 30 = orange: 3162, 15%\n31 - 45 = brown: 1754, 8%\n46 - 60 = violet: 326, 1%\n+ 61 = blue: 80, 0.3%
10
0.0
1

BUTTON
1001
536
1072
569
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
471
518
622
609
women, distance counselcenter\n(<= 0) 10088, 49.99%\n(0-15) 7489, 37.11%\n(15-30) 2379, 11.7%\n(30-45) 213, 1.05%\n(45-60) 7, 0.03%\n(+ 60) 1, 0.004%
10
0.0
1

@#$#@#$#@
## WHAT IS IT?

Hospital choice based on social multiplier of formed networks in counselcenters. Actors of the simulation are women, counselcenters and hospitals. Random utility models applied for the selection of counselcenter and then hospitals. One cycle is equivalent to one week.

## NOTES ON HOSPITALS

* San Rossore: private
* Serristore Figlini: not a maternity department

## HOW IT WORKS

Each wave_pregnant, a total of count_pregnant women randomly extracted are assigned to be pregnant. At initialization of the model, women hold a ranking distribution according to normal distribution (average and standard deviation to compute). The distribution is for hospitals in a radius. The first select a counselsenter where to follow a preparatory course where networks are formed. The selection occurs via a random utility model, selecting an array of options in a radius based on available spot, the decision occurs based on the distance, with higher probability for closer counselcenters. Women are connected to other women pregnant in the same counselcenter. They will stay until week 36. Due to different time of execution, time spent varies by individual woman. Women who reach week 36 need to decide the hospital to give birth. The list of options to decide from are the original one for the individual agent, plus hospitals brought to the discussion by each agent in the counselcenter.
 This decision is implemented through a random utility model, based on distance (closer the better), plus individual ranking, plus social multiplies which models the weight of preference of other women in the network on the actual selection decision of agents. Weight of individual ranking and weight of social multiplier are complementary. The social multiplier is modeled with a weight given to weighted mean of women in the counselcenter for each hospital. The weight of the preference of each other woman to the selection of the woman at week 36 is equivalent to the time spent with that woman during the stay at the counselstay. As such, women most spent time with have higher influence. After the hospital is selected, the woman is given status givenbirth and is out of the dynamics of the simulation. The simulation ends when all women have given birth. 


## HOW TO USE IT

* mean_ranking, sd_ranking: to set the distribution of ranking for hospitals. Currently it is global, i.e. not differentiating distribution for specific hospitals or else
* weight_distance_counsel: weight for distance (negative) in selection counselcenter
* weight_distance_hospital: weight for distance (negative) in selection hospital
* social_multiplier: weight for effect social influence in selection hospital
* weight_socialinfluence: used to compute weight of individual ranking as complementary to social multiplier. E.g. with weight_socialinfluence equal 10 and social_multiplier equal 6, weight individual ranking is equal 4

## THINGS TO NOTICE

* Hospital choice in the printed box: actual number of births per hospital, ID who is reported (below in the box the complete name)
* Monitors: simulated births per hospital
* Hospital choice: each bar is the number of births per hospital (red: actual empirical, blue is simulated). Not possible to report the label.

## THINGS TO INVESTIGATE AND CHANGE

*  weight_distance_counsel: maybe we can get it out: it complicates understanding of the dynamics since we need to understand the role of distance weight in the final decision of hospital. What most matters is under what condition women are "forced" to interact with others and consider options out of their space. This mostly happends because of limited capacity and need to find a spot elsewhere, due to capacity
* effect of density of pregnant women in the radius of hospitals, and more precisely the number of women pregnant at the same time, what effects this would have on reinforcing the effect of ranking on hospital selection
* the distribution of ranking, ideally changing by zone, so to effectively study under what conditions women would select one hospital that they would not consider or holds low ranking. This also considering the role of social influence over distance
* The effect of the selection of one woman on other women of their spatial proximity (municipality), i.e. currently the ranking of hospital is set at initialization, so as the list of options bounded to space, women who give birth and select one hospital could change the initial list of options as effect of word-of-mouth of women who selected in a previous cycle. This dynamic is to be implemented.

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

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
