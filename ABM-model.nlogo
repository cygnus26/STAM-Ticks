extensions [gis csv]

breed [residents resident]
breed [tourists tourist]

turtles-own [stay-duration activity risk-agent bite-stat]
patches-own [landuse agent-count risk-patch]

globals
[
  landuse-list
  landuse-dataset
  shape-dataset
  precipitation
  temperature
  output-file
  bite-count
]

to setup
  file-close-all
  clear-all
  setup-environment
  setup-agents
  reset-ticks
end

to setup-agents
 create-residents 100
  ask residents [move-to one-of patches with [landuse = 20] set color white set shape "person"]
 create-tourists 300
  ask tourists [move-to one-of patches with [landuse > 0] set color red set shape "person"]
  ask n-of (1 + random count turtles) turtles [set risk-agent random-float 1]
end


to setup-environment
  set landuse-dataset gis:load-dataset "Data_2022/Bilthoven/bilt_ascii.asc"
  gis:set-world-envelope (gis:envelope-of landuse-dataset)
  gis:apply-raster landuse-dataset landuse
  ask patches [
    if landuse = 60 [ ;forest
      set pcolor green set risk-patch 0.85]
    if landuse = 20 [
      set pcolor yellow set risk-patch 0.05] ;residential
    if landuse = 61 [
      set pcolor brown set risk-patch 0.4] ;dunes/sand
    if landuse = 62 [
       set pcolor grey set risk-patch 0.2] ;other
  ]

  set shape-dataset gis:load-dataset "Data_2022/Bilthoven/Bilt_shape.shp"
  gis:set-drawing-color white
  gis:draw shape-dataset 1

  set bite-count 0
end

to go
  ask turtles [set bite-stat False]

  patch-agent-count

  ;weather values
  file-open "Data_2022/Bilthoven/precip_bilt.csv"
  if file-at-end? [stop]
  let weather csv:from-row file-read-line

  set precipitation item 0 weather
  set temperature item 1 weather

  ;assign an activity

  if ticks mod 7 = 1 or ticks mod 7 = 2 or ticks mod 7 = 3 or ticks mod 7 = 4 or ticks mod 7 = 5[
    ask residents [set activity 1]]

  if ticks mod 7 = 6 or ticks mod 7 = 0 [
  ask residents [set activity one-of [2 3]]]
  ask tourists [set activity one-of [2 3]]

  
  move2
  tick-bite

  write-to-file

  if ticks = 300 [
    set output-file gis:patch-dataset agent-count
    gis:store-dataset output-file "output_ascii.asc"
  ]
  count-bites
  tick
end


to move2
 if precipitation < 50 [
    ask turtles with [activity = 2 or activity = 3][
      move-to one-of patches with [landuse = 60 or landuse = 61 or landuse = 62]
    ]
    ask turtles with [activity = 1][
      move-to one-of patches with [landuse = 20]
    ]
  ]
end

to write-to-file
  file-open "agents-location.txt"
  file-write ticks
  foreach sort turtles [x-turtle -> ask x-turtle [
    file-write (word self) file-write xcor file-write ycor file-write activity
    ]
  ]
  file-print " "
  file-close
end

to patch-agent-count
 ask patches [
 set agent-count (agent-count + count turtles-here)
 ]
end

to tick-bite
    ask turtles [if risk-agent < [risk-patch] of patch-here [
        set bite-stat True
    ]]
end

to count-bites
    set bite-count bite-count + count turtles with [bite-stat = True]
end