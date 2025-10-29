extensions [gis table csv rnd profiler]
turtles-own [PRO_COM]
breed [hospital hospitals]
breed [women womens]
breed [counselcenter counselcenters]
globals [tuscany distservices distservicesnorm]
counselcenter-own [ID capacity utility womencounsel]
hospital-own [ID hospitalizations utility capacity womenhospital mobilitiesemp pneranking rankbywomen]
women-own [pregnant givenbirth selcounsel counselstay rankinglist distancehosp selectedhospital selectedhospitalemp timeatbirth eps_acceptance mu_convergence prechoicelist friendselected]



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
    hide-turtle
]
  ]
end


to create-hospitals
let hospitals2023 csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/accessi_parto_ospedali_used.csv"
let rankhosp csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/ranking_hospitals.csv"

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
    set shape "triangle"
      let list_effective filter [ [s] -> item 2 s = x ] but-first hospitals2023              ; it filters the movement rows in the dataset [here sublists] where it is mentioned
      set hospitalizations reduce + map [ [s] -> item 5 s ] list_effective                   ; the total hospitalizations per hospital across movements are computed
      set utility 0
      set pro_com  gis:property-value gis:find-one-feature tuscany "PRO_COM" item 4 item 0 list_effective "PRO_COM"     ; for relocation, the location with the first valid register of birth (to not repeat)
      let loc gis:location-of gis:random-point-inside gis:find-one-feature tuscany "PRO_COM" item 4 item 0 list_effective
      set xcor item 0 loc
      set ycor item 1 loc
      let effective_rank filter [ [s] -> item 0 s = x ] but-first rankhosp
      set pneranking item 1 item 0 effective_rank
      set color (ifelse-value
        pneranking = -1 [magenta]
        pneranking = -0.5 [blue]
        pneranking = 0 [green]
        pneranking = 0.5 [pink]
        [cyan]


      )

    ]
  ]



end

to create-womens
let df csv:from-file "C:/Users/LENOVO/Documents/GitHub/childbirthod/data/accessi_parto_ospedali_used.csv"

foreach sort hospital [ x ->
 foreach but-first df [s ->
if  item 2 s = [id] of x [
 let mun gis:find-one-feature tuscany "PRO_COM" item 0 s


        gis:create-turtles-inside-polygon mun women ifelse-value (rescale15 = true) [item 6 s][item 5 s] [

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
      set PRO_COM item 0 s
      set selectedhospitalemp [who] of x
      set timeatbirth 0

  ]
]
]
]

end

to options_hospital

set rankinglist table:make
set distancehosp table:make


; the initial distribution of ranking (opinion quality): either totally random or with distribution centered on pne ranking and standard deviation
foreach sort hospital [y ->
    table:put rankinglist [who] of y ifelse-value (initrankrnd) [precision ((random-float 2) - 1) 3][ normal [pneranking] of y initrank_sd 1 -1]
]

foreach sort hospital [y ->
table:put distancehosp [who] of y dist self y distservicesnorm
]

end

to go
random-seed 10
if not any? women with [givenbirth = false] [report_data "export" stop ]


  ask one-of women with [pregnant = false and givenbirth = false] [
   set pregnant true
   if selectedhospital = 0 [select_hospital]
      ]

  if ticks > 0 and ticks mod 80 = 0 [ ask women with [givenbirth = true][
   communicate_experience
  ]
  ]

if avgrank [
 ask hospital [
 let h who
 let vals ifelse-value (rank_by_procom = 0) [[ table:get rankinglist h ] of women] [ [ table:get rankinglist h ] of women with [pro_com = rank_by_procom] ]
 set rankbywomen mean vals

 ]
  ]


  plot-hospitals

  tick
end


to select_hospital

let distance_threshold_updated distance_threshold
let friends no-turtles

