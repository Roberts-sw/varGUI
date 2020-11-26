#!/bin/sh 
# \
exec wish "$0" "$@"

# http://www.tcl.tk/man/tcl8.6/
package require Tcl 8.5		;# lassign
package require Tk 8.5		;# ttk::
package require registry	;# 
# wm withdraw .

# CONFIGURATION ===============================================================
proc data_rd {data} {	global cfg
	foreach line [split $data \n] {
		if {"" eq $line} {continue}
		if {"#" eq [string index $line 0]} {continue}
		if {![string is list $line]} {continue}
		foreach {n v} $line {break};#	puts "line:$line\n   n:$n\n   v:$v"
		if {[string is upper [string index $n 0] ]} {set cfg($n) $v} else {	
			set ::app($n) $v
		}
	}
}
proc data_wr {_arr} {	upvar $_arr arr
	if {[info vars arr] eq ""} {return ""}
	foreach n [lsort -dict [array names arr]] {
		append res "$n\t[list $arr($n)]\n"
	}
	return $res
}
proc filedo args {	;# withOpenFile ...
	if {[llength $args]<3} {
		error {wrong # args: should be "filedo fh fname ?access? ?permissions? script"}
	}
	upvar 1 [lindex $args 0] fh
	try {		open {*}[lrange $args 1 end-1]
	} on ok fh {uplevel 1 [lindex $args end]
	} finally {	catch {chan close $fh}
	}
	# filedo fh $fname a {chan puts $fh $mytext}
	# set res [filedo fh $fname a {chan read $f}]	
}

proc fappend {fname fdata} {
	if {![catch {open $fname a} fh]} {puts $fh $fdata; close $fh}
}
proc fread {fname {ext cfg}} {
	if {[string first . $fname] < 0} {append fname .$ext}
	set res [filedo fh $fname r {read $fh}]
}
proc fwrite {fname fdata} {
	if {[string first . $fname] < 0} {append fname .cfg}
	filedo fh $fname w {puts $fh $fdata}	
}
array set app {
	name	varGUI
	version	0.1
	filetypes {{{config files} {.cfg}} {{log files} {.log .txt}} {{all files} *}}
	cols	{1 2 3 4 5 6 7 8 9 10 11 12}
	rows	{"" Shift- Ctrl- Alt-}
};	data_rd [fread $app(name) ini]
 
# set platform $tcl_platform(platform)	;# http://wiki.tcl.tk/1649
if {"windows" eq $tcl_platform(platform)} {
	bind . <Escape> {eval [list exec wish $argv0] $argv &; exit}
	foreach c {1 4} t {console exit} {			;# ? Alt-F4 ends program
		if {![info exists cfg(F$c,4)]} {set cfg(F$c,4) $t}	
	};	bind . <Alt-F1> {console show}			;# ... Alt-F1 for Tcl console
};# https://wiki.tcl-lang.org/page/console+platform+portability


# GUI ============================================= see http://wiki.tcl.tk/2264
ttk::style theme use xpnative;# clam;# alt;# default;# classic;# winnative;# 
wm title . $app(name);# window scaling in X and Y -----------------------------
grid columnconfigure . 0 -weight 1; grid rowconfigure . 0 -weight 1

# Fn-key table, scaling in width ----------------------------------------------
grid [ttk::frame .f -padding "1 1"] -row 0 -column 0 -sticky news
set r 0;grid columnconfigure .f 0 -minsize 30	;# header column 0
for {set c 1} {$c<=12} {incr c} {				;# header column 1-12
	grid [ttk::label .f.l0,$c -width -1 -text F$c] -column $c -row 0
	grid columnconfigure .f $c -minsize 30 -weight 1 -uniform cb
}
foreach hd $app(rows) {	incr r
	grid [ttk::label .f.l$r,0 -width -2 -text $hd] -row $r -column 0 -sticky e
	for {set c 1} {$c<=12} {incr c} {
		if {![info exists cfg(F$c,$r)]} {set cfg(F$c,$r) "-- F$c --"}
		if {![info exists cfg(F$c,$r,m)]} {set cfg(F$c,$r,m) ""}
		grid [ttk::button .f.b$c,$r -textvar cfg(F$c,$r)] -sticky ew -column $c\
				 -row $r
	}
};	if {4 eq $r && "windows" eq  $tcl_platform(platform)} {
	foreach c {1 4} {.f.b$c,$r configure -textvar cfg(F$c,$r) -state disabled}
} 
# entry and button to couple tekst to Fn-key ----------------------------------
incr r; 
grid [ttk::entry .f.e] -sticky ew -column 1 -columnspan 12 -row $r -padx 1
.f.e insert end "var 16.0.4 303 102 103 105 212\\n"
# grid [ttk::button .f.b$r,12 -text assign] -sticky ew -column 12 -row $r
focus .f.e
bind . <Return> {xmit [.f.e get]}	;# no send key needed, <Return> is oke

# message history with slider, scaling in X and Y -----------------------------
incr r; grid rowconfigure .f $r -weight 1
grid [ttk::labelframe .f.lf -text { berichten  }] -sticky news \
		-row $r -column 1 -columnspan 12
pack [ttk::scrollbar .f.lf.sy -command [list .f.lf.t yview] ] \
	-in .f.lf -side right -fill y
text .f.lf.t -height 7 -yscrollcommand [list .f.lf.sy set] -state disabled
	.f.lf.t tag configure txtin -foreground black
	.f.lf.t tag configure txtout -foreground blue
pack .f.lf.t  -in .f.lf -fill both -expand 1

proc GUI_element {name el} {wm title [winfo toplevel $el] "$name > $el"}
bind all <Enter> {GUI_element $app(name) %W}

menu .mnu;# menus -------------------------------------------------------------
. config -menu .mnu;# 2 levels, default action command in submenu
proc msg_box {arg {head ""} {foot "to be implemented"} } {
	if {"" eq $head} {set msg ""} {set msg $head\ }; append msg \"$arg\"
	if {"" ne $foot} {append msg \n$foot};	tk_messageBox -message $msg
}
foreach menu {
	{file 0 {new 0 open 0 save 0 save_as 1 ... - exit 1}}
	{edit 0 {fn_keys 0}} 
	{config 0 {serial 0 logging 0}}
	{help 0 {about 0}}
	} {
	lassign $menu m u submenu
	.mnu add cascade -label [string totitle $m] -underline $u \
			-menu [menu .mnu.$m -tearoff 0]
	foreach {s u} $submenu {
		if {"-" eq $u} {.mnu.$m add separator} {
			# default menu handler alerts: "$cmd to be implemented"
			set cmd [join [list $m $s] _];proc $cmd {} "msg_box $cmd"  
			.mnu.$m add command -label [string totitle [split $s _] ] \
					-underline $u -command $cmd
		};# command example: edit_fn_keys 
	}
}
if 0 {	;# undocumented 
	proc ::tk::UnderlineAmpersand {text} {
	    set s [string map {&& & & \ufeff} $text]
	    set idx [string first \ufeff $s]
	    return [list [string map {\ufeff {}} $s] $idx]
	}
}

# LOG =========================================================================
proc log_time {} {	set t [clock milliseconds]
	set f [expr {($t%1000+50)/10%100}];	set t [expr {$t/1000}]
	set r [clock format $t -format %T],[format %02d $f];	# ex. 08:03:14,09
}
proc log_record {data {is_tx 0} } {
	return [log_time][expr {$is_tx ? " > " : " < "}]$data
}
proc log_write {record} {
}


# SERIAL ======================================================================
# https://wiki.tcl-lang.org/page/Serial+Port
# links to:
# 	https://wiki.tcl-lang.org/page/A+simple+serial+terminal
# 	https://wiki.tcl-lang.org/page/SerWatch+%2D+serial+port+protocol+analyzer+library
# 	https://wiki.tcl-lang.org/page/SerPortChat
proc Hwserial {} {;# https://wiki.tcl-lang.org/page/serial+ports+on+Windows
	set res ""
	if {"windows" eq $::tcl_platform(platform)} {
		set R HKEY_LOCAL_MACHINE\\HARDWARE\\DEVICEMAP\\SERIALCOMM
		catch {	foreach v [registry values $R] {
			lappend res [registry get $R $v]}
		}
	} elseif {"linux" eq [lindex [split [::platform::generic] -] 0]} {
		set res [glob -nocomplain {/dev/ttyS[0-9]} {/dev/ttyUSB[0-9]} {/dev/ttyACM[0-9]}]
	} else {;# bsd variants
		set res [glob -nocomplain {/dev/tty0[0-9]} {/dev/ttyU[0-9]}]
	};	lsort $res
}


# PROC ========================================================================

# menu functions file_* -------------------------------------------------------
proc _file_dir_name ext {
	if {[array names ::app cfg] eq ""} {
		list [file join [file dirname [info script]] cfg] default.$ext
	} { list [file dirname $::app(cfg)] [file tail $::app(cfg)]
	}
}
proc file_exit {} {exit}
proc file_new {} {global cfg
	set fname [tk_getSaveFile -parent . -filetypes $::app(filetypes)]
	if {"" eq $fname} {return}
	set ::app(cfg) $fname;	fwrite $fname [data_wr cfg]
}
proc file_open {} {global cfg; lassign [_file_dir_name cfg] fdir fname
	set fname [tk_getOpenFile -parent . -filetypes $::app(filetypes) \
			-initialdir $fdir -initialfile $fname]
	if {"" eq $fname} {return}
	data_rd [set ::app(cfg) $fname; fread $fname]
	foreach n "[lsort -dict [array names cfg] ]" {
		if {"F" eq [string index $n 0]
		&&	"m" ne [string index $n end]} {
			set key [string range $n 1 end]
			.f.b$key configure -textvar cfg($n)
		};# else {puts "name $n"}
	}
}
proc file_save {} {global cfg; lassign [_file_dir_name cfg] fdir fname
	set fname [tk_getSaveFile -parent . -filetypes $::app(filetypes) \
			-initialdir $fdir -initialfile $fname]
	if {"" eq $fname} {return}
	set ::app(cfg) $fname;	fwrite $fname [data_wr cfg]
}
proc file_save_as {} {global cfg; lassign [_file_dir_name cfg] fdir fname
		set fname [tk_getSaveFile -parent . -filetypes $::app(filetypes) \
				-initialdir $fdir -initialfile $fname]
	if {"" eq $fname} {return}
	set ::app(cfg) $fname;	fwrite $fname [data_wr cfg]
}

# menu functions edit_* -------------------------------------------------------
proc _edit_fn_populate {_row} {	global cfg; upvar $_row r;	set w .keys.f;
	if {$r && $r <= [llength $::app(rows)]} {		;# previous r: 0 | 1..4
		foreach k $::app(cols) {
			set cfg(F$k,$r) [$w.e$k get];	set cfg(F$k,$r,m) [$w.e$k,m get]
		}
	};	if {[llength $::app(rows)]<[incr r]} {set r 1}	;# 1..4
	foreach k $::app(cols) {
		$w.e$k delete 0 end;	$w.e$k insert end $cfg(F$k,$r)
		$w.e$k,m delete 0 end;	$w.e$k,m insert end $cfg(F$k,$r,m)
	};	incr k;	$w.sel$k configure -text [lindex $::app(rows) $r-1]
	focus $w.sel$k
}
proc _edit_fn_ok {_row} {	upvar $_row r
	_edit_fn_populate r;	after 25 [destroy .keys]
}
proc edit_fn_keys {} {	global cfg r
	if {[winfo exists .keys]} {
		wm attributes .keys -topmost 1;	focus .keys.f.sel13; return
	}
	toplevel .keys;	set w .keys; wm title $w "Function keys"
	grid columnconfigure $w 0 -weight 1; grid rowconfigure $w 0 -weight 1
	grid [ttk::frame $w.f -padding "5 1"] -row 0 -column 0 -sticky news
	set w .keys.f
	foreach c {1 2} t {label message} {
		grid columnconfigure $w $c -weight 1
		grid [ttk::label $w.l$c,0 -width -5 -text $t] -row 0 -column $c
	}
	foreach k $::app(cols) {
		grid [ttk::label $w.l$k -width -1 -text F$k] -column 0 -row $k
		grid [ttk::entry $w.e$k -width 12] -column 1 -row $k -padx 5 -pady 3
		grid [ttk::entry $w.e$k,m -width 48] -column 2 -row $k -padx 5
	};	incr k;	set r 0
	ttk::button $w.sel$k -width -7 -command "_edit_fn_populate r"
	ttk::button $w.ok$k  -width -7 -command "_edit_fn_ok r" -text "Ok"
	grid $w.sel$k -column 1 -row $k -pady 5
	grid $w.ok$k  -column 2 -row $k -pady 5
	_edit_fn_populate r
}

# menu functions config_* -----------------------------------------------------
proc _cfg_ser_ok {} {	global cfg
	if {![winfo exists .term.f]} {return}
	foreach n {port baud parity data stop} {set $n [.term.f.$n get]}
	set cfg(Ser_set) $baud,[string index $parity 0],$data,$stop
	set cfg(Ser_port) $port
	destroy .term
}
proc config_serial {} {		global cfg
	if {[winfo exists .term]} {
		wm attributes .term -topmost 1;	return
	}
	toplevel .term; set w .term; wm title $w "Serial port"
	grid columnconfigure $w 0 -weight 1; grid rowconfigure $w 0 -weight 1
	grid [ttk::frame $w.f -padding "5 3" -width 40 -height 30] -row 0 -column 0
	set w .term.f; set r 0

	foreach {lb st listv} {
	port      readonly {NONE}
	baud_rate normal   {4800 9600 19200 38400 57600 115200}
	parity    readonly {none even odd}
	data_bits readonly {8} 
	stop_bits readonly {1 2}
	} {	incr r;	set lb [split $lb _] 
		ttk::label $w.lb$r -text [string totitle $lb]:
		set cbb [lindex $lb 0] 
		ttk::combobox $w.$cbb -state $st -values $listv
		grid $w.lb$r -row $r -column 0 -padx 5 -sticky nws
		grid $w.$cbb -row $r -column 1 -pady 3 -sticky nes -columnspan 2
	};	incr r
	ttk::button $w.can -width -7 -command "destroy .term" -text "Cancel"
	ttk::button $w.ok  -width -7 -command _cfg_ser_ok -text "Ok"
	grid $w.can -column 1 -row $r -pady 5
	grid $w.ok  -column 2 -row $r -pady 5

	if {![info exists cfg(Ser_port)]} {set cfg(Ser_port) NONE}
	set ports [join [list $cfg(Ser_port) [Hwserial] ] ]
	$w.port configure -values [lsort -unique $ports]	
	$w.port set $cfg(Ser_port) 

	if {![info exists cfg(Ser_set)]} {set list_set {115200 n 8 2} } {
		set list_set [split $cfg(Ser_set) ,]
	};	foreach n {baud parity data stop} v $list_set {$w.$n set $v} 
	focus $w.ok
if 0 {
	$w.port set $nm
	set ports [join [list [.term.f.port get] [Hwserial] ]]
	.term.f.port configure -values $ports	
}
}

proc _cfg_dir_file ext {
	if {[array names ::cfg tmplog] eq ""} {
		list [file join [file dirname [info script]] log] default.$ext
	} { list [file dirname $::cfg(tmplog)] [file tail $::cfg(tmplog)]
	}
}
proc _config_log_btn {col} {	global cfg
	switch -- $col {
		1 {	filedo fh $cfg(tmplog) w {puts $fh ""}; return}
		2 { lassign [_cfg_dir_file log] fdir fname	;# browse
			set fname [tk_getSaveFile -filetypes $::app(filetypes) \
				-initialdir $fdir -initialfile $fname]
			if {"" ne $fname} {	set cfg(tmplog) $fname			
				.log.f.e delete 0 end;
				.log.f.e insert end [file tail $fname]
			}; return
		}
		4 {	set cfg(Logfile) $cfg(tmplog)	;# array names cfg Log*
			if {"alternate" eq [.log.f.ena state]} {set cfg(Log_ena) 1}
			if {"alternate" eq [.log.f.app state]} {set cfg(Log_app) 1}
		}
	};	unset cfg(tmplog); destroy .log
}
proc config_logging {} {	global cfg
	if {[winfo exists .log]} {
		wm attributes .log -topmost 1; focus .log.f.b1; return
	};	toplevel .log; set w .log; wm title $w "Log file"
	grid [ttk::frame $w.f -padding "5 1"] -row 0 -column 0 -sticky ew
	set w $w.f; ttk::entry $w.e -width 37 ;# -state readonly
	grid [ttk::label $w.l -width -3 -text File:] -row 0 -column 0 -sticky ns
	grid $w.e -row 0 -column 1 -columnspan 4 -pady 5 -padx 3 -sticky ew
	foreach {r v t} {1 ena Enable 2 app Append} {
		grid [ttk::checkbutton $w.$v -width -7 -text $t -onvalue 1 \
				-variable cfg(Log_$v)] -row $r -column 0
	}
	foreach {c t} {1 Truncate 2 Browse 3 Cancel 4 Ok} {
		ttk::button $w.b$c -width 9 -text $t -command "_config_log_btn $c"
		grid $w.b$c -padx 3 -pady 7 -row 1 -rowspan 2 -column $c
	};	if {![info exist cfg(Logfile)]} {set cfg(Logfile) "default.log"}
	set cfg(tmplog) $cfg(Logfile);	.log.f.e insert end $cfg(Logfile)
	focus $w.b1
}
# parray cfg Log*

# menu functions help_* -------------------------------------------------------
proc help_about {} {	toplevel .about
	wm title .about "About $::app(name)"
	pack [ttk::frame .about.f -padding "1 1"] -fill both -expand 1
	pack [ttk::scrollbar .about.f.sy -command [list .about.f.t yview] ] \
		-side right -fill y 
	pack [text .about.f.t -height 5 -width 45] -fill both -expand 1
	.about.f.t insert 1.0 "version: $::app(version)\n\n"
	.about.f.t insert end "todo:\n> serial port config/send/receive\n"
	.about.f.t insert end "> log file enable append truncate\n"
	.about.f.t insert end "> (Mouse-)button for assigning entry to Fn-key\n"
	.about.f.t configure -state disabled -yscrollcommand [list .about.f.sy set] 
	button .about.ok -text "Ok" -width 10 -command "destroy .about"
	pack .about.ok -side bottom -pady 10
}
proc xmit {arg} {
	msg_box [subst $arg] message "not yet transmitted"
#	set antw [...]
}

# MAIN --------------

# winfo children .
# winfo geometry .about
# winfo class .f.b1,2
# join [lsort -dict [grid slaves .f]] \n
# grid slaves .f -column 3
# grid info .f.b1,2

if 0 {
# https://wiki.tcl-lang.org/page/Ask%2C+and+it+shall+be+given+%23+1
# https://wiki.tcl-lang.org/page/Countdown+program


set bijna "[clock format [expr $tijd/1000] -format %H:%M:%S],[expr {($tijd %1000+50)/10}] "
if {uitgaand} {append bijna " % "};# {append bijna " < "}
+ plus nog de dataregel
+ plus, mits logbestand ingeschakeld: logbestand bijwerken en afsluiten

	# vervang tekst \n door LF:
set v [join [lrange $arr($n) 1 end]]	;# join verwijdert accolades
set v [string map {\\n \n} $arr($n)]	;# 
set v [subst $arr($n)]					;# meest rechtstreeks ?

ttk::style element names 
ttk::style theme names
proc traceproc args {puts "modified to: $args"}
trace add variable (f.e) write "traceproc $(f.e)" 
}