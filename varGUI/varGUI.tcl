#!/bin/sh 
# \
exec wish "$0" "$@"

# http://www.tcl.tk/man/tcl8.5/
package require Tcl 8.5		;# chan lassign
package require Tk 8.5		;# ttk::
package require registry	;# 
# wm withdraw .

# DATA ========================================================================
proc data_init {} {
	# ::app 
	set ::LISTapp_defs {
		name varGUI
		version 0.2
		cols	{1 2 3 4 5 6 7 8 9 10 11 12}
		rows	{--- Shift- Control- Alt-}
	}
	set ::LISTtodo {
"" "todo:"
	"- auto-connect with serial port in config file"
	"- (Mouse-)button for assigning entry to (Modifier-)Fn"
	"- click on button in stead of (Modifier-)Fn"
"" "Short manual:"
	"The varGUI.ini file overrides the default application settings"
	"  and contains the name of the last used .cfg file."
	"A config file (.cfg) consists of three parts:"
	"  1. Fn,r(,m) the function key settings for Fn in row r"
	"  2. Log... the logging setup"
	"  3. Ser... the serial port setup\n"
	"Function key settings can be edited per row via Edit > Fn keys:"
	"  - labels are the texts visible inside the keys"
	"  - a message ending at \\n is transmitted by Fn-key press,"
	"    a message without is copied into the message entry"
	"  The button below the labels indicates the edited row:"
	"    ---  is the first row, with plain Fn-key settings, "
	"    Shift- Control- and Alt- for the other rows."
	"Serial port connection is made by accepting in Config > Serial"
	"Log settings are read by opening a .cfg file"
	}
	set ::LISTcfg_ser_defs {
		{1 port      readonly {NONE}}
		{2 baud_rate normal   {4800 9600 19200 38400 57600 115200}}
		{3 parity    readonly {none even odd}}
		{4 data_bits readonly {8}} 
		{5 stop_bits readonly {1 2}}
	}
	array set ::app $::LISTapp_defs		;# array set aRapp $LISTapp_defs
	set fname $::app(name).ini 
	if {[file exists $fname]} {data_rd [fread $fname]}
}
proc data_rd {data} {
	foreach line [split $data \n] {
		if {"" eq $line} {continue}
		if {"#" eq [string index $line 0]} {continue}
		if {![string is list $line]} {continue}
		set n [lindex $line 0]
		set v [join [lrange $line 1 end] ]
		if {[string is upper [string index $n 0] ]} {
			if {"Ser_fh" == $n} {continue}
			# Titled element names for ::cfg change \n into "visible"
			set ::cfg($n) [string map {\n \\n} $v]
		} {;# lowercase element names for ::app
			set ::app($n) $v
		}
	}
}
proc data_wr {_arr} {	upvar $_arr arr;
	if {![array exists arr]} {return ""}
	foreach n [lsort -dict [array names arr]] {
		# skip serial port file handle	
		if {"Ser_fh" == $n} {continue}
		# skip default Fn key text and empty message
		if {[regexp {F(\d+),(\d)(.*)} $n -> c r m]} {
			if {$m eq ""} {;# puts "?skip? ${->} c=$c r=$r m=$m"
				if {[string match $arr($n) "-- F$c --"]} {continue}
			} elseif {$m eq ",m" && $arr($n) eq ""} {continue}
		}
		append res $n\t[string map {\n \\n} $arr($n)]\n
	};	return $res
}
proc filedo args {	;# https://wiki.tcl-lang.org/page/withOpenFile
	if {[llength $args]<3} {
		error {wrong # args: should be "filedo fh fname ?access? ?permissions? script"}
	};	upvar 1 [lindex $args 0] fh
	try {	open {*}[lrange $args 1 end-1]
	} on ok fh {uplevel 1 [lindex $args end]
	} finally {	catch {chan close $fh}
	}
}
proc fappend {fname fdata {ext cfg}} {
	if {[string first . $fname] < 0} {append fname .$ext}
	filedo fh $fname a {chan puts $fh $fdata}	
}
proc fread {fname {ext cfg}} {
	if {[string first . $fname] < 0} {append fname .$ext}
	set res [filedo fh $fname r {chan read $fh}]
}
proc fwrite {fname fdata {ext cfg}} {
	if {[string first . $fname] < 0} {append fname .$ext}
	filedo fh $fname w {chan puts $fh $fdata}	
}

proc f_dir_name {_fname ext} {	upvar $_fname fname;
	if {![info exists $_fname]} {set fname ./$::app(name).$ext}
	list [file dirname $fname] [file tail $fname]
}

# GUI ============================================= see http://wiki.tcl.tk/2264
if 0 {	;# undocumented menu helper 
	proc ::tk::UnderlineAmpersand {text} {
		set s [string map {&& & & \ufeff} $text]
		set idx [string first \ufeff $s]
		return [list [string map {\ufeff {}} $s] $idx]
	}
}
proc gui_init {} {
	# Names of helper functions specific to the GUI start with _ 
	proc _Fn_send {col mod} {
		set line [join $::cfg(F$col,$mod,m)]					;#puts $line 
		if {[string index $line end] eq "\n"} {xmit $line} {
			.f.e delete 0 end;	.f.e insert end $line;	focus .f.e
		}
	}	
	proc _history_insert {args} {;# proc _history_insert {line {out 0} }
		set line {*}[lrange $args 0 end-1]
		set out [lindex $args end]
		if {$out} {set tag txtout} {set tag txtin} 
		.f.history.t configure -state normal
		.f.history.t insert end $line $tag
		.f.history.t see end
		.f.history.t configure -state disabled
	}
	proc _msg_box {arg {head ""} {foot "to be implemented"}} {
		tk_messageBox -type ok -message "$head \"$arg\"\n$foot"
	}

	wm title . $::app(name);
	ttk::style theme use xpnative;# clam;# alt;# default;# classic;# winnative;# 
	# window scaling in X and Y
	grid columnconfigure . 0 -weight 1
	grid rowconfigure . 0 -weight 1

	# menu: 2 levels with default action command in submenu -------------------
	. config -menu [menu .mnu]
	foreach {m u submenu} {
	file 0 {new 0 open 0 save 0 save_as 1 ... - exit 1}
	edit 0 {fn_keys 0} 
	config 0 {serial 0 logging 0}
	help 0 {about 0}
	} {	.mnu add cascade -label [string totitle $m] -underline $u \
				-menu [menu .mnu.$m -tearoff 0]
		foreach {s u} $submenu {
			if {"-" eq $u} {.mnu.$m add separator; continue}
			set cmd [join [list $m $s] _]
			proc $cmd {} "_msg_box $cmd"  
			.mnu.$m add command -label [string totitle [split $s _] ] \
					-underline $u -command $cmd
			# example: File > Save as has cmd file_save_as, which ...
			# ... defaults to alert: "file_save_as"\nto be implemented 
		}
	}

	# frame for window contents -----------------------------------------------
	grid [ttk::frame .f -padding "1 1"] -row 0 -column 0 -sticky news

	# Fn-key table, columns 1-12 scaling in width -----------------------------
	# column headers: row with Fn names
	set ::FnCOLS 0
	foreach c $::app(cols) {	incr ::FnCOLS
		grid [ttk::label .f.lbl0,$c -width -1 -text F$c] -column $c -row 0
		grid columnconfigure .f $c -minsize 30 -weight 1 -uniform cb
	};	grid columnconfigure .f 0  -minsize 30	;# header column 0 not scaling
	# Fn-keys with row header in column 0: indicates modifier key
	set r 0
	foreach hd $::app(rows) {
		incr r
		ttk::label .f.lbl$r,0 -width -2 -text $hd
		grid .f.lbl$r,0 -row $r -column 0 -padx 5 -sticky nws
		# Fn-keys with default texts and messages
		foreach c $::app(cols) {
			ttk::button .f.b$c,$r -textvar cfg(F$c,$r)
			grid .f.b$c,$r -sticky ew -column $c -row $r
			set ::cfg(F$c,$r) "-- F$c --"
			set ::cfg(F$c,$r,m) ""
#			switch -- $r {
#			1 {	bind . <F$c> [list _Fn_send $c $r]}
#			}
			if {1 == $r} {
				bind . <F$c> [list _Fn_send $c $r]
			} {	bind . <$hd\F$c> [list _Fn_send $c $r]
			}
		}
	}
	# todo: https://wiki.tcl-lang.org/page/console+platform+portability
	# http://wiki.tcl.tk/1649
	if {"windows" eq $::tcl_platform(platform)} {
		# Alt-F4 ends program, add Alt-F1 for Tcl console and Esc for restart
		bind . <Escape> {program_exit;eval [list exec wish $argv0] $argv &; exit}
		bind . <Alt-F1> {console show}
		if {4 == $r} {
			set ::cfg(F1,4) console		
			set ::cfg(F4,4) exit
			.f.b1,4 configure -state disabled
			.f.b4,4 configure -state disabled
		}
	}	 

	# message entry -----------------------------------------------------------
	incr r; 
	grid [ttk::entry .f.e] -sticky ew -column 1 -row $r -padx 1 \
			 -columnspan $::FnCOLS
	.f.e insert end "info commands"
	# ttk::button .f.b$r,$::FnCOLS -text assign
	# grid .f.b$r,$::FnCOLS -sticky ew -column $::FnCOLS -row $r

	# message history with slider ---------------------------------------------
	incr r
	grid rowconfigure .f $r -weight 1
	ttk::labelframe .f.history -text " message history  "
	grid .f.history -sticky news -row $r -column 1 -columnspan $::FnCOLS

	set w .f.history
	# use pack for assembling scrollbar and history text in a frame:
	text $w.t -height 15 -yscrollcommand [list $w.sy set] -state disabled
	ttk::scrollbar $w.sy -command [list $w.t yview]
	pack $w.sy -in $w -side right -fill y
	pack $w.t  -in $w -fill both -expand 1
	$w.t tag configure txtin -foreground black
	$w.t tag configure txtout -foreground blue

	# Use <Return> for sending the message
	bind . <Return> {xmit [.f.e get]; .f.e delete 0 end; focus .f.e}
	focus .f.e
}

proc menu_implement_functions {} {
	# after a call to gui_init all sub menus have an alert box as a function
	# the can be implemented with real actions by a new call to proc with the
	# same name and different body
	# Names of helpers specific to a (sub)menu start with _ 

	# menu file_* -------------------------------------------------------------
	proc _file_save_app_and_cfg {} {
		lassign [f_dir_name ::app(cfg) cfg] fdir fname
		set fname [tk_getSaveFile -filetypes {{{config files} {.cfg}}} \
				-initialdir $fdir -initialfile $fname]
		if {"" ne $fname} {	set ::app(cfg) $fname
			fwrite $::app(name).ini [data_wr ::app]
			fwrite $fname [data_wr ::cfg]
		}
	}
	proc file_exit {} {program_exit; exit}
	proc file_new {} {    _file_save_app_and_cfg}
	proc file_save {} {   _file_save_app_and_cfg}
	proc file_save_as {} {_file_save_app_and_cfg}
	proc file_open {} {
		lassign [f_dir_name ::app(cfg) cfg] fdir fname
		set fname [tk_getOpenFile -filetypes {{{config files} {.cfg}}} \
				-parent . -initialdir $fdir -initialfile $fname]
		if {$fname ne ""} {
			# assign function key labels and messages
			data_rd [set ::app(cfg) $fname; fread $fname]
			foreach n "[lsort -dict [array names ::cfg] ]" {
				if {"F" eq [string index $n 0]
				&&	"m" ne [string index $n end]} {
					set key [string range $n 1 end]
					.f.b$key configure -textvar ::cfg($n)
				};# else {puts "name $n"}
			}
			
		}
	}

	# menu edit_* -------------------------------------------------------------
	proc _edit_fn_get {mod} {
		# store values from entry fields
		if {$mod && $mod <= [llength $::app(rows)]} {
			foreach k $::app(cols) {	set w .keys.f.e$k
				set ::cfg(F$k,$mod)   [string map {\n \\n} [$w   get]]
				set ::cfg(F$k,$mod,m) [string map {\n \\n} [$w,m get]]
			}
		}
	}
	proc _edit_fn_populate {_row} {	upvar $_row r
		# store values, replace with values from new row, change sel-text
		_edit_fn_get $r
		if {[llength $::app(rows)] < [incr r]} {set r 1}
		foreach k $::app(cols) {	set w .keys.f.e$k
			$w   delete 0 end; $w   insert end $::cfg(F$k,$r)
			$w,m delete 0 end; $w,m insert end $::cfg(F$k,$r,m)
		}
		.keys.f.sel configure -text [lindex $::app(rows) $r-1]
		focus .keys.f.sel
	}
	proc _edit_fn_ok {mod} {
		# store values and quit menu
		_edit_fn_get $mod
		after 25 [destroy .keys]
	}
	proc edit_fn_keys {} {
		if {[winfo exists .keys]} {
			wm attributes .keys -topmost 1; focus .keys.f.sel; return
		}
		# window with Fn-key table, Fn-rows with label and message ------------
		toplevel .keys;	set w .keys; wm title $w "Function keys"
		ttk::labelframe $w.f -padding "5 1" -text " Edit > Fn keys  "
		grid $w.f -row 0 -column 0
		set w .keys.f

		# define keys, remember modifier key for text on select key
		set ::mod 0
		ttk::button $w.sel -width -7 -command {_edit_fn_populate ::mod}
		ttk::button $w.ok  -width -7  -command {_edit_fn_ok $::mod} -text "Ok"

		# column headers: row with Fn names
		foreach c {1 2} t {label message} {
			grid [ttk::label $w.lbl$c,0 -width -5 -text $t] -row 0 -column $c
		}

		# rows: header text message, last row: buttons
		foreach r $::app(cols) {
			grid [ttk::label $w.lbl$r -width -1 -text F$r] -column 0 -row $r
			grid [ttk::entry $w.e$r -width 12] -column 1 -row $r -padx 5 -pady 3
			grid [ttk::entry $w.e$r,m -width 48] -column 2 -row $r -padx 5
		};	incr r 
		grid $w.sel -column 1 -row $r -pady 5
		grid $w.ok  -column 2 -row $r -pady 5

		# fill the value entries
		_edit_fn_populate ::mod
		wm resizable .keys 0 0
	}

	# menu config_* -----------------------------------------------------------
	proc _cfg_ser_ok {} {	;#global cfg
		if ![winfo exists .term.f] return
		# close previous serial port, gather new settings
		Hwserial_disconnect
		set ::cfg(Ser_port) [.term.f.port get] 
		foreach r {1 2 3 4} {set n [lindex $::LISTcfg_ser_defs $r 1]
			append res [.term.f.$n get],
		};	set ::cfg(Ser_set) [string trimright $res ,]
		if {"NONE" ne $::cfg(Ser_port)} {
			# connect with port settings callback 
			Hwserial_connect $::cfg(Ser_port) $::cfg(Ser_set) Hwserial_rcv
		}
	}
	proc config_serial {} {
		if {[winfo exists .term]} {
			wm attributes .term -topmost 1;	return
		}
		# window with settings table: each setting with combobox --------------
		toplevel .term; set w .term; wm title $w "Serial port"
		ttk::labelframe $w.f -padding "5 3" -text " Config > Serial  "
		grid $w.f -row 0 -column 0
		set w .term.f
		
		# rows with label and combobox for setting, last row with buttons
		foreach line $::LISTcfg_ser_defs {
			foreach {r cbb st listv} $line {
				ttk::label $w.lb$r -text [string totitle [split $cbb _]]:
				ttk::combobox $w.$cbb -state $st -values $listv
				grid $w.lb$r -row $r -column 0 -padx 5 -sticky w
				grid $w.$cbb -row $r -column 1 -pady 3 -columnspan 2
			}
		};	incr r
		foreach {c lb cmd} {
		1 cancel {unset ::ports; destroy .term}
		2 ok     {_cfg_ser_ok; destroy .term}
		} {	grid [ttk::button $w.$lb -width 9 -command $cmd \
					-text [string toupper $lb]] -column $c -row $r -pady 5
		}

		# populate ::cfg for Serial ports and fill in data fields
		set ::ports NONE;	# lappend ::ports [list [Hwserial]]
		foreach port [Hwserial] {lappend ::ports $port}
		if {![info exists ::cfg(Ser_port)]} {set ::cfg(Ser_port) NONE}
		if {![info exists ::cfg(Ser_set)]} {set ::cfg(Ser_set) 115200,n,8,2}
		$w.port configure -values [lsort -unique [join $::ports]]
		$w.port set $::cfg(Ser_port);
		foreach r {1 2 3 4} v [split $::cfg(Ser_set) ,] {
			set n [lindex $::LISTcfg_ser_defs $r 1]
			$w.$n set $v
		}
# join [lsort [winfo children .term.f]] \n
		wm resizable .term 0 0
		focus $w.ok
	}

	proc _config_log_btn {col} {
		switch -- $col {
		1 {	fwrite $::cfg(Logtmp) "";	return		}
		2 {	lassign [f_dir_name ::cfg(Logtmp) log] fdir fname
			set fname [tk_getSaveFile -initialdir $fdir -initialfile $fname \
					-filetypes {{{log files} {.log .txt}}}]
			if {"" ne $fname} {	set ::cfg(Logtmp) $fname			
				.log.f.e delete 0 end;
				.log.f.e insert end [file tail $fname]
			}; return
		}
		4 {	if {"alternate" eq [.log.f.ena state]} {set ::cfg(Log_ena) 1}
			if {"alternate" eq [.log.f.app state]} {set ::cfg(Log_app) 1}
		#	set ::cfg(Logfile) $::cfg(Logtmp)	;# array names cfg Log*
			if {[info procs log_start] ne ""} {
				log_start $::cfg(Logtmp)
			}
		}
		};	unset ::cfg(Logtmp); destroy .log
	}
	proc config_logging {} {
		if {[winfo exists .log]} {
			wm attributes .log -topmost 1; focus .log.f.b1; return
		}
		# window with first row: file name in entry  --------------------------
		toplevel .log; set w .log; wm title $w "Logging"
		ttk::labelframe $w.f -padding "5 1" -text " Config > Logging  "
		grid $w.f -row 0 -column 0
		set w $w.f;
		grid [ttk::label $w.l -width -3 -text File:] -row 0 -column 0 -sticky ns
		grid [ttk::entry $w.e -width 37] -columnspan 4 -row 0 -column 1 \
			-pady 5 -padx 3 -sticky ew

		# 2 check buttons below label File:, other buttons below entry		
		foreach {r v t} {1 ena Enable 2 app Append} {
			grid [ttk::checkbutton $w.$v -width -7 -text $t \
					-onvalue 1 -variable ::cfg(Log_$v)] -row $r -column 0
		}
		foreach {c t} {1 Truncate 2 Browse 3 Cancel 4 Ok} {
			ttk::button $w.b$c -width 9 -text $t -command "_config_log_btn $c"
			grid $w.b$c -padx 3 -pady 7 -rowspan 2 -row 1 -column $c
		};
		lassign [f_dir_name ::cfg(Logfile) log] fdir fname
		.log.f.e insert end [set ::cfg(Logtmp) $fname]  
		wm resizable .log 0 0
		focus $w.b1
	}

	# menu help_* -------------------------------------------------------------
	proc help_about {} {
		if {[winfo exists .about]} {
			wm attributes .about -topmost 1; return
		}
		toplevel .about;	set w .about
		# wm title .about "About $::app(name)"

		# use pack for assembling scrollbar and about text in a frame:
		ttk::labelframe $w.f -padding "1 1" -text " Help > About  "
		pack $w.f -fill both -expand 1
		pack [ttk::scrollbar .about.f.sy -command [list .about.f.t yview] ] \
			-side right -fill y 
		pack [text .about.f.t -height 15 -padx 10] -fill y -expand 1
		
		# insert text:
		set mlw 40	;# maximum line width
		.about.f.t insert 1.0 \
		"program: $::app(name)\nversion: $::app(version)\n"
		foreach line $::LISTtodo {	set lw [string length $line]
			if {$mlw < $lw} {set mlw $lw};	.about.f.t insert end "$line\n"
		};	if {$mlw > 80} {set mlw 80}
		.about.f.t configure -state disabled -width $mlw\
			-yscrollcommand [list .about.f.sy set] 
		button .about.ok -text "Ok" -width 10 -command "destroy .about"
		pack .about.ok -side bottom -pady 10
		wm resizable .about 0 1
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
proc log_start {fname} {
	puts $fname
	if {$::cfg(Log_ena)} {
		set dt [clock format [clock seconds] -format "%d/%m/%Y %T"]
		set record "##### varGUI log started $dt #####\n"
		if {$::cfg(Log_app)} {fappend $fname $record} {fwrite $fname $record}
	};	set ::cfg(Logfile) $fname
}
proc log_append {record} {
	if {[array names ::cfg Logfile] ne ""} {
		fappend $::cfg(Logfile) $record
	}
}


# SERIAL ======================================================================
# https://wiki.tcl-lang.org/page/Serial+Port
proc Hwserial {} {;# https://wiki.tcl-lang.org/page/serial+ports+on+Windows
	set res ""
	if {"windows" eq $::tcl_platform(platform)} {
		package require registry
		set R HKEY_LOCAL_MACHINE\\HARDWARE\\DEVICEMAP\\SERIALCOMM
		catch {	foreach v [registry values $R] {
			lappend res [registry get $R $v]}
		}
	} elseif {"linux" eq [lindex [split [::platform::generic] -] 0]} {
		set res [glob -nocomplain {/dev/ttyS[0-9]} {/dev/ttyUSB[0-9]} \
				{/dev/ttyACM[0-9]}]
	} else {;# bsd variants
		set res [glob -nocomplain {/dev/tty0[0-9]} {/dev/ttyU[0-9]}]
	};	lsort $res
}

proc Hwserial_rcv fh {
	while {[chan gets $fh line] >= 0} {
		puts $line
		_history_insert $line 0
		if {![info exists ::cfg(Logfile)]} {continue}
		if {![info exists ::cfg(Log_ena)]} {continue}
		if {!$::cfg(Log_ena)} {continue}
		set record [log_record [string map {\r {} \n {} } $line] 0] 
		log_append $record
	}
}

proc Hwserial_connect {port baudset callback} {
	set fh [open $port r+]
	set ::cfg(Ser_fh) $fh

	# non-blocking needs event loop, so invoke vwait somewhere
	fconfigure $fh -blocking 0 -mode $baudset

	# none = each character sent, no buffersize needed
	# line = send at \n
	# full = send at flush command
	fconfigure $fh -buffering none;# -buffersize 1024 

	# for now, use the default, set code [encoding system]
#	fconfigure $fh -encoding binary

	# for working with DOS file systems:
#	fconfigure $fh -eofchar \x1a

	fconfigure $fh -translation binary ;# auto;# cr ;# crlf ;# lf ;# 
			
	fileevent $fh readable [list $callback $fh]
}
proc Hwserial_disconnect {} {
	if [info exists ::cfg(Ser_fh)] {
		close $::cfg(Ser_fh)
		after 25 [unset ::cfg(Ser_fh)]
	}		
}
proc xmit {args} {
	set line [join $args]\n 
	_history_insert $line 1
	if [info exists ::cfg(Ser_fh)] {
		if {[info exists ::cfg(Logfile)]
		&&	[info exists ::cfg(Log_ena)]} {
			if {$::cfg(Log_ena)} {
				set record [log_record [string map {\r {} \n {} } $line] 1] 
				log_append $record
			}
		}
		puts $::cfg(Ser_fh) $line
		flush $::cfg(Ser_fh)
	} {tk_messageBox -type ok -message "no serial port selected"}
}

# MAIN ========================================================================
proc program_exit {} {
	if [info exists ::cfg(Ser_fh)] {
		close $::cfg(Ser_fh)
		puts "Closed connection with handle $::cfg(Ser_fh)"
		while {1} {
			after 5000 [break]
		}
	}
}

data_init
gui_init
menu_implement_functions
vwait forever
