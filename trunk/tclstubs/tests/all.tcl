#!/bin/sh
# This line continues for Tcl, but is a single line for 'sh' \
	exec tclsh "$0" ${1+"$@"}

package require tcltest
puts "Running tests"

tcltest::configure -verbose {body error}

if { [llength $argv] } {
    eval tcltest::configure $argv
}

tcltest::runAllTests

