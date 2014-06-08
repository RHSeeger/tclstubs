#!/bin/sh
# This line continues for Tcl, but is a single line for 'sh' \
        exec tclsh8.5 "$0" ${1+"$@"}

puts "DOCTOOLS: [package require doctools]"
puts "TCL: $tcl_version"
puts "TCL: [info patchlevel]"

#namespace import doctools::*

proc _man {module format ext docdir} {
    global config
    #global distribution argv argc argv0 config

    ::doctools::new dt -format $format -module $module

    set dirname [file dirname [info script]]

    foreach f [glob -nocomplain -directory $dirname *.man] {

	set out [file join $docdir [file rootname [file tail $f]]].$ext

	log "Generating $out"
	#if {$config(dry)} {continue}

	dt configure -file $f
        dt setparam meta {
            <!-- meta -->
            <link rel="stylesheet" href="manpage.css">
        }
        dt setparam header {
            <!-- header -->
            <div class="body">
        }
        dt setparam footer {
            <!-- footer -->
            </div>
        }
        set format_ip [set ::doctools::doctoolsdt::format_ip]
        #puts "comms: [$format_ip eval [list info commands *var*]]"
        #puts "format_ip: $format_ip"
#         foreach elem [dt parameters] {
#             set value [$format_ip eval [list fmt_var $elem]]
#             puts "\t${elem}: $value"
#         }
	file mkdir [file dirname $out]

	set data [dt format [get_input $f]]
	switch -exact -- $format {
	    nroff {
		set data [string map \
			[list \
			{.so man.macros} \
			$config(man.macros)] \
			$data]
	    }
	    html {}
	}
	write_out $out $data

	set warnings [dt warnings]
	if {[llength $warnings] > 0} {
	    log [join $warnings \n]
	}
    }
    dt destroy
    return
}

proc get_input {f} {
    return [read [set if [open $f r]]][close $if]
}
proc write_out {f text} {
    global config
    # if {$config(dry)} {log "Generate $f" ; return}
    catch {file delete -force $f}
    puts -nonewline [set of [open $f w]] $text
    close $of
}


proc main {} {
    global config

    set dir [file dirname [info script]]

    interp alias {} log {} puts
    
    set config(man.macros) \
            [string trim [get_input [file join $dir man.macros]]]

    doctools::search $dir
    
    _man doc nroff n $dir
    _man doc html2 html $dir
}

main