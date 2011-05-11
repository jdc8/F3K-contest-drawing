proc groups {p} {
    switch $p {
	5  { return [list {5}]}
	6  { return [list {6}]}
	7  { return [list {7}]}
	8  { return [list {8}]}
	9  { return [list {9}]}
	10 { return [list {10} {5 5}]}
	11 { return [list {11} {6 5}]}
	12 { return [list {12} {6 6}]}
	13 { return [list {6 7}]}
	14 { return [list {7 7}]}
	15 { return [list {8 7}]}
	16 { return [list {8 8}]}
	17 { return [list {9 8}]}
	18 { return [list {9 9} {6 6 6}]}
	19 { return [list {10 9} {7 6 6}]}
	20 { return [list {10 10} {7 7 6}]}
	21 { return [list {11 10} {7 7 7}]}
	22 { return [list {11 11} {8 7 7}]}
	23 { return [list {12 11} {8 8 7}]}
	24 { return [list {12 12} {8 8 8}]}
	25 { return [list {9 8 8}]}
	26 { return [list {9 9 8}]}
	27 { return [list {9 9 9}]}
	28 { return [list {10 9 9} {7 7 7 7}]}
	29 { return [list {10 10 9} {8 7 7 7}]}
	30 { return [list {10 10 10} {8 8 7 7}]}
	31 { return [list {11 10 10} {8 8 8 7}]}
	32 { return [list {11 11 10} {8 8 8 8}]}
	33 { return [list {11 11 11} {9 8 8 8}]}
	34 { return [list {12 11 11} {9 9 8 8}]}
	35 { return [list {12 12 11} {9 9 9 8} {7 7 7 7 7}]}
	36 { return [list {12 12 12} {9 9 9 9} {8 7 7 7 7}]}
	37 { return [list {10 9 9 9} {8 8 7 7 7}]}
	38 { return [list {10 10 9 9} {8 8 8 7 7}]}
	39 { return [list {10 10 10 9} {8 8 8 8 7}]}
	40 { return [list {10 10 10 10} {8 8 8 8 8}]}
	41 { return [list {11 10 10 10} {9 8 8 8 8}]}
	42 { return [list {11 11 10 10} {9 9 8 8 8}]}
	43 { return [list {11 11 11 10} {9 9 9 8 8}]}
	44 { return [list {11 11 11 11} {9 9 9 9 8}]}
	45 { return [list {12 11 11 11} {9 9 9 9 9}]}
	46 { return [list {12 12 11 11} {10 9 9 9 9}]}
	47 { return [list {12 12 12 11} {10 10 9 9 9}]}
	48 { return [list {12 12 12 12} {10 10 10 9 9}]}
	49 { return [list {10 10 10 10 9}]}
	50 { return [list {10 10 10 10 10}]}
    }
}

set mp 5  ;# Minimum number of pilots
set Mp 50 ;# Maximum number of pilots
set mr 5  ;# Minimum number of tasks
set Mr 20 ;# Maximum number of tasks
set generate_script 0
set incremental 1
set generate_html 0

foreach a $argv {
    switch -glob -- $a {
	h* -
	-h* {
	    set generate_html 1
	}
	s* -
	-s* {
	    set generate_script 1
	}
    }
}

set methods {
    -10000   10000random   "Best of 10000 random draws"                                     "Rnd4"
    -1000000 1000000random "Best of 1000000 random draws"                                   "Rnd6"
    1        1siman        "Minimized frequency of maximum number of duels"                 "Min"
    3        3siman        "Maximized frequency of 3 duels, minimized frequency of 0 duels" "Max3"
    4        4siman        "Maximized frequency of 4 duels, minimized frequency of 0 duels" "Max4"
}