; loop to find friends for social influence
while [count friends < n_network][

set distance_threshold_updated distance_threshold_updated + 1
; filters all vectorfeatures for extraction. position procom 0: header of distservices. item 0 filter [], item 0 (procom) of rows whose distance falls within the threshold
let matchrad filter [f -> item position pro_com item 0 distservices item 0 filter [x -> first x = gis:property-value f "PRO_COM"] distservices  <= distance_threshold_updated] gis:feature-list-of tuscany
; list pro_com of matching vectorfeatures
let listrad map [ f -> gis:property-value f "PRO_COM" ] matchrad
  set friends n-of (min list n_network (count other women with [member? pro_com listrad])) other women with [member? pro_com listrad]

]

  set friendselected (count friends with [selectedhospital != 0] / count friends)

  ask hospital [
    ; distance of hospital used in utility estimate
    let distancefrom table:get [distancehosp] of myself [who] of self
    ; opinion on quality of the hospital by caller
    let opinionquality table:get [rankinglist] of myself [who] of self
    let ranking_othweight []
    let totweightfriend []
    let otherranking table:make
    let selectbyfriend table:make
    foreach sort friends   [ z ->
      ; following deffuant, only friends whose quality opinion of that hospital fall within the latitude of acceptance will be considered for the weighted average
      ; if abs(table:get [rankinglist] of z [who] of self - table:get [rankinglist] of myself [who] of self) <= latitude_acceptance [
      ; weight of friend: 1 - distance to woman
      let weightfriend ifelse-value ([selectedhospital] of z = [who] of self) [weight_experience][(1 - weight_experience)] ; (1 - dist myself z distservicesnorm)
      ; denominator in weighted average
      set totweightfriend lput weightfriend totweightfriend
      ; numerator weighted average (rank of hospital by friend * weight of friend)
    set ranking_othweight lput (table:get [rankinglist] of z [who] of self * weightfriend) ranking_othweight
     table:put otherranking [who] of z table:get [rankinglist] of z [who] of self
     table:put selectbyfriend [who] of z [selectedhospital] of z
    ]
    ; if there are no friends to be considered, or their weight is 0, then only the own initial quality opinion is used
    ; if there are such friends, the simil-deffuant update of the opinion quality occurs
    set opinionquality ifelse-value (empty? totweightfriend or reduce + totweightfriend = 0) [opinionquality] [( opinionquality + social_multiplier * ((reduce + ranking_othweight / reduce + totweightfriend) - opinionquality ) )]

    ; in the utility estimate, the weighted effect of distance and weighted effect of opinion quality (individual or amplified due to above line)
    set utility ( (weight_distance_hospital * (distancefrom * 10  )) +  (weight_opinion * opinionquality)  )

  ]

   set selectedhospital [who] of rnd:weighted-one-of hospital [exp(utility - max [utility] of hospital)]
  ; the "ranking experience" of influncers at next steps, derived from the objective pne, to which a random term can be added for robustness check
  set prechoicelist rankinglist
  table:put rankinglist selectedhospital  normal [pneranking] of one-of hospital with [who = [selectedhospital] of myself] uptrnk_sd 1 -1

if show_networks [
    let selectedone one-of hospital with [who = [selectedhospital] of myself]
 create-link-with selectedone
 ask my-out-links [

      ifelse dist selectedone myself distservices <= 0 [set color red]
        [ifelse dist selectedone myself distservices > 0 and dist selectedone myself distservices <= 15  [set color yellow]
          [ ifelse dist selectedone myself distservices > 15 and dist selectedone myself distservices <= 30 [set color orange]
            [ifelse dist selectedone myself distservices > 30 and dist selectedone myself distservices <= 45 [set color brown]
              [ifelse dist selectedone myself distservices > 45 and dist selectedone myself distservices <= 60 [set color violet]
                [set color blue]
              ]
            ]
          ]
      ]
    ]

    ]

 set givenbirth true
 set pregnant false
 set timeatbirth ticks

end

to communicate_experience

;  if any? other women with [pro_com = [pro_com] of myself and pregnant = false and givenbirth = false] [
;    let alter n-of round (0.01 * count other women with [pro_com = [pro_com] of myself and pregnant = false and givenbirth = false]) other women with [pro_com = [pro_com] of myself and pregnant = false and givenbirth = false]

  let topic selectedhospital
;  print(word who " sel: " topic)

  if any? other women with [pro_com = [pro_com] of myself and pregnant = false and selectedhospital != [selectedhospital] of myself] [   ; and pregnant = false and givenbirth = false
    let alter n-of round (0.01 * count other women with [pro_com = [pro_com] of myself and pregnant = false and selectedhospital != topic]) other women with [pro_com = [pro_com] of myself and pregnant = false and selectedhospital != topic]

    ask alter [
      set eps_acceptance ifelse-value (givenbirth = true)[eps_birthtrue][eps_notbirth]
      set mu_convergence ifelse-value (givenbirth = true)[mu_birthtrue][ mu_notbirth]
    ;]

  ;  foreach sort alter [ f ->
;      print(word "alter: " [who] of f " opselected: " table:get [rankinglist] of f selectedhospital  " ticks: " ticks) ; TEST

      if abs(table:get rankinglist topic - table:get [rankinglist] of myself topic) <= eps_acceptance [
        table:put rankinglist topic ( table:get rankinglist topic + (mu_convergence * (table:get [rankinglist] of myself topic - table:get rankinglist topic)))
;      print(word "caller: " who " selcaller: " selectedhospital  " op: "  table:get rankinglist selectedhospital  " alter: " [who] of f " newhosp: " table:get [rankinglist] of f selectedhospital " ticks: " ticks ) ; TEST

    ]
  ]
  ]

end

to plot-hospitals
if plot_mobil [
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
  ]
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

to-report rankupdate [idd]
  if any? women with [ table:has-key? rankinglist [who] of idd ] [
    report mean [ table:get rankinglist [who] of idd ] of (women with [ table:has-key? rankinglist [who] of idd ])]
end

to-report womendiscuss [idd]
  if any? women with [ table:has-key? rankinglist [who] of idd ] [
    report count women with [table:has-key? rankinglist [who] of idd]]
end

to report_data [filename]

  let param-names  ["rescale15" "initrankrnd" "initrank_sd" "distance_threshold"  "n_network"  "weight_distance_hospital"  "weight_opinion" "social_multiplier" "weight_experience" "uptrnk_sd" "eps_birthtrue" "eps_notbirth" "mu_birthtrue" "mu_notbirth"  ]
  let param-values (list rescale15 initrankrnd initrank_sd distance_threshold n_network weight_distance_hospital weight_opinion social_multiplier weight_experience uptrnk_sd eps_birthtrue eps_notbirth mu_birthtrue mu_notbirth )

  let core-header ["who" "timeatbirth" "pro_com" "selectedhospitalemp" "name_selectedhospitalemp" "procom_selectedhospitalemp" "selectedhospital" "name_selectedhospital" "procom_selectedhospital" "friendselected" "prechoicelist" "rankinglist"  ]
  let header sentence core-header param-names
  let rows (list header)

  ;; build rows in a stable order (by who)
  foreach sort women [ w ->
    let core-row (list
      [who] of w
      [timeatbirth] of w
      [pro_com] of w
      [selectedhospitalemp] of w
      [id] of one-of hospital with [who = [selectedhospitalemp] of w]
      [pro_com] of one-of hospital with [who = [selectedhospitalemp] of w]
      [selectedhospital] of w
      [id] of one-of hospital with [who = [selectedhospital] of w]
      [pro_com] of one-of hospital with [who = [selectedhospital] of w]
      [friendselected] of w
      [prechoicelist] of w
      [rankinglist] of w
    )
    ;; append metadata + parameters to each row
    let row sentence core-row (sentence param-values)
    set rows lput row rows
  ]

  let stringa remove-item 14 remove-item 11 remove-item 6 remove-item 4 remove-item 2 word substring date-and-time 0 12 substring date-and-time 16 27
  let first6 substring stringa 0 6
  let mid substring stringa 6 9
  let last9 substring stringa (length stringa - 9) length stringa
  let stringappear (word first6 "_" mid "_" last9)
  csv:to-file (word "data_bs/" filename "_" stringappear ".csv") rows
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
15
19
78
52
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
1208
395
1302
428
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
1097
396
1203
429
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
1097
433
1204
466
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
1209
432
1304
465
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
1308
394
1386
427
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
1306
433
1387
466
show hospital
ask hospital [\nset size 1\nset color (ifelse-value\n        pneranking = -1 [magenta]\n        pneranking = -0.5 [blue]\n        pneranking = 0 [green]\n        pneranking = 0.5 [pink]\n        [cyan]\n\n\n      ) show-turtle]
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
1054
413
1094
454
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
895
589
967
622
testdistances
print dist turtle origin_from turtle destination_to distservicesnorm 
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
728
587
804
647
origin_from
6194.0
1
0
Number

INPUTBOX
806
587
891
647
destination_to
5585.0
1
0
Number

BUTTON
255
571
320
604
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
0

MONITOR
252
518
320
563
given birth
count women with [givenbirth = true]
17
1
11

SLIDER
32
264
185
297
weight_opinion
weight_opinion
-100
100
10.0
1
1
max
HORIZONTAL

SLIDER
32
228
186
261
weight_distance_hospital
weight_distance_hospital
-50
0
0.0
1
1
NIL
HORIZONTAL

TEXTBOX
74
212
160
230
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
432
522
502
555
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
1327
478
1476
582
women, distance counselcenter\n[ not visualize]\n(<= 0) 10088, 49.99%\n(0-15) 7489, 37.11%\n(15-30) 2379, 11.7%\n(30-45) 213, 1.05%\n(45-60) 7, 0.03%\n(+ 60) 1, 0.004%
10
0.0
1

SLIDER
45
131
175
164
distance_threshold
distance_threshold
0
260
0.0
1
1
NIL
HORIZONTAL

BUTTON
582
594
702
627
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
484
558
600
591
show_networks
show_networks
1
1
-1000

CHOOSER
740
10
832
55
hospital_id
hospital_id
50 61 58 60 48 63 53 64 69 56 66 51 59 65 57 62 55 49 52 54 71 68 67 70
0

BUTTON
605
524
700
557
highlight hospital
ask hospitals hospital_id [set  size 2]\nplot-hospitals
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
728
214
1036
364
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
"0" 1.0 0 -2674135 true "" "if plot_mobil [plot (distchoicezero hospitals hospital_id)]"
"1-15" 1.0 0 -1184463 true "" "if plot_mobil [plot (distchoice hospitals hospital_id 0 15)]"
"16-30" 1.0 0 -955883 true "" "if plot_mobil [plot (distchoice hospitals hospital_id 15 30 )]"
"31-45" 1.0 0 -6459832 true "" "if plot_mobil [plot (distchoice hospitals hospital_id 30 45)]"
"46-60" 1.0 0 -8630108 true "" "if plot_mobil [plot (distchoice hospitals hospital_id 45 60)]"
"61+" 1.0 0 -13345367 true "" "if plot_mobil [plot (distchoicemax hospitals hospital_id 60)]"

TEXTBOX
68
112
154
130
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
421
563
NIL
count women
2
1
11

SLIDER
45
167
175
200
n_network
n_network
0
100
50.0
1
1
NIL
HORIZONTAL

SWITCH
509
523
599
556
emp_net
emp_net
1
1
-1000

BUTTON
494
594
578
627
emp_mobilities
ask women [let selectedoneemp one-of hospital with [who = [selectedhospitalemp] of myself]\ncreate-link-with selectedoneemp\nask my-out-links [\n\n      ifelse dist selectedoneemp myself distservices <= 0 [set color red]\n        [ifelse dist selectedoneemp myself distservices > 0 and dist selectedoneemp myself distservices <= 15  [set color yellow]\n          [ ifelse dist selectedoneemp myself distservices > 15 and dist selectedoneemp myself distservices <= 30 [set color orange]\n            [ifelse dist selectedoneemp myself distservices > 30 and dist selectedoneemp myself distservices <= 45 [set color brown]\n              [ifelse dist selectedoneemp myself distservices > 45 and dist selectedoneemp myself distservices <= 60 [set color violet]\n                [set color blue]\n              ]\n            ]\n          ]\n      ]\n    ]\n\n]
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
91
18
207
51
rescale15
rescale15
1
1
-1000

BUTTON
607
558
701
591
sim_mobilitiies
ask hospital [print (word who \" sim: \" count women with [selectedhospital = [who] of myself])]
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
324
571
394
604
profiler
profiler:start         ;; start profiling\nrepeat 100 [ go ]       ;; run something you want to measure\nprofiler:stop          ;; stop profiling\nprint profiler:report  ;; view the results\nprofiler:reset         ;; clear the data
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
54
393
165
426
uptrnk_sd
uptrnk_sd
0
1
0.0
0.05
1
NIL
HORIZONTAL

TEXTBOX
58
376
163
394
rank post-experience
10
0.0
1

PLOT
727
367
1037
517
Ranking hospital
NIL
NIL
0.0
10.0
-1.0
1.0
true
true
"" ""
PENS
"PNE" 1.0 0 -2674135 true "" "if avgrank [plot ([pneranking] of one-of hospital with [who = hospital_id])]"
"avg_simul" 1.0 0 -13345367 true "" "if avgrank [plot ([rankbywomen] of one-of hospital with [who = hospital_id])]"

SWITCH
945
482
1035
515
avgrank
avgrank
0
1
-1000

SWITCH
944
176
1037
209
plot_mobil
plot_mobil
0
1
-1000

BUTTON
973
528
1050
561
report_ranking
 ask hospital [\n let h who\n let vals ifelse-value (rank_by_procom = 0) [[ table:get rankinglist h ] of women] [ [ table:get rankinglist h ] of women with [pro_com = rank_by_procom] ]\n set rankbywomen mean vals\n let sdd standard-deviation vals\n print (word who \" name: \" id \" pne: \" pneranking \" avg: \" rankbywomen  \" sd: \" sdd \" PNE-avg: \" (pneranking - rankbywomen))\n ]
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
43
454
163
472
deffuant opinion dynamic
10
0.0
1

SLIDER
31
334
185
367
weight_experience
weight_experience
0
1
1.0
0.1
1
NIL
HORIZONTAL

INPUTBOX
878
521
970
581
rank_by_procom
53011.0
1
0
Number

SLIDER
112
69
211
102
initrank_sd
initrank_sd
0
1
0.0
0.1
1
NIL
HORIZONTAL

SWITCH
8
70
103
103
initrankrnd
initrankrnd
0
1
-1000

SLIDER
32
298
185
331
social_multiplier
social_multiplier
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
3
472
104
505
eps_birthtrue
eps_birthtrue
0
2
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
108
472
205
505
eps_notbirth
eps_notbirth
0
2
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
4
509
105
542
mu_birthtrue
mu_birthtrue
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
108
508
207
541
mu_notbirth
mu_notbirth
0
1
0.5
0.1
1
NIL
HORIZONTAL

INPUTBOX
728
521
819
581
COMUNE
Firenze
1
0
String

BUTTON
820
530
875
563
pro_com
show gis:property-value (gis:find-one-feature tuscany \"COMUNE\" COMUNE) \"PRO_COM\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

The model simulates the effect of social influence and distance on the selection of childbirth hospitals and diffusion of ranking of hospitals, and how the two affect each other. From the dynamics modeling perspective, the work combines discrete choice model and opinion dynamics.

The model is initialized with geo-data on Tuscany, main actors are women and hospital. Agent-types include also counsel-centers, not used. A normalized matrix distance reports time to travel between municipalities of agents.

## HOW IT WORKS

At time 0, every woman is given a vector of the distance to each hospital and a random distribution of ranking for each hospital between -1 and +1.
At each step, one woman becomes pregnant and has to select one hospital where to give birth. The selection follows a random utility model, where a utility is attributed to each hospital. The deterministic effect over the random selection of one hospital is due by two elements: a weighted effect of distance and a weighted effect of social influence, which implements the social multiplier. For the social multiplier, the agent selects 50 agents to ask suggestion. Networks vary by the distance from the caller. The social multiplies weights the average mean between alter who have had direct experience of giving birth to that hospital, or opinion based on indirect communication. The relative weights between direct experience or indirect communication are complementary.
After selection, the selector updates their ranking of that selected hospital derived from PNE official quantitative indicators provided by region Tuscany.
Once a woman has given birth, they influence the 1% of their municipality, communicating their experience of that hospital to other women who have not given birth in that hospital. Both women who have given birth elsewhere or women who still have to give birth can be influenced. The success of communication follows a Deffuant model, where the other agent holds a latitude of acceptance and a convergence rate. If the absolute distance between ranking of proposer and alter follows below the latitude of acceptance, the social influence mechanism occurs. This consists to add to the own ranking the difference between the ranking of the proposer and the own ranking, weighted by the confluence rate.
Note that when next agents become pregnant, the effect of opinion dynamic can influence the rank communicated from communication of experience for those who did not give birth in that hospital and those who did, based on the composition of networks used for the social multiplier. 


## HOW TO USE IT


* distance_threshold: the distance within which 50 random alter are selected to ask suggestion for the social multiplier in the selection of hospitals by the caller
* n_network: the size of network size for the social multiplier of caller
* weight_distance_hospital: the weight of distance in the selection of hospitals by the caller (negative weight)
* social_multiplier: weight of social influence in the selection of hospitals by the caller
* weight_experience [0,1]: within the weighted average used in the social multiplier, the weight given to those who have had experience of that hospital. The weight given to those who have received communication of the experience by others is computed as complementary (1 - weight_experience)
* uptrnk_sd: standard deviation for the distribution of ranking of selected hospital by the caller, centered in the PNE data on quantitative performance of hospital

* Deffuant opinion dynamic, for those who have given birth (**_birthtrue) or still not pregnant (**_notbirth):
** eps: latitude of acceptance
** mu: parameter of convergence


## THINGS TO NOTICE

* report_ranking: for each hospital, it reports the PNE value, the average mean by agents out of the simulation and standard deviation. If rank_by_procom is set to 0, it reports data on the entire population; otherwise: specify the pro_com of municipality
* Selection hospital: if plot_mobil activated, for hospital_id hospital, it reports the number of agents who have selected that hospital by distance and comparing with real selection from empirical data
* Mobility hospital origin: if plot_mobil activated, for hospital_id hospital, it reports the number of agents who selected that hospital by the origin of agents
 
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
  <experiment name="GENOVA" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="rescale15">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance_threshold">
      <value value="0"/>
      <value value="260"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n_network">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="weight_distance_hospital">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social_multiplier">
      <value value="0"/>
      <value value="1"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="weight_experience">
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="uptrnk_sd">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eps_birthtrue">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eps_notbirth">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mu_birthtrue">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mu_notbirth">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgrank">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plot_mobil">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show_networks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emp_net">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rank_by_procom">
      <value value="53011"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="destination_to">
      <value value="5585"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="origin_from">
      <value value="6194"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hospital_id">
      <value value="50"/>
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
