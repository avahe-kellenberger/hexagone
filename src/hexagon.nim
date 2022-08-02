import shade

import std/[tables, random, sugar]

type HexagonColor* = enum
  RED
  YELLOW
  GREEN
  BLUE
  PURPLE

const
  HEXAGON_IMAGE_PATH = "./assets/gfx/hexagon_small.png"
  COLOR_TABLE = {
    RED: newColor(246, 76, 59),
    YELLOW: newColor(243, 228, 17),
    GREEN: newColor(27, 174, 86),
    BLUE: newColor(95, 198, 216),
    PURPLE: newColor(110, 58, 106)
  }.toTable()
  HEXAGON_SIZE* = vector(50, 58)
  HEXAGON_HALF_WIDTH* = HEXAGON_SIZE.x * 0.5
  HEXAGON_THREE_QUARTER_HEIGHT* = HEXAGON_SIZE.y * 0.75
  HEXAGON_QUARTER_HEIGHT* = HEXAGON_SIZE.y * 0.25

var ALL_COLORS: set[HexagonColor]
for color in HexagonColor.low .. HexagonColor.high:
  ALL_COLORS.incl(color)

var hexagonImage: Image = nil

type Hexagon* = ref object of Node
  color*: HexagonColor
  rgb: Color
  scale: float
  collisionRadius: float
  velocity*: Vector

proc newHexagon*(color: HexagonColor, scale: float): Hexagon =
  result = Hexagon(
    color: color,
    rgb: COLOR_TABLE[color],
    scale: scale,
    collisionRadius: HEXAGON_SIZE.x * scale * 0.9
  )
  initNode(Node result)

  if hexagonImage == nil:
    let (_, image) = Images.loadImage(HEXAGON_IMAGE_PATH)
    hexagonImage = image

proc getRandomHexagonColor*(): HexagonColor =
  return rand(HexagonColor.low .. HexagonColor.high)

proc getRandomHexagonColorExcluding*(colors: set[HexagonColor]): HexagonColor =
  if colors == ALL_COLORS:
    raise newException(Exception, "getRandomHexagonColorExcluding given all colors!")
  return sample(ALL_COLORS - colors)

method update*(this: Hexagon, deltaTime: float) =
  procCall update(Node this, deltaTime)
  this.move(this.velocity * deltaTime)

Hexagon.renderAsNodeChild:
  hexagonImage.setRGB(this.rgb.r, this.rgb.g, this.rgb.b)
  hexagonImage.blitScale(nil, ctx, this.x + offsetX, this.y + offsetY, this.scale, this.scale)