proc add_contest {h fnm} {
    if {![file exists ../data/$fnm]} {
	puts $h "Contest data not available yet"
	return
    }
    puts $h "<a href='../data/${fnm}'>Data in textual format</a> &bull; <a href='#home'>Top of page</a>"
    puts $h "<br>"
    puts $h "<br>"
    set f [open ../data/$fnm r]
    set ll [split [read $f] \n]
    close $f
    set rl {}
    set ml {}
    set dfl {}
    foreach l $ll {
	switch -exact -- [lindex $l 0] {
	    pilots { set npilots [lindex $l 1] }
	    round { lappend rl [lindex $l 2] }
	    matrix { lappend ml $l }
	    duel_frequencies { set dfl [lrange $l 1 end] }
	}
    }
    puts $h "<table border='1'><caption>Groups per task</caption>"
    set ri 1
    foreach gl $rl {
	if {$ri == 1} {
	    puts $h "<tr><th></th>"
	    set gi 1
	    foreach g $gl {
		puts $h "<th>Group $gi</th>"
		incr gi
	    }
	    puts $h "</tr>"
	}
	puts $h "<tr><th>Task $ri</th>"
	foreach g $gl {
	    puts $h "<td>[join $g ,\ ]</td>"
	}
	puts $h "</tr>"
	incr ri
    }
    puts $h "</table>"
    set ndl {}
    foreach df $dfl {
	lassign [split $df :] nduels freq
	lappend ndl $nduels
    }
    puts $h "<br>"
    puts $h "<table border='1'><caption>Duel matrix</caption>"
    set mi 1
    puts -nonewline $h "<tr><th class='w2'></th>"
    for {set i 1} {$i <= $npilots} {incr i} {
	puts -nonewline $h "<th class='w2'>$i</th>"
    }
    puts $h "</tr>"
    set i 1
    set Md [lindex [lsort -integer $ndl] end]
    foreach m [lrange $ml 1 end] {
	puts -nonewline $h "<tr>"
	puts -nonewline $h "<th class='w2'>$i</th>"
	foreach j [lrange $m 2 end] {
	    if {$j == $Md} {
		puts -nonewline $h "<td class='w2max'>$j</td>"
	    } elseif {$j == 0} {
		puts -nonewline $h "<td class='w2min' bgcolor='#00FF00'>$j</td>"
	    } else {
		puts -nonewline $h "<td class='w2'>$j</td>"
	    }
	}
	puts $h "</tr>"
	incr i
    }
    puts $h "</table>"
}

proc wgroups {n} {
    if {$n == 1} {
	return group
    } else {
	return groups
    }
}

proc htmlheader {h} {
    puts $h "<html>"
    puts $h "<head>"
    puts $h "<style type='text/css'>"
    puts $h "td.w2 {width:20px; text-align: right;}"
    puts $h "td.w2max {width:20px; text-align: right; background-color: red;}"
    puts $h "td.w2min {width:20px; text-align: right; background-color: green;}"
    puts $h "td.w3 {width:30px; text-align: right;}"
    puts $h "td.ar {text-align: right;}"
    puts $h "</style>"
    puts $h "</head>"
    puts $h "<body>"
    puts $h "<h1><a id='home'>F3k Contests</a></h1>"
    puts $h "<a href='index.html'>Pilots/Rounds table</a>"
}

proc htmlfooter {h} {
    puts $h "</body></html>"
    close $h
}

proc cost { dmnm mti } {
    upvar $dmnm dm
    set m -1
    foreach {k v} [array get dm "$mti,*"] {
	lassign [split $k ,] t d
	if {$d > $m} {
	    set m $d
	}
    }
    if {$m < 0} {
	return 10e20
    } else {
	set c [expr {$m * 10e9}]
	switch -exact -- $mti {
	    3siman -
	    4siman {
		switch -exact -- $mti {
		    3siman { set max_duels 3 }
		    4siman { set max_duels 4 }
		}
		if {$m <= $max_duels} {
		    if {[info exists dm($mti,0)]} {
			set c [expr {$c + $dm($mti,0) * 10e6}]
		    }
		    for {set i 1} {$i <= $max_duels} {incr i} {
			if {[info exists dm($mti,$i)]} {
			    set c [expr {$c - $dm($mti,$i) * ($i == 2 ? 20000 : 1000)}]
			}
		    }
		}
	    }
	    default {
		set c [expr {$c + $dm($mti,$m) * 10e6}]
	    }
	}
    }
    return $c
}

proc collect_duel_frequencies { fnm methods dmnm } {
    upvar $dmnm dm
    unset -nocomplain dm
    foreach {marg mti mtl mtlabb} $methods {
	set tfnm ../data/${fnm}_$mti.txt
	if {![file exists $tfnm]} {
	    continue
	}
	set f [open $tfnm r]
	set ll [split [read $f] \n]
	close $f
	set dfl {}
	foreach l $ll {
	    switch -exact -- [lindex $l 0] {
		duel_frequencies { set dfl [lrange $l 1 end] }
	    }
	}
	foreach df $dfl {
	    lassign [split $df :] nduels freq
	    incr ddm($nduels)
	    incr dm($mti,$nduels) $freq
	}
    }
    return [lsort -integer [array names ddm]]
}

