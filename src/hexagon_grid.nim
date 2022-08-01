import shade

import std/[sets]
import seq2d
import hexagon as hexagonModule

type
  Cell* = tuple[x: int, y: int]
  HexagonGrid* = object
    location: Vector
    columnOffset: int
    # Whether the first row is offset
    isFirstRowOffset: bool
    padding: int
    grid: Seq2D[Hexagon]
    hexagonSize: Vector

const NULL_CELL* = (-1, -1)

proc updateHexagonPositions(this: HexagonGrid)
proc updateHexagonPosition(this: HexagonGrid, hexagon: Hexagon, x, y: int)
proc removeHexagonAt*(this: var HexagonGrid, column, row: int): Hexagon
proc isColumnEmpty*(this: HexagonGrid, x: int): bool
proc isRowEmpty*(this: HexagonGrid, y: int): bool
proc floodfill(this: HexagonGrid, x, y: int, addedHexagons: var HashSet[Hexagon], color: HexagonColor)
proc getAdjacentIndicies(this: HexagonGrid, column, row: int): array[6, Cell]
proc getHexagonPosition(this: HexagonGrid, column, row: int): Vector

proc newHexagonGrid*(width, height, padding: int, hexagonSize: Vector): HexagonGrid =
  if width < 1 or height < 1:
    raise newException(Exception, "Width and height of HexagonGrid must be > 0")

  result.hexagonSize = hexagonSize
  result.padding = padding
  result.grid = newSeq2D[Hexagon](width, height)

proc width*(this: HexagonGrid): int =
  return this.grid.width

proc height*(this: HexagonGrid): int =
  return this.grid.height

proc widthInPixels*(this: HexagonGrid): float =
  result = this.width * (HEXAGON_SIZE.x + this.padding) - this.padding
  if this.height > 1:
    result += HEXAGON_HALF_WIDTH

proc heightInPixels*(this: HexagonGrid): float =
  return this.height * (
    HEXAGON_THREE_QUARTER_HEIGHT + this.padding
  ) + HEXAGON_QUARTER_HEIGHT - this.padding

proc isRowOffset(this: HexagonGrid, row: int): bool =
  return ((row and 1) == 0) == this.isFirstRowOffset

proc indexOf(this: HexagonGrid, hex: Hexagon): Cell =
  # TODO optimize this lookup (maybe a map or store the cell in the hexagon)
  for x, y, hexagon in this.grid.items:
    if hexagon == hex:
      return (x, y)
  return NULL_CELL

proc getHexagon(this: HexagonGrid, column, row: int): Hexagon =
  if column < 0 or column >= this.width or row < 0 or row >= this.height:
    return nil
  return this.grid[column, row]

proc setHexagon(this: var HexagonGrid, column, row: int, hex: Hexagon) =
  if hex == nil:
    return

  var
    x = column
    y = row
    gridWidth = this.width
    gridHeight = this.height
    # Values must be >= 0
    shiftX = 0
    shiftY = 0
    shiftWidth = 0
    shiftHeight = 0

  if x < 0:
    shiftX = -x
    shiftWidth = shiftX
    this.columnOffset += x
    x = 0
    this.location.x -= (this.hexagonSize.x + this.padding) * shiftX
  elif (x + 1) > gridWidth:
    shiftWidth = x - gridWidth + 1

  if y < 0:
    shiftY = -y
    shiftHeight = shiftY
    y = 0
    this.isFirstRowOffset = this.isFirstRowOffset != ((shiftY and 1) != 0)
    this.location.y -= (this.hexagonSize.y * 0.75 + this.padding) * shiftY
  elif (y + 1) > gridHeight:
    shiftHeight = y - gridHeight + 1

  # TODO: ?
  # this.add_child(hex)

  if shiftWidth != 0 or shiftHeight != 0:
    # Resize array and shift everything as needed
    var
      newWidth = gridWidth + shiftWidth
      newHeight = gridHeight + shiftHeight
      newArray = newSeq2D[Hexagon](newWidth, newHeight)

    for y in 0 ..< gridHeight:
      for x in 0 ..< gridWidth:
        newArray[x + shiftX, y + shiftY] = this.grid[x, y]

    newArray[x, y] = hex
    this.grid = newArray
    this.updateHexagonPositions()
  else:
    # Place hexagon into grid
    this.grid[x, y] = hex
    # Position hexagon relative to grid
    this.updateHexagonPosition(hex, x, y)

