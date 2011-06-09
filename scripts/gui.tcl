package require Tk

set tpath "../f3ksa"

proc title {} {
    global text nrounds
    $text configure -state normal
    for {set n 0} {$n <= $nrounds} {incr n} {
	$text insert end "---- " title
    }
    $text insert end "------------- --------------------" title \n ""
    for {set n 0} {$n <= $nrounds} {incr n} {
	$text insert end [format {%4d } $n] title
    }
    $text insert end [format {%-13s %s} MAD Cost] title \n ""
    for {set n 0} {$n <= $nrounds} {incr n} {
	$text insert end "---- " title
    }
    $text insert end "------------- --------------------" title \n ""
    $text configure -state disabled
}

proc run {} {
    global tpath npilots ngroups nrounds cost optmeth fconf teams fdescr text gtext cntr cvs mcvs mparam rb sb
    $rb configure -state disabled
    $sb configure -state normal
    set cmd [list $tpath $npilots $nrounds]
    set cntr 0
    switch -exact -- $cost {
	wc {
	    lappend cmd f0
	}
	f {
	    switch -exact -- $optmeth {
		rnd { lappend cmd f$mparam }
		sa { lappend cmd f$mparam }
	    }
	}
	m {
	    switch -exact -- $optmeth {
		rnd { lappend cmd m$mparam }
		sa { lappend cmd m$mparam }
	    }
	}
    }
    set div [expr {$npilots / $ngroups}]
    set rem [expr {$npilots % $ngroups}]
    for {set g 0} {$g < $ngroups} {incr g} {
	if {$rem} {
	    incr ng
	    incr rem -1
	    lappend cmd [expr {$div+1}]
	} else {
	    lappend cmd $div
	}
    }
    $text configure -state normal
    $text delete 1.0 end
    $text insert end "Running command '$cmd'\n"
    $text configure -state disabled
    $gtext configure -state normal
    $gtext delete 1.0 end
    $gtext configure -state disabled
    $cvs delete bars
    $mcvs delete matrix
    set r 0
    set c 1
    for {set p 0} {$p < $npilots} {incr p} {
	$mcvs create rectangle [expr {5+$c*30}] [expr {5+$r*30}] [expr {5+$c*30+30}] [expr {5+$r*30+30}] -outline black -tags matrix
	$mcvs create text [expr {5+$c*30+15}] [expr {5+$r*30+15}] -text $p -tags matrix
	incr c
    }
    set r 1
    set c 0
    for {set p 0} {$p < $npilots} {incr p} {
	$mcvs create rectangle [expr {5+$c*30}] [expr {5+$r*30}] [expr {5+$c*30+30}] [expr {5+$r*30+30}] -outline black -tags matrix
	$mcvs create text [expr {5+$c*30+15}] [expr {5+$r*30+15}] -text $p -tags matrix
	incr r
    }
    set r 1
    set c 1
    for {set p 0} {$p < $npilots} {incr p} {
	set r 1
	for {set q 0} {$q < $npilots} {incr q} {
	    $mcvs create rectangle [expr {5+$c*30}] [expr {5+$r*30}] [expr {5+$c*30+30}] [expr {5+$r*30+30}] -outline black -tags matrix
	    if {$p == $q} {
		$mcvs create text [expr {5+$c*30+15}] [expr {5+$r*30+15}] -text - -tags matrix
	    } else {
	    }
	    incr r
	}
	incr c
    }
    $mcvs configure -scrollregion [$mcvs bbox matrix]
    
    title
    lappend cmd k 2>@1
    set fdescr [open |$cmd]
    fconfigure $fdescr -blocking 0 -buffering line
    fileevent $fdescr readable [list onoutput]
}

