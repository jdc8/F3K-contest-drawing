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

set generate_script 0
set incremental 0
set generate_html 0
set generate_duel_matrix 0
set generate_xml 0
set parallel 1

foreach a $argv {
    switch -glob -- $a {
	h* -
	-h* {
	    set generate_html 1
	}
	i* -
	-i* {
	    set incremental 1
	}
	m* -
	-m* {
	    set generate_duel_matrix 1
	}
	s* -
	-s* {
	    set generate_script 1
	}
	x* -
	-x* {
	    set generate_xml 1
	}
        4 {
	    set parallel 4
	}
    }
}

set mp 5  ;# Minimum number of pilots
set Mp 50 ;# Maximum number of pilots
set mr 5  ;# Minimum number of tasks
set Mr 20 ;# Maximum number of tasks
set methods {
    0        worstcase     "Worst case"                                                                                  "Wrst"
    -1       1random       "1 random draw"                                                                               "Rnd0"
    -10      10random      "Best of 10 random draws"                                                                     "Rnd1"
    -10000   10000random   "Best of 10000 random draws"                                                                  "Rnd4"
    -1000000 1000000random "Best of 1000000 random draws"                                                                "Rnd6"
    1        1siman        "Minimized frequency of maximum number of duels using simulated annealing"                    "Min"
    3        3siman        "Maximized frequency of 3 duels and minimized frequency of 0 duels using simulated annealing" "Max3"
    4        4siman        "Maximized frequency of 4 duels and minimized frequency of 0 duels using simulated annealing" "Max4"
    5        5siman        "Maximized frequency of 5 duels and minimized frequency of 0 duels using simulated annealing" "Max5"
}

proc add_contest {h fnm} {
    if {![file exists ../data/$fnm]} {
	puts $h "Contest data not available yet"
	return
    }
    puts $h "<p><a href='index.html'>Pilots/Rounds table</a> &bull; <a href='#home'>Top of page</a><br/><br/></p>"
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
	    puts -nonewline $h "<tr><th></th>"
	    set gi 1
	    foreach g $gl {
		puts -nonewline $h "<th>Group $gi</th>"
		incr gi
	    }
	    puts -nonewline $h "</tr>"
	}
	puts -nonewline $h "<tr><th>Task $ri</th>"
	foreach g $gl {
	    puts -nonewline $h "<td>[join [lsort -integer $g] ,\ ]</td>"
	}
	puts -nonewline $h "</tr>"
	incr ri
    }
    puts $h "</table>"
    set ndl {}
    foreach df $dfl {
	lassign [split $df :] nduels freq
	lappend ndl $nduels
    }
    if {$::generate_duel_matrix} {
	puts $h "<p><br/></p>"
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
		    puts -nonewline $h "<td class='w2min'>$j</td>"
		} else {
		    puts -nonewline $h "<td class='w2'>$j</td>"
		}
	    }
	    puts $h "</tr>"
	    incr i
	}
	puts $h "</table>"
    }
}

proc wgroups {n} {
    if {$n == 1} {
	return group
    } else {
	return groups
    }
}

proc htmlheader {h pilots} {
    puts $h "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">"
    puts $h "<html xmlns=\"http://www.w3.org/1999/xhtml\">"
    puts $h "<head>"
    puts $h "<meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />"
    puts $h "<title>F3K Contests</title>"
    puts $h "<style type='text/css'>"
    puts $h "td.w2 {width:20px; text-align: right;}"
    puts $h "td.w2max {width:20px; text-align: right; background-color: red;}"
    puts $h "td.w2min {width:20px; text-align: right; background-color: green;}"
    puts $h "td.w3 {width:30px; text-align: right;}"
    puts $h "td.ar {text-align: right;}"
    puts $h "</style>"
    puts $h "</head>"
    puts $h "<body>"
    if {$pilots > 0} {
	puts $h "<h1><a id='home'>F3k Contests for $pilots pilots</a></h1>"
    } else {
	puts $h "<h1><a id='home'>F3k Contests</a></h1>"
	puts $h "<p>Last update: [clock format [clock seconds]]</p>"
    }
    if {$pilots == 0} {
	puts $h "<p>"
	puts $h "This page tries to list a number of ways to arrange the groups in a F3K contest. Different methods are used to find a solution to this problem. The aim was to minimize the number of times 2 pilots fly in the same group during a contest. No other constraints have been taken into account (e.g. frequency clashes, teams, flying rounds back-to-back, ...)."
	puts $h "</p>"
	puts $h "<p>"
	puts $h "Starting from the group data as listed here, you can generate a random contests by applying a random mapping from your pilots list to the numbers used in the group data and by randomizing the group order for a given round. This makes it possible to store the group data found here in a F3K contest application without having to repeat the calculations."
	puts $h "</p>"
	puts $h "<p>"
	puts $h "An XML file with the results is available as a <a href='f3k.xml.zip'>zippped file</a>. The XML only contains the simulated annealing results as they are always better than the random results."
	puts $h "</p>"
	puts $h "<p>"
	puts $h "For questions and feedback about the data and the method used to obtain this data, you can contact me at <a href=\"mailto:jos.decoster@gmail.com\">jos.decoster@gmail.com</a>."
	puts $h "</p>"
	puts $h "<p>"
	puts $h "The data is provided with a BSD style <a href='#license'>license</a>."
	puts $h "</p>"
    } else {
	puts $h "<p><a href='index.html'>Pilots/Rounds table</a></p>"
    }
}

