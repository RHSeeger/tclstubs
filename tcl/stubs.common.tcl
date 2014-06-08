#
# $Header: /home/rhseeger/svn/tclstubs-cvsbackup/tclstubs/tcl/stubs.common.tcl,v 1.1.1.1 2004-07-20 17:22:56 robert_seeger Exp $
#
#    common stubs for people to use
#
# Copyright (c) 2004 Robert Seeger <robert_seeger@users.sourceforge.net>
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#


package require stubs

::stubs::define stub ensemble array names {
    # sort the names before returning them
    return [lsort [eval [linsert $args 0 ::stubs::chain names]]]
} get {
    set retval {}
    set arrName [lindex $args 0]
    foreach key [uplevel 1 [list array names] $args] {
        lappend retval $key [uplevel 1 [list set ${arrName}($key)]]
    }
    return $retval
}

::stubs::define stub ensemble clock seconds { return 0 }
