import shade

import std/[tables, random]

randomize()

type HexagonColor* = enum
  RED
  YELLOW
  GREEN
  BLUE
  PURPLE

const
  HEXAGON_IMAGE_PATH = "./assets/gfx/hexagon.png"
  COLOR_TABLE = {
    RED: newColor(246, 76, 59),
    YELLOW: newColor(243, 228, 17),
    GREEN: newColor(27, 174, 86),
    BLUE: newColor(95, 198, 216),
    PURPLE: newColor(110, 58, 106)
  }.toTable()

  HEXAGON_SIZE* = vector(200, 230)
  HEXAGON_HALF_WIDTH* = HEXAGON_SIZE.x * 0.5
  HEXAGON_THREE_QUARTER_HEIGHT* = HEXAGON_SIZE.y * 0.75
  HEXAGON_QUARTER_HEIGHT* = HEXAGON_SIZE.y * 0.25

# TODO: Scale image down based on sceen size (gamestate.resolution).
# self.gameobjectsScalar = (screenSize.x - paddingFromSides.x * 2) / self.grid.width()
# From Gameplay.gd ^
var hexagonImage: Image = nil

type Hexagon* = ref object of Node
  color*: HexagonColor
  rgb: Color

proc newHexagon*(color: HexagonColor): Hexagon =
  result = Hexagon(color: color, rgb: COLOR_TABLE[color])
  initNode(Node result)

  if hexagonImage == nil:
    let (_, image) = Images.loadImage(HEXAGON_IMAGE_PATH)
    hexagonImage = image

proc getRandomHexagonColor*(): HexagonColor =
  return rand(HexagonColor.low .. HexagonColor.high)

proc getRandomHexagonColorExcluding*(colors: set[HexagonColor]): HexagonColor =
  return rand(HexagonColor.low .. HexagonColor.high)

Hexagon.renderAsNodeChild:
  hexagonImage.setRGB(this.rgb.r, this.rgb.g, this.rgb.b)
  hexagonImage.blit(nil, ctx, this.x + offsetX, this.y + offsetY)