proc removeHexagon*(this: var HexagonGrid, hexagon: Hexagon): bool =
  let cell = this.indexOf(hexagon)
  return cell != NULL_CELL and hexagon == this.removeHexagonAt(cell.x, cell.y)

proc removeHexagonAt*(this: var HexagonGrid, column, row: int): Hexagon =
  var hex = this.getHexagon(column, row)
  if hex == nil:
    return nil

  hex.move(this.location)
  # TODO: ?
  # this.remove_child(hex)

  this.grid[column, row] = nil

  let
    gridWidth = this.width
    gridHeight = this.height

  var
    shiftX = 0
    shiftY = 0
    shiftWidth = 0
    shiftHeight = 0

  if column == 0:
    var x = column
    while x < gridWidth and this.isColumnEmpty(x):
      x += 1
    shiftX = column - x
    shiftWidth = shiftX
    this.location.x -= (this.hexagonSize.x + this.padding) * shiftX
    this.columnOffset += x
  elif column + 1 == gridWidth:
    var x = column
    while x >= 0 and this.isColumnEmpty(x):
      x -= 1
    shiftWidth = x - column

  if row == 0:
    var y = row
    while y < gridHeight and this.isRowEmpty(y):
      y += 1
    shiftY = row - y
    shiftHeight = shiftY
    this.isFirstRowOffset = this.isFirstRowOffset != ((-shiftY and 1) != 0)
    # TODO: Use constant for hexagon height * 3/4
    this.location.y -= (this.hexagonSize.y * 0.75 + this.padding) * shiftY
  elif row + 1 == gridHeight:
    var y = row
    while y >= 0 and this.isRowEmpty(y):
      y -= 1
    shiftHeight = y - row

  if shiftWidth != 0 or shiftHeight != 0:
    # Resize array and shift everything as needed
    var
      newWidth = gridWidth + shiftWidth
      newHeight = gridHeight + shiftHeight
      newArray = newSeq2D[Hexagon](newWidth, newHeight)
    for j in 0 ..< newHeight:
      for i in 0 ..< newWidth:
        newArray[i, j] = this.grid[i - shiftX, j - shiftY]

    this.grid = newArray
    this.updateHexagonPositions()

  return hex

proc isColumnEmpty*(this: HexagonGrid, x: int): bool =
  for y in 0 ..< this.grid.height:
    if this.grid[x, y] != nil:
      return false
  return true

proc isRowEmpty*(this: HexagonGrid, y: int): bool =
  for x in 0 ..< this.grid.width:
    if this.grid[x, y] != nil:
      return false
  return true

