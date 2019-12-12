# tmapp2

Config:
https://docs.google.com/spreadsheets/d/1cDXIQRZK0_gT1BKH9TqVX7dWb68o0wwGaJaTCi7_7Wo/edit?usp=sharing

|  SECTION | KEY | EXAMPLE | OPTIONS | UNITS | RUNMODE | DEPENDENCY | COMMENTS |
| --- | --- | :--- | --- | --- | --- | --- | --- |
|   | [main] |  |  |  |  |  |  |
|  main | wd | /home/caduff/sim/tsub_basin8big/ |  |  | ALL |  |  |
|  main | srcdir | /home/caduff/src/tmapp2/ |  |  | ALL |  |  |
|  main | tscale_root | /home/caduff/src/ |  |  | ALL |  |  |
|  main | FSMPATH | /home/caduff/src/fsm/ |  |  | ALL |  |location of executable "FSM"  |
|  main | runmode | basins | "basins" "grid" "points" "points_sparse" |  | ALL |  |  |
|  main | startDate | 2013-09-01 |  |  | ALL |  |  |
|  main | endDate | 2014-09-01 |  |  | ALL |  |  |
|  main | tz | 0 |  |  | ALL |  | check and fix if necssary |
|  main | num_cores | 4 |  |  |  |  | required? fix in era download as max permissible jobs |
|  main | latN | 40 |  | degrees |  |  |  |
|  main | latS | 39 |  | degrees |  |  |  |
|  main | lonW | 69.5 |  | degrees |  |  |  |
|  main | lonE | 73.5 |  | degrees |  |  |  |
|  main | demRes | 3 | 1=30m / 3=90m |  |  |  |  |
|  main | demexists | FALSE |  |  |  |  |  |
|  main | demdir | /home/caduff/data/srtm/ |  |  |  |  |  |
|  main | chirpsP | FALSE |  |  |  |  |  |
|   | pointsBuffer | 0.08 |  | degrees |  |  | buffer around point for dem download in lon/lat |
|   | [forcing] |  |  |  |  |  |  |
|  forcing | dataset | era5 | era5' or '' |  |  |  |  |
|  forcing | product | reanalysis |  |  |  |  |  |
|  forcing | step | 6 |  | h |  |  |  |
|  forcing | plevels | 300, 500, 700,1000 |  | mb |  |  |  |
|  forcing | grid | /home/joel/src/tmapp2/grids/era5_0.25.tif |  |  |  |  |  |
|   |  |  |  |  |  |  |  |
|  toposcale | [toposcale] |  |  |  |  |  |  |
|  toposcale | tscaleOnly | TRUE |  |  |  |  |  |
|  toposcale | svfCompute | TRUE |  |  |  |  |  |
|  toposcale | svfSectors | 8 |  |  |  |  | sectors for svf algo |
|  toposcale | svfMaxDist | 3000 |  | m |  |  | max search dist for svf algo (m) |
|  toposcale | windCor | FALSE |  |  |  |  |  |
|  toposcale | mode | basins | "basins" "1d" "3d" |  |  |  |  |
|  toposcale | plapse | FALSE | TRUE FALSE |  |  |  | use Liston scaling (T/F) Ok in moderate topo eg Alps, often nonsense in extreme topo such as HMA |
|   |  |  |  |  |  |  |  |
|   | [toposub] |  |  |  |  |  |  |
|  toposub | nclust | 100 # number of toposub clusters ONLY if runmode | grid' |  |  |  |  |
|  toposub | inform | TRUE # do informed sampling? |  |  |  |  |  |
|  toposub | spatialDate | 31/03/2014 00:00 |  |  |  |  |  |
|   |  |  |  |  |  |  |  |
|   | [geotop] |  |  |  |  |  |  |
|  geotop | file1 | surface.txt |  |  |  |  |  |
|  geotop | targV | snow_water_equivalent.mm. |  |  |  |  |  |
|   |  |  |  |  |  |  |  |
|   | [meteoio] |  |  |  |  |  |  |
|  meteoio | timestep | 60 # output timestep of meteoio |  |  |  |  |  |
|   |  |  |  |  |  |  |  |
|   |  |  |  |  |  |  |  |
|   | [ensemble] |  |  |  |  |  |  |
|  ensemble | run | FALSE |  |  |  |  |  |
|  ensemble | members | 100 |  |  |  | if sampling == lhc then members=9 |  |
|  ensemble | sampling | lhc # lhc or random |  |  |  |  |  |
|   | [da] |  |  |  |  |  |  |
|  da | pscale | 1 |  |  |  |  |  |
|  da | tscale | 0 |  |  |  |  |  |
|  da | lwscale | 0 |  |  |  |  |  |
|  da | swscale | 0 |  |  |  |  |  |
|  da | PPARS | PTSL |  |  |  | if sampling == lhc then PPARS=P |  |
|  da | startDate | 2013-09-01 |  |  |  |  |  |
|  da | endDate | 2014-09-01 |  |  |  |  |  |
|  da | mapDOY | 212 # DOY from startDate to map DA results |  |  |  |  |  |
