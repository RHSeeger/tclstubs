#
# $Header: /home/rhseeger/svn/tclstubs-cvsbackup/tclstubs/tcl/stubs.tcl,v 1.3 2004-12-20 05:23:44 robert_seeger Exp $
#
#     The stubs package
#
# Copyright (c) 2004 Robert Seeger <robert_seeger@users.sourceforge.net>
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

namespace eval ::stubs {
    namespace export stub unstub loadStubs define chain

    namespace eval stubbedProcs {}

    variable libpaths [list [file dirname [info script]]]
    variable loaded 

    variable stubCount 0
    variable stubProcs
    variable stubStubs

    variable definedStubs
    variable definedGroups

    variable chainLevel

    array set stubStubs {}
    array set loaded {}
    array set definedStubs {}
    array set chainLevel {}

    proc stub {type args} {
        switch -exact -- $type {
            value {
                uplevel 1 [namespace current]::stubValue $args
            }
            alias {
                uplevel 1 [namespace current]::stubAlias $args
            }
            proc {
                uplevel 1 [namespace current]::stubProc $args
            }
            ensemble {
                uplevel 1 [namespace current]::stubEnsemble $args
            }
            defined {
                uplevel 1 [namespace current]::stubDefined $args
            }
            group {
                uplevel 1 [namespace current]::stubGroup $args
            }
            default {
                error "bad option \"$type\": must be value, alias, proc, group, or defined"
            }
        }
    }

    proc unstub {args} {
        variable stubProcs
        variable stubStubs

        if { ![llength $args] } {
            # unstub everything
            foreach name [array names stubProcs] {
                uplevel 1 [list [namespace current]::unstub $name]
            }
        }

        foreach procName $args {
            if { [string first :: $procName] != 0 } {
                # if { ![info exists stubProcs($procName)] } {}
                # puts "Changing $procName -> [namespace origin $procName]"
                set procName [namespace origin $procName]
            }
            if { ![info exists stubProcs($procName)] } {
                error "Cannot unstub \"$procName\":\
                       not a known stubbed command {[array names stubProcs]}"
            }
            while {[llength $stubProcs($procName)]} {
                set current [lindex $stubProcs($procName) end]
                uplevel 1 [list rename $procName {}]
                if { [string length $current] } {
                    uplevel 1 [list rename $current $procName]
                }
                if { [info exists stubStubs($current)] } {
                    unset stubStubs($current)
                }
                set stubProcs($procName) [lrange $stubProcs($procName) 0 end-1]
            }
            unset stubProcs($procName)
        }

    }