proc addRandomRowAtTop*(this: var HexagonGrid, numOfColumns: int) =
  ## Adds a new row to the top of the grid.
  var
    col = 0
    lastColor = -1
    touchingColors: set[HexagonColor]
    rowBelow: int = 0

  while col < numOfColumns:
    # Must re-evaluate column offset each loop (do not put in range!)
    col -= this.columnOffset

    # Find colors of the below hexagons.
    var downLeftColor = -1
    var downRightColor = -1

    var isOffset: bool = this.isRowOffset(rowBelow)
    if isOffset:
      let downLeftHex = this.getHexagon(col - 1, rowBelow)
      downLeftColor = if downLeftHex == nil: -1 else: ord(downLeftHex.color)
      let downRightHex = this.getHexagon(col, rowBelow)
      downRightColor = if downRightHex == nil: -1 else: ord(downRightHex.color)
    else:
      let downLeftHex = this.getHexagon(col, rowBelow)
      downLeftColor = if downLeftHex == nil: -1 else: ord(downLeftHex.color)
      let downRightHex = this.getHexagon(col - 1, rowBelow)
      downRightColor = if downRightHex == nil: -1 else: ord(downRightHex.color)

    if downLeftColor != -1:
      touchingColors.incl(HexagonColor downLeftColor)

    if downRightColor != -1:
      touchingColors.incl(HexagonColor downRightColor)

    if lastColor == -1:
      touchingColors.incl(HexagonColor lastColor)

    var newColor = getRandomHexagonColorExcluding(touchingColors)
    var newHexagon = newHexagon(newColor)
    # newHexagon.add_to_group(Hexagon.GROUP_HEXAGON_GRID)
    lastColor = ord(newColor)
    reset touchingColors

    this.setHexagon(col, rowBelow - 1, newHexagon)

    rowBelow = 1
    inc col

proc floodfill*(
  this: HexagonGrid,
  hexagon: Hexagon,
  addedHexagons: var HashSet[Hexagon],
  color: HexagonColor
) =
  ## Recursively gets adjacent hexagons of the same color and adds them to the list.
  if addedHexagons.containsOrIncl(hexagon):
    let cell = this.indexOf(hexagon)
    if cell != NULL_CELL:
      this.floodfill(cell.x, cell.y, addedHexagons, color)

proc floodfill(this: HexagonGrid, x, y: int, addedHexagons: var HashSet[Hexagon], color: HexagonColor) =
  let adjacent = this.getAdjacentIndicies(x, y)
  for cell in adjacent:
    let next = this.getHexagon(cell.x, cell.y)
    if next != nil and next.color == color and addedHexagons.containsOrIncl(next):
      this.floodfill(cell.x, cell.y, addedHexagons, color)

proc getAdjacentIndicies(this: HexagonGrid, column, row: int): array[6, Cell] =
  let isOffset: bool = this.isRowOffset(row)
  return [
    # Top two
    (column, row - 1),
    ((if isOffset: column + 1 else: column - 1), row - 1),
    # Sides
    (column - 1, row),
    (column + 1, row),
    # Bottom two
    (column, row + 1),
    ((if isOffset: column + 1 else: column - 1), row + 1)
  ]

proc getInsertionIndex(this: HexagonGrid, relativePosition: Vector, collided: Cell): Cell =
  result = NULL_CELL
  var smallestDistance: float = INF

  let adjacentIndices = this.getAdjacentIndicies(collided.x, collided.y)
  for cell in adjacentIndices:
    if this.getHexagon(cell.x, cell.y) != nil:
      continue

    let
      hexPosition = this.getHexagonPosition(cell.x, cell.y)
      dist = hexPosition.distanceSquared(relativePosition)

    if smallestDistance > dist:
      result = cell
      smallestDistance = dist

proc getHexagonPosition(this: HexagonGrid, column, row: int): Vector =
  let
    spriteWidth = this.hexagonSize.x
    spriteHeight = this.hexagonSize.y
    halfWidth = spriteWidth * 0.5
    quarterHeight = spriteHeight * 0.25

  if this.isRowOffset(row):
    result.x = halfWidth + (column * spriteWidth) + (this.padding * 0.5)
  else:
    result.x = column * spriteWidth

  result.y = row * (spriteHeight - quarterHeight)

  result.x += this.padding * column + halfWidth
  result.y += this.padding * row + (spriteHeight * 0.5)

proc updateHexagonPositions(this: HexagonGrid) =
  for x, y, hexagon in this.grid.items:
    if hexagon != nil:
      this.updateHexagonPosition(hexagon, x, y)

proc updateHexagonPosition(this: HexagonGrid, hexagon: Hexagon, x, y: int) =
  hexagon.setLocation(this.getHexagonPosition(x, y))