proc onoutput {} {
    global status text follow fdescr nrounds cntr cvs gtext mcvs npilots rb sb
    incr cntr
    if {[expr {$cntr & 0xf}] == 0} {
	title
    }
    set ll [read $fdescr]
    foreach l [split $ll \n] {
	if {[string length $l]} {
	    lassign $l ccost cmad dl rl
	    $text configure -state normal
	    unset -nocomplain dm
	    foreach {n f} $dl {
		set dm($n) $f
	    }
	    set bfl {}
	    for {set n 0} {$n <= $nrounds} {incr n} {
		if {[info exists dm($n)]} {
		    set f $dm($n)
		} else {
		    set f 0
		}
		lappend bfl [list $n $f]
		$text insert end [format {%4d } $f] ""
	    }
	    $text insert end [format {%13.8f %f} $cmad $ccost] ""
	    $text insert end \n ""
	    $text configure -state disabled
	    if {$follow} {
		$cvs delete bars
		set y 0
		set mf [lindex [lsort -integer -index 1 $bfl] end]
		foreach nf $bfl {
		    lassign $nf n f
		    $cvs create rectangle 5 $y [expr {5+$f}] [expr {$y+18}] -outline green -fill green -tags bars
		    $cvs create text [expr {$f+10}] $y -text "$n: $f" -tags bars -anchor nw
		    incr y 20
		}
		$cvs configure -scrollregion [$cvs bbox bars]
		$gtext configure -state normal
		$gtext delete 1.0 end
		$gtext insert end [join $rl \n]
		$gtext configure -state disabled
		unset -nocomplain dm
		set M 0
		foreach r $rl {
		    foreach g $r {
			for {set p 0} {$p < [llength $g]} {incr p} {
			    for {set q [expr {$p+1}]} {$q < [llength $g]} {incr q} {
				set pi [lindex $g $p]
				set qi [lindex $g $q]
				incr dm($pi,$qi)
				incr dm($qi,$pi)
				if {$dm($pi,$qi) > $M} {
				    set M $dm($pi,$qi)
				}
			    }
			}
		    }
		}
		$mcvs delete dfreq
		set r 1
		set c 1
		for {set p 0} {$p < $npilots} {incr p} {
		    set r 1
		    for {set q 0} {$q < $npilots} {incr q} {
			if {$p != $q} {
			    if {[info exists dm($p,$q)]} {
				if {$dm($p,$q) == $M} {
				    $mcvs create text [expr {5+$c*30+15}] [expr {5+$r*30+15}] -text $dm($p,$q) -tags {matrix dfreq} -fill red
				} else {
				    $mcvs create text [expr {5+$c*30+15}] [expr {5+$r*30+15}] -text $dm($p,$q) -tags {matrix dfreq}
				}
			    } else {
				$mcvs create text [expr {5+$c*30+15}] [expr {5+$r*30+15}] -text 0 -tags {matrix dfreq} -fill orange
			    }
			}
			incr r
		    }
		    incr c
		}
	    }
	}
    }
    if {$follow} {
	$text see end
    }
    if {[eof $fdescr]} {
	puts ""
        fconfigure $fdescr -blocking 1
        if [catch {close $fdescr}] {
            set s [lindex $::errorCode 0]
            if {$s eq "CHILDSTATUS"} {
                set status [lindex $::errorCode 2]
            } elseif {$s eq "CHILDKILLED"} {
                puts [lindex $::errorCode 3]\n
                set status -1
            }
        } else {
            set status 0
        }
	unset fdescr
	$text configure -state normal
	$text insert end "\nDone."
	$text configure -state disabled
	$sb configure -state disabled
	$rb configure -state normal
    }
}

proc stop {} {
    global fdescr rb sb
    if {[info exists fdescr]} {
	close $fdescr
    }
    $sb configure -state disabled
    $rb configure -state normal
}

set sf [ttk::frame .settings]
pack $sf -fill x

set npilots 20
set npl [ttk::label $sf.npl -text "Number of pilots:" -justify left]
set npe [ttk::entry $sf.npe -textvariable npilots -justify right]

set ngroups 2
set ngl [ttk::label $sf.ngl -text "Number of groups:" -justify left]
set nge [ttk::entry $sf.ngo -textvariable ngroups -justify right]

set nrounds 7
set nrl [ttk::label $sf.nrl -text "Number of rounds:" -justify left]
set nre [ttk::entry $sf.nro -textvariable nrounds -justify right]

set cost m
set cl [ttk::label $sf.ml -text "Cost:" -justify left]
set crb {}
foreach {p c} {wc "Worst case" f "Cost function" m "Mean absolute deviation"} {
    lappend crb [ttk::radiobutton $sf.crb$p -text $c -variable cost -value $p]
}

set optmeth sa
set oml [ttk::label $sf.oml -text "Optimization method:"]
set omrb {}
foreach {p m} {rnd "Random" sa "Simulated annealing"} {
    lappend omrb [ttk::radiobutton $sf.omrb$p -text $m -variable optmeth -value $p] 
}

