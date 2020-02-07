import os, sequtils, strutils, terminal, algorithm

let filtered = filterIt(toSeq(walkDir(".", true)), not(it.path.startsWith(".")))
let dirs = sortedByIt(filtered, it.path)
let maxNameLen = max(dirs.mapIt(it.path.len)) + 2
let totalLen = foldl(dirs.mapIt(it.path.len), a + b + 2) - 2
var entriesPerLine = max((terminalWidth() - 5) div maxNameLen, 1)
var numLines = (dirs.len div entriesPerLine)

if (terminalWidth() - 5) > totalLen:
  numLines = 1
  entriesPerLine = len(dirs) + 1

proc alignFn(name: string, padLen: int): string =
  if numLines > 1:
    return alignLeft(name, padLen)
  return name & "  "

#[
var colIdx:int = 0
for entry in dirs:
  if colIdx == entriesPerLine:
    colIdx = 0
  if colIdx == 0:
    setForegroundColor(fgRed)
  echo entry.path
  resetAttributes()
  inc(colIdx)
]#

var outputCount = 0
for entry in dirs:
  if entry.kind == pcFile or entry.kind == pcLinkToFile:
    stdout.write(alignFn(entry.path, maxNameLen))
  if entry.kind == pcDir or entry.kind == pcLinkToDir:
    setForegroundColor(fgBlue)
    stdout.write(entry.path)
    stdout.write(alignFn("/", maxNameLen - entry.path.len))
  resetAttributes()
  inc(outputCount)
  if numLines > 1 and (outputCount == entriesPerLine):
    stdout.write("\p")
    outputCount = 0
echo ""