set license {##
## This data is copyrighted by Jos Decoster (jos.decoster@gmail.com).
## The  following terms apply to all files associated with the 
## data unless explicitly disclaimed in individual files.
##
## The authors hereby grant permission to use, copy, modify, distribute, and
## license this data and its documentation for any purpose, provided that
## existing copyright notices are retained in all copies and that this notice
## is included verbatim in any distributions.  No written agreement, license,
## or royalty fee is required for any of the authorized uses.
##
## IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY FOR
## DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
## OF THE USE OF THIS DATA, ITS DOCUMENTATION, OR ANY DERIVATIVES THEREOF,
## EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##
## THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
## INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS DATA IS
## PROVIDED ON AN *AS IS* BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE NO
## OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
## MODIFICATIONS.
##}

proc htmlfooter {h pilots} {
    if {$pilots == 0} {
	puts $h "<h2 id='license'>License</h2>"
	puts $h "<pre>$::license</pre>"
    }
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
    htmlheader $h 0
    puts $h "<table border='1'><caption>Optimization methods</caption>"
    foreach {marg mti mtl mtlabb} $methods {
	puts $h "<tr><td>$mtlabb</td><td>$mtl</td></tr>"
    }

    set nh 0
    puts $h "</table>"
    puts $h "<p><br/><br/></p>"
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
		puts $h "<td rowspan='[llength [groups $p]]'><a href='$p.html'>$p</a></td>"
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
		    set scost($fnm,$mti) $c
		}
		set cost [lsort -increasing -index 1 -real $cost]
		foreach {marg mti mtl mtlabb} $methods {
		    incr ntot
		    set fnm "f3k_${p}p_${r}r_[join $gl _]_$mti.txt"
		    if {[file exists ../data/$fnm]} {
			incr nfound
			lappend al "<a href='p${p}.html#g[join $gl -]r${r}'>$mtlabb ([lsearch -index 0 $cost $mti])</a>"
		    } else {
			lappend al "$mtlabb"
		    }
		}
		puts $h [join $al "<br/>"]
		puts $h "</td>"
	    }
	    puts $h "</tr>"
	}
    }
    puts $h "</table>"
    htmlfooter $h 0

    for {set p $mp} {$p <= $Mp} {incr p} {
	set h [open ../html/p${p}.html w]
	htmlheader $h $p
	puts $h "<p><br/><br/></p><table border='1'><caption>Number of rounds for group structure</caption>"
	puts -nonewline $h "<tr>"
	foreach gl [groups $p] {
	    puts -nonewline $h "<th>[llength $gl] [wgroups [llength $gl]] ([join $gl ,\ ])</th>"
	}
	puts $h "</tr>"
	for {set r $mr} {$r <= $Mr} {incr r} {
	    puts -nonewline $h "<tr>"
	    foreach gl [groups $p] {
		puts -nonewline $h "<td><a href ='#g[join $gl -]r${r}'>$r rounds</a></td>"
	    }
	    puts $h "</tr>"
	}
	puts $h "</table>"
	foreach gl [groups $p] {
	    for {set r $mr} {$r <= $Mr} {incr r} {
		set fnm "f3k_${p}p_${r}r_[join $gl _]"
		puts $h "<h2><a id='g[join $gl -]r${r}'>Contest of $r tasks for $p pilots flying in [llength $gl] [wgroups [llength $gl]] ([join $gl ,\ ])</a></h2>"
		set ndl [collect_duel_frequencies $fnm $methods dm]
		puts $h "<table border='1'><caption>Duel frequencies overview</caption>"
		puts -nonewline $h "<tr><th></th>"
		foreach nd $ndl {
		    puts -nonewline $h "<th class='w3'>$nd</th>"
		}
		puts $h "<th>Cost</th></tr>"
		foreach {marg mti mtl mtlabb} $methods {
		    puts -nonewline $h "<tr><td><a href='#idg[join $gl -]r${r}$mti'>$mtl</a></td>"
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
		    puts $h "<h3><a id='idg[join $gl -]r${r}$mti'>$mtl</a></h3>"
		    add_contest $h ${fnm}_$mti.txt
		}
	    }    
	}
	htmlfooter $h $p
    }

    puts "Processed $nfound of $ntot ([format %5.1f [expr {$nfound * 100.0 / $ntot}]]%), HTML written to directory ../html"

    foreach {k v} [array get scost] {
	lassign [split $k ,] fnm mti
	lappend lcost($fnm) [list $mti $v]
    }
    puts "size scost: [llength [array names scost]]"
    puts "size lcost: [llength [array names lcost]]"
    foreach {k v} [array get lcost] {
	set lcost($k) [lsort -real -increasing -index 1 $v]
	incr mcost([lindex $lcost($k) 0 0])
    }
    set cl {}
    foreach {k v} [array get mcost] {
	lappend cl [list $k $v]
    }
    set cl [lsort -index 1 -integer -decreasing $cl]
    foreach c $cl {
	lassign $c m n
	puts [format "%12s %5d %6.2f%%" $m $n [expr {double($n)/[llength [array names lcost]]*100}]]
    }
}

