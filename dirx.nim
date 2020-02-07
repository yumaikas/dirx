import os, sequtils, strutils, terminal, algorithm, unicode

let filtered = filterIt(toSeq(walkDir(".", true)), not(it.path.startsWith(".")))
let dirs = sortedByIt(filtered, it.path.toUpper)
let maxNameLen = max(dirs.mapIt(it.path.len)) + 2
let totalLen = foldl(dirs.mapIt(it.path.len), a + b + 2) - 2
var entriesPerLine = max((terminalWidth() - 5) div maxNameLen, 1)
var numLines = (dirs.len div entriesPerLine)

if (terminalWidth() - 5) > totalLen:
  numLines = 1
  entriesPerLine = len(dirs) + 1

proc alignFn(name: string, padLen: int): string =
  if numLines > 1:
    return strutils.alignLeft(name, padLen)
  return name & "  "

proc emitEntry(entry: tuple[kind: PathComponent, path: string ], maxNameLen: int) =
  # Useful debugging code
  # stdout.write(alignFn($(entry.path.len), maxNameLen))
  # stdout.write(alignFn($($maxNameLen & " - " & $(entry.path.len)), maxNameLen))

  if entry.kind == pcFile or entry.kind == pcLinkToFile:
    setForegroundColor(fgWhite)
    stdout.write(alignFn(entry.path, maxNameLen))
    resetAttributes()
  if entry.kind == pcDir or entry.kind == pcLinkToDir:
    setForegroundColor(fgCyan)
    stdout.write(entry.path)
    resetAttributes()
    stdout.write(alignFn("/", maxNameLen - entry.path.len))

if numLines <= 1:
  for elem in dirs:
    emitEntry(elem, maxNameLen)
  echo ""
  quit()

let outputDirs = dirs.distribute(entriesPerLine)
# for line in outputDirs:
#   echo line
var colWidths = newSeq[int]()

for col in outputDirs:
  var maxColNameLen: int = 0
  for line in col:
    maxColNameLen = max(line.path.len, maxColNameLen)
  colWidths.add(maxColNameLen + 2)

# echo colWidths

for lineIdx in 0..numLines:
  var colIdx = 0
  for col in outputDirs:
    if len(col) > lineIdx:
      let elem = col[lineIdx]
      let w = colWidths[colIdx]
      emitEntry(elem, w)
    inc(colIdx)
  stdout.write("\p")
echo ""
