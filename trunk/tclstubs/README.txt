Description:

Stubs is a package for the Tcl programming language, intended to make writing
tests faster and easier. By simplifying the process of temporarily replacing the
functionality of a command, group of commands, or part of a command, test cases
are simpler to both write and understand.

The package provides the following functionality:
- Stub out a command in several ways:
  - Replace a command with one that returns a simple value
  - Replace a command with an alias to another command
  - Replace a command with a new command definition
  - Replace a command with another, predefined, command
  - Replace a subcommand of a command with a new code block (i.e., clock seconds)
- Unstub a command, returning it to its original functionality
- Call the previous definition of a command from within a stub
- Define command replacements, which can later be used in the stub process
- Define stub Groups with can be used to stub multiple commands at once
- Load stub modules, which can define various groups and/or stubs

Note:

The Stubs package was originally written for use with the standard Tcl package
tcltest. While there is no reason it should not work with other testing
frameworks, it has not been tested outside of tcltest.

Acknowledgments:

The Stubs package was originally designed and written at AOL, in support of unit
testing for various software projects there. While the code in this package was
developed separately from that use at AOL, the base ideas and functionalities
are the same. As such, I extend my thanks to AOL for the ideas contained in this
package, and for allowing me to take those ideas and publicly release my own
implementation of them.

I would also like to thank Dossy Shiobara, who was a co-developer of the
original package and was kind enough to provide many helpful ideas about the
functionality.