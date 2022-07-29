# Package

version       = "0.1.0"
author        = "Anonymous"
description   = "A new awesome nimble package"
license       = "GPL-2.0-only"
srcDir        = "src"
bin           = @["hexagone"]


# Dependencies

requires "nim >= 1.6.6"

import os

switch("multimethods", "on")
switch("import", "std/lenientops")

task runr, "Runs the program in release mode":
  exec "nim r -d:release src/hexagone.nim"

task run_mobile, "Runs the program in release mode":
  exec "nim r -d:release -d:mobile src/hexagone.nim"

task buildr, "Builds a release binary of the program":
  exec "nim c -d:release src/hexagone.nim"