    proc loadStubs {args} {
        variable libpaths
        variable loaded

        switch -exact -- [llength $args] {
            1 {
                set forced 0
                set module [lindex $args 0]
            } 2 {
                if { ![string equal -force [lindex $args 0]] } {
                    error "usage: loadStubs ?-force? filename|module"
                }
                set forced 1
                set module [lindex $args 1]
            } default {
                error "usage: loadStubs ?-force? filename|module"
            }
        }

        set found 0
        if {[string match {*/*} $module]} {
            # Its a filename, not a stubs name
            if { [file exists $module] && [file readable $module] } {
                set filename $module
                set found 1
            } else {
                error "File does not exist: $module"
            }
        } else {
            foreach dir $libpaths {
                set filename [file join $dir "stubs.${module}.tcl"]
                if { [file readable $filename] } {
                    set found 1
                    break
                }
            }
            if { ! $found } {
                error "Could not find module: $module"
            }
        }

        if { [info exists loaded($filename)] && ! $forced} {
            return $filename
        }
        set result [uplevel 1 [list source $filename]]
        set loaded($filename) 1
        return $result
    }

    proc define {type args} {
        variable definedGroups
        variable definedStubs

        switch -exact -- $type {
            stub {
                if { [llength $args] < 2 } {
                    error "usage: define stub type name ?args?"
                }
                foreach {type name} $args {break}
                set definedStubs($name) \
                    [list $type [lrange $args 2 end]]
            }
            group {
                if { [llength $args] != 2 } {
                    error "usage: define group name script"
                }
                set definedGroups([lindex $args 0]) [lindex $args 1]
            } default {
                error "usage: define type args"
            }
        }
    }

    proc chain {args} {
        variable stubProcs
        variable stubStubs

        if { [info level] <= 1} {
            error "Cannot chain from the global scope"
        }
        set name [lindex [info level -1] 0]
        set name [uplevel 1 [list namespace origin $name]]

        if { [info exists stubProcs($name)] } {
            set command [linsert $args 0 [lindex $stubProcs($name) end]]
        } elseif { [info exists stubStubs($name)] } {
            set command [linsert $args 0 [lindex $stubStubs($name) end]]
        } else {
            error "Cannot chain from within an unstubbed proc"
        }

        return [uplevel 2 $command]
    }

    proc moveProc {name} {
        variable stubCount
        variable stubProcs
        variable stubStubs


        if {[llength [uplevel 1 [list info command $name]]] } {
#             set name [namespace origin $name]
            set ns [uplevel 1 {namespace current}]
            set stubName "stubbed-$name-[incr stubCount]"
            # uniquify the stubName but *must* remain in the
            # stubbed proc's namespace else call to stubs::chain
            # will fail.  This is because if a command is renamed
            # into a different namespace, future invocations of it
            # will execute in the new namespace. see Tcl 'rename' 
            set ns [namespace qualifiers [namespace origin $name]]
            set stubName [namespace.join $ns [regsub -all -- {:} $stubName {_}]]
            set oldName  [uplevel 1 [list namespace origin $name]]

            uplevel 1 [list ::stubs::rename $name $stubName]

            if { [info exists stubProcs($oldName)] } {
                # Stubbing an already stubbed proc
                set stubStubs($stubName) [lindex $stubProcs($oldName) end]
            }

        } else {
            if { [string first :: $name] != 0 } {
                set ns [uplevel 1 {namespace current}]
                set oldName [namespace.join $ns $name]
                set stubName {}
            }
        }
        if { [string first :::: $name] == 0 } {
            error "Name $name has too many :"
        }

        lappend stubProcs($oldName) $stubName
        return $stubName
    }

    proc stubValue {name value} {
        uplevel 1 [subst {
            [list [namespace current]::moveProc $name]
            proc [list $name] {args} { return [list $value] }
        }]

        #         uplevel 1 [list [namespace current]::moveProc $name]
        #         uplevel 1 [list proc $name {args} [list return $value]]
    }

    proc stubAlias {name args} {
        uplevel 1 [subst {
            [list [namespace current]::moveProc $name]
            interp alias {} [list $name] {} $args
        }]
    }

    proc stubProc {name argList body} {
        uplevel 1 [subst {
            [list [namespace current]::moveProc $name]
            [list proc $name $argList $body]
        }]
    }
    
    proc stubEnsemble {command args} {
        set procName [uplevel 1 [list [namespace current]::moveProc $command]]
        if { [llength $args] %2 } {
            error "Usage: stub ensemble command subcommand body\
                          ?subcommand body? ..."
        }
        
        set body {}
        foreach {subcommand clause} $args {
            set branch {
                if { [string equal $subCommand <<subCommand>>] } {
                    return [eval {
                        <<body>>
                    }]
                }
                
            }
            regsub {<<subCommand>>} $branch $subcommand branch
            regsub {<<body>>} $branch $clause branch
            lappend body $branch
        }
        set startBody [join $body "\n"]
        
        
        set procBody {
            <<startBody>>
            uplevel 1 [list <<procName>> $subCommand] $args
        }
        regsub {<<startBody>>} $procBody $startBody procBody
        regsub {<<procName>>} $procBody $procName procBody
        
        #puts [list proc $command {subCommand args} $procBody]
        uplevel 1 [list proc $command {subCommand args} $procBody]
    }
    
    proc stubDefined {name} {
        variable definedStubs

        if { ![info exists definedStubs($name)] } {
            error "Stub $name is not defined"
        }
        
        foreach {type argList} $definedStubs($name) {break}

        uplevel 1 [linsert $argList 0 ::stubs::stub $type $name]
    }

    proc stubGroup {name} {
        variable definedGroups

        if { ![info exists definedGroups($name)] } {
            error "Stub group $name is not defined"
        }
        uplevel 1 $definedGroups($name)
    }
    
    proc rename {origName newName} {
        set alias [uplevel 1 [list interp alias {} $origName]]
        if {[string length $alias]} {
            set trace [trace info command $origName]
            uplevel 1 [subst {
                [list ::rename $origName $newName]
                #interp alias {} $origName {}
                # Must re-create the alias, and the trace
                [list interp alias {} $newName {} $alias]
                foreach t [list $trace] {
                    eval [list [list trace add command $newName]] \$t
                }
            }]
        } else {
            uplevel 1 [list ::rename $origName $newName]
        }
    }

    proc namespace.join {args} {
        set result [join $args ::]
        set result [regsub -all -- {::::} $result {::}]

#         set result ""
#         foreach elem $args {
#             set elem [string trim $elem :]
#             if { ![string length $elem] } {
#                 continue
#             }
#             append result ::$elem
#         }
        return $result
    }
}


package provide stubs 1.1
