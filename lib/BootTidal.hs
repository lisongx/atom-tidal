:set prompt ""
:module Sound.Tidal.Context

(cps, getNow) <- bpsUtils

(d1,t1) <- dirtSetters getNow
(d2,t2) <- dirtSetters getNow
(d3,t3) <- dirtSetters getNow
(d4,t4) <- dirtSetters getNow
(d5,t5) <- dirtSetters getNow
(d6,t6) <- dirtSetters getNow
(d7,t7) <- dirtSetters getNow
(d8,t8) <- dirtSetters getNow
(d9,t9) <- dirtSetters getNow

(s1,ts1) <- superDirtSetters getNow
(s2,ts2) <- superDirtSetters getNow
(s3,ts3) <- superDirtSetters getNow
(s4,ts4) <- superDirtSetters getNow
(s5,ts5) <- superDirtSetters getNow
(s6,ts6) <- superDirtSetters getNow
(s7,ts7) <- superDirtSetters getNow
(s8,ts8) <- superDirtSetters getNow
(s9,ts9) <- superDirtSetters getNow


let bps x = cps (x/2)
let hush = mapM_ ($ silence) [d1,d2,d3,d4,d5,d6,d7,d8,d9,s1,s2,s3,s4,s5,s6,s7,s8,s9]
let solo = (>>) hush

:set prompt "tidal> "