set mparam 0
set mpl [ttk::label $sf.mpl -text "Method parameter:" -justify left]
set mpe [ttk::entry $sf.mpo -textvariable mparam -justify right]

set fconf {}
set fcl [ttk::label $sf.fcl -text "Frequency conflicts" -justify left]
set fce [ttk::entry $sf.fco -textvariable fconf]

set teams {}
set tl [ttk::label $sf.tl -text "Teams" -justify left]
set te [ttk::entry $sf.to -textvariable teams]

grid $npl $npe -sticky ewns
grid $ngl $nge -sticky ewns
grid $nrl $nre -sticky ewns
grid $cl {*}$crb -sticky ewns
grid $oml {*}$omrb -sticky ewns
grid $mpl $mpe -sticky ewns
grid $fcl $fce - - - -sticky ewns
grid $tl $te - - - -sticky ewns
for {set r 0} {$r < 5} {incr r} {
    grid columnconfigure $sf $r -weight 1
}

set bf [ttk::frame .buttons]
pack $bf -fill x

set rb [ttk::button $bf.rb -text "Run" -command run]
set sb [ttk::button $bf.sb -text "Stop" -command stop -state disabled]
set follow 1
set fcb [ttk::checkbutton $bf.fcb -text "Follow output" -variable follow]

grid $rb $sb $fcb -sticky ewns
for {set r 0} {$r < 2} {incr r} {
    grid columnconfigure $bf $r -weight 1
}

set nb [ttk::notebook .nb]
pack $nb -fill both -expand true

set of [ttk::frame $nb.output]
$nb add $of -text "Log"

set text [text $of.text -wrap none -xscrollcommand [list $of.sx set] -yscrollcommand [list $of.sy set] -state disabled]
set sx [ttk::scrollbar $of.sx -orient horizontal -command [list $of.text xview]]
set sy [ttk::scrollbar $of.sy -orient vertical -command [list $of.text yview]]

grid $text $sy -sticky ewns
grid $sx -sticky ewns
grid columnconfigure $of 0 -weight 1
grid rowconfigure $of 0 -weight 1

set gf [ttk::frame $nb.groups]
$nb add $gf -text "Groups"

set gtext [text $gf.text -wrap none -xscrollcommand [list $gf.sx set] -yscrollcommand [list $gf.sy set] -state disabled]
set sx [ttk::scrollbar $gf.sx -orient horizontal -command [list $gf.text xview]]
set sy [ttk::scrollbar $gf.sy -orient vertical -command [list $gf.text yview]]

grid $gtext $sy -sticky ewns
grid $sx -sticky ewns
grid columnconfigure $gf 0 -weight 1
grid rowconfigure $gf 0 -weight 1

set cvsf [ttk::frame $nb.cvsf]
$nb add $cvsf -text "Distribution"
set cvs [canvas $cvsf.cvs -bd 2 -xscrollcommand [list $cvsf.cvsx set] -yscrollcommand [list $cvsf.cvsy set]]
set cvsx [ttk::scrollbar $cvsf.cvsx -orient horizontal -command [list $cvsf.cvs xview]]
set cvsy [ttk::scrollbar $cvsf.cvsy -orient vertical -command [list $cvsf.cvs yview]]

grid $cvs $cvsy -sticky ewns
grid $cvsx -sticky ewns
grid columnconfigure $cvsf 0 -weight 1
grid rowconfigure $cvsf 0 -weight 1

set mcvsf [ttk::frame $nb.mf]
$nb add $mcvsf -text "Matrix"
set mcvs [canvas $mcvsf.mcvs -bd 2 -xscrollcommand [list $mcvsf.mcvsx set] -yscrollcommand [list $mcvsf.mcvsy set]]
set mcvsx [ttk::scrollbar $mcvsf.mcvsx -orient horizontal -command [list $mcvsf.mcvs xview]]
set mcvsy [ttk::scrollbar $mcvsf.mcvsy -orient vertical -command [list $mcvsf.mcvs yview]]

grid $mcvs $mcvsy -sticky ewns
grid $mcvsx -sticky ewns
grid columnconfigure $mcvsf 0 -weight 1
grid rowconfigure $mcvsf 0 -weight 1