if {$generate_xml} {

    set ntot 0
    set nfound 0

    set x [open ../html/f3k.xml w]
    puts $x "<?xml version=\"1.0\"?>"
    puts $x "<!--"
    puts $x $::license
    puts $x "-->"
    puts $x "<f3k version=\"1.0\">"
    for {set p $mp} {$p <= $Mp} {incr p} {
	for {set r $mr} {$r <= $Mr} {incr r} {
	    foreach gl [groups $p] {
		puts $x " <contest pilots=\"$p\" rounds=\"$r\" groups=\"[llength $gl]\">"
		foreach {marg mti mtl mtlabb} $methods {
		    # No random result in the XML to keep the file size lower and the simulated annealing results are always better.
		    if {$marg <= 0} continue
		    incr ntot
		    set fnm "f3k_${p}p_${r}r_[join $gl _]_${mti}.txt"
		    puts $x "  <draw method=\"$mti\" filenam=\"$fnm\">"
		    if {[file exists ../data/$fnm]} {
			incr nfound
			set f [open ../data/$fnm r]
			set ll [split [read $f] \n]
			close $f
			foreach l $ll {
			    switch -exact -- [lindex $l 0] {
				round { 
				    puts -nonewline $x "   <round id=\"[lindex $l 1]\">"
				    set rgid 0
				    foreach rg [lindex $l 2] {
					puts -nonewline $x "    <group id=\"$rgid\">"
					foreach rgp $rg {
					    puts -nonewline $x "<p>$rgp</p>"
					}
					puts $x "</group>"
					incr rgid
				    }
				    puts $x "   </round>"
				}
			    }
			}
		    }
		    puts $x "  </draw>"
		}
		puts $x " </contest>"
	    }
	}
    }
    puts $x "</f3k>"
    close $x

    puts "Processed $nfound of $ntot ([format %5.1f [expr {$nfound * 100.0 / $ntot}]]%), XML written to directory ../html"
}

if {$generate_script} {

    set ntot 0
    set nmiss 0

    set fl {}
    for {set i 0} {$i < $parallel} {incr i} {
	set f [open all$i.sh w]
	puts $f "#/bin/sh"
	lappend fl $f
    }
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
			puts [lindex $fl [expr {$nmiss%$parallel}]] "./f3ksa $p $r $marg [join $gl]"
		    }
		}
	    }
	}
    }
    close $f

    puts "Missing $nmiss of $ntot ([format %5.1f [expr {$nmiss * 100.0 / $ntot}]]%), commands written to 'all.sh'"
}
