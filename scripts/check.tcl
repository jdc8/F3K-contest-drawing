# contest via simulated annealing
# set pilots 19
# set groups {7 6 6}
# set rounds 6
# set contest {
#     {{6 1 13 18 9 5 8} {17 7 2 3 12 11} {16 4 15 0 10 14}}
#     {{14 12 11 3 6 5 9} {8 10 0 4 17 13} {2 1 18 16 15 7}}
#     {{8 2 1 17 12 0 14} {7 9 10 5 13 16} {3 15 4 18 6 11}}
#     {{4 13 0 11 15 12 9} {2 3 16 10 8 6} {18 17 5 7 1 14}}
#     {{14 16 12 18 2 9 4} {10 13 1 11 17 6} {0 3 5 7 15 8}}
#     {{3 13 14 1 4 2 5} {16 11 15 9 8 17} {7 12 0 6 10 18}}
# }

# Diest 25/4/2011
set pilots 21
set groups {7 7 7}
set rounds 6
set contest {
    {{2 13 17 6 11 5 9}  {16 19 1 18 10 7 0} {12 14 4 3 8 15 20}}
    {{18 15 6 19 11 9 2} {14 1 10 8 3 5 20}   {7 12 16 17 4 13 0}}
    {{12 16 13 18 9 1 2} {4 3 8 14 17 7 20}   {5 10 15 19 11 6 0}}
    {{16 12 7 2 5 18 19} { 17 10 8 13 4 15 0} {9 3 14 11 1 6 20}}
    {{8 6 13 15 19 18 16} {1 12 17 9 4 3 20} {5 14 7 10 11 2 0}}
    {{18 3 5 13 12 8 19} {20 0 10 17 11 2 4} {14 15 9 1 16 6 7}}
}

# contest from f3kscore
#set pilots 19
#set groups {7 6 6}
#set rounds 6
# set contest {
#     {{0 3 5 9 12 13 15} {4 6 8 10 16 17} {1 2 7 11 14 18}}
#     {{17 18 2 3 8 12 16} {0 1 5 6 7 13} {10 11 14 15 4 9}}
#     {{12 14 0 3 6 8 10} {1 4 5 7 13 17} {11 15 16 18 2 9}}
#     {{14 15 7 8 9 11 12} {13 17 18 1 3 6} {0 2 4 5 10 16}}
#     {{16 1 2 3 4 7 12} {0 5 10 15 17 18} {9 11 13 14 6 8}}
#     {{4 7 9 10 18 0 3} {2 5 6 11 12 17} {16 1 8 13 14 15}}
# }

# contest via simulated annealing
# set pilots 21
# set groups {7 7 7}
# set rounds 6
# set contest {
#     {{1 16 0 13 11 20 19} {18 15 2 14 8 9 7} {12 10 17 5 6 4 3}}
#     {{15 13 0 3 14 8 6} {12 10 9 20 5 2 16} {18 4 19 7 11 17 1}}
#     {{5 8 19 11 2 9 3} {12 4 6 20 7 15 1} {0 17 13 18 14 10 16}}
#     {{14 1 5 17 8 16 7} {11 10 15 12 4 13 9} {18 2 20 19 6 0 3}}
#     {{12 17 7 3 0 8 18} {9 4 16 11 6 20 14} {15 13 5 2 19 10 1}}
#     {{14 13 7 6 9 12 19} {8 2 10 0 4 20 17} {18 11 16 3 1 5 15}}
# }

################################################################################

for {set i 0} {$i < $pilots} {incr i} {
    lappend pilotsl $i
}

proc check_full {full pilots groups rounds} {
    if {[llength $full] != $rounds} {
	error "Expected $rounds rounds, only found [llength $full]."
    }
    for {set i 0} {$i < ([llength $pilots] -1)} {incr i} {
	for {set j [expr {$i+1}]} {$j < [llength $pilots]} {incr j} {
	    set duel([lsort [list $i $j]]) 0
	}
    }
    foreach round $full {
	unset -nocomplain pmap
	foreach group $round tgroup $groups {
	    if {[llength $group] != $tgroup} {
		error "Expected group length of $tgroup, only got [llength $group]."
	    }
	    foreach p $group {
		if {[lsearch $pilots $p] < 0} {
		    error "Unknown pilot '$p'"
		}
		if {[info exists pmap($p)]} {
		    error "Duplicate pilot in round: $round"
		}
		incr pmap($p)
	    }
	    for {set i 0} {$i < ([llength $group] -1)} {incr i} {
		for {set j [expr {$i+1}]} {$j < [llength $group]} {incr j} {
		    incr duel([lsort [list [lindex $group $i] [lindex $group $j]]])
		}
	    }
	}
	if {[llength [array names pmap]] != [llength $pilots]} {
	    error "Insufficient pilots in round: $round"
	}
    }
    #parray duel
    foreach {k v} [array get duel] {
	incr ov($v)
    }
    puts -nonewline "  "
    for {set i 0} {$i < [llength $pilots]} {incr i} {
	puts -nonewline [format { %2d} $i]
    }
    puts ""
    for {set i 0} {$i < [llength $pilots]} {incr i} {
	puts -nonewline [format {%2d} $i]
	for {set j 0} {$j < [llength $pilots]} {incr j} {
	    set k [lsort [list $i $j]]
	    if {[info exists duel($k)]} {
		puts -nonewline [format { %2d} $duel($k)]
	    } else {
		puts -nonewline "  -"
	    }
	}
	puts ""
    }
    puts "check full duel frequencies:"
    parray ov
}

check_full $contest $pilotsl $groups $rounds