if {$generate_html} {

    set ntot 0
    set nfound 0

    set h [open ../html/index.html w]
    htmlheader $h
    puts $h "<table border='1'><caption>Optimization methods</caption>"
    foreach {marg mti mtl mtlabb} $methods {
	puts $h "<tr><td>$mtlabb</td><td>$mtl</td></tr>"
    }

    set nh 0
    puts $h "</table>"
    puts $h "<br><br>"
    puts $h "<table border='1'><caption>Pilots/rounds table</caption>"
    for {set p $mp} {$p <= $Mp} {incr p} {
	set first_group 1
	
	if {$nh % 5 == 0} {
	    if {$nh == 0} {
		puts $h "<tr><th colspan='2'></th><th colspan='[expr {$Mr-$mr+1}]'>Rounds</th></tr>"
	    }
	    puts -nonewline $h "<tr><th>Pilots</th><th>Groups</th>"
	    for {set r $mr} {$r <= $Mr} {incr r} {
		puts -nonewline $h "<th>$r</th>"
	    }
	    puts $h "</tr>"
	}

	incr nh

	foreach gl [groups $p] {

	    puts $h "<tr>"
	    if {$first_group} {
		puts $h "<td rowspan='[llength [groups $p]]'>$p</td>"
		set first_group 0
	    }
	    puts $h "<td>[llength $gl] ([join $gl ,\ ])</td>"
	    for {set r $mr} {$r <= $Mr} {incr r} {
		puts $h "<td>"
		set al {}
		set fnm "f3k_${p}p_${r}r_[join $gl _]"
		unset -nocomplain dm
		set cost [list]
		set ndl [collect_duel_frequencies $fnm $methods dm]
		foreach {marg mti mtl mtlabb} $methods {
		    set c [cost dm $mti]
		    lappend cost [list $mti $c]
		    set dcost($fnm,$mti) $c
		}
		set cost [lsort -increasing -index 1 -real $cost]
		foreach {marg mti mtl mtlabb} $methods {
		    incr ntot
		    set fnm "f3k_${p}p_${r}r_[join $gl _]_$mti.txt"
		    if {[file exists ../data/$fnm]} {
			incr nfound
			lappend al "<a href='p${p}g[join $gl -]r${r}.html#id$mti'>$mtlabb ([lsearch -index 0 $cost $mti])</a>"
		    } else {
			lappend al "$mtlabb"
		    }
		}
		puts $h [join $al "<br>"]
		puts $h "</td>"
	    }
	    puts $h "</tr>"
	}
    }
    puts $h "</table>"
    htmlfooter $h

    for {set p $mp} {$p <= $Mp} {incr p} {
	foreach gl [groups $p] {
	    for {set r $mr} {$r <= $Mr} {incr r} {
		set h [open ../html/p${p}g[join $gl -]r${r}.html w]
		htmlheader $h
		set fnm "f3k_${p}p_${r}r_[join $gl _]"
		puts $h "<h2>Method used to optimize a contest of $r tasks for $p pilots flying in [llength $gl] [wgroups [llength $gl]] ([join $gl ,\ ])</h2>"
		set ndl [collect_duel_frequencies $fnm $methods dm]
		puts $h "<table border='1'><caption>Duel frequencies overview</caption>"
		puts -nonewline $h "<tr><th></th>"
		foreach nd $ndl {
		    puts -nonewline $h "<th class='w3'>$nd</th>"
		}
		puts $h "<th>Cost</th></tr>"
		foreach {marg mti mtl mtlabb} $methods {
		    puts -nonewline $h "<tr><td><a href='#id$mti'>$mtl</a></td>"
		    foreach nd $ndl {
			if {[info exists dm($mti,$nd)]} {
			    puts -nonewline $h "<td class='w3'>$dm($mti,$nd)</td>"
			} else {
			    puts -nonewline $h "<td class='w3'>-</td>"
			}
		    }		
		    if {[info exists dcost($fnm,$mti)]} {
			puts $h "<td>$dcost($fnm,$mti)</td></tr>"
		    } else {
			puts $h "<td>-</td></tr>"
		    }
		}
		puts $h "</table>"
		foreach {marg mti mtl mtlabb} $methods {
		    puts $h "<h3><a id='id$mti'>$mtl</a></h3>"
		    add_contest $h ${fnm}_$mti.txt
		}
		htmlfooter $h
	    }    
	}
    }

    puts "Processed $nfound of $ntot ([format %5.1f [expr {$nfound * 100.0 / $ntot}]]%), HTML written to directory ../data"
}

if {$generate_script} {

    set ntot 0
    set nmiss 0

    set f [open all.sh w]
    puts $f "#/bin/sh"
    for {set p $mp} {$p <= $Mp} {incr p} {
	for {set r $mr} {$r <= $Mr} {incr r} {
	    foreach gl [groups $p] {
		if {$p != [expr [join $gl +]]} {
		    error "$p != [join $gl +]"
		}
		set fnm "../data/f3k_${p}p_${r}r_[join $gl _]"
		foreach {marg mti mtl mtlabb} $methods {
		    incr ntot
		    if {!$incremental || ![file exists "${fnm}_$mti.txt"]} {
			incr nmiss
			puts $f "./f3ksa $p $r $marg [join $gl]"
		    }
		}
	    }
	}
    }
    close $f

    puts "Missing $nmiss of $ntot ([format %5.1f [expr {$nmiss * 100.0 / $ntot}]]%), commands written to 'all.sh'"
}
