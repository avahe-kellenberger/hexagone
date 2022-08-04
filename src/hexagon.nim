import shade

import std/[tables, random]

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

const ALL_COLORS: set[HexagonColor] = { HexagonColor.low .. HexagonColor.high }

var hexagonImage: Image = nil

type Hexagon* = ref object of PhysicsBody
  color*: HexagonColor
  rgb: Color
  scale: float

proc newHexagon*(color: HexagonColor, scale: float, inGrid: bool): Hexagon =
  result = Hexagon(
    kind: if inGrid: PhysicsBodyKind.STATIC else: PhysicsBodyKind.KINEMATIC,
    color: color,
    rgb: COLOR_TABLE[color],
    scale: scale
  )
  var collisionShape = newCollisionShape(newCircle(VECTOR_ZERO, HEXAGON_HALF_WIDTH * scale * 0.9))
  initPhysicsBody(PhysicsBody result, collisionShape)

  if hexagonImage == nil:
    let (_, image) = Images.loadImage(HEXAGON_IMAGE_PATH)
    hexagonImage = image

proc getRandomHexagonColor*(): HexagonColor =
  return rand(HexagonColor.low .. HexagonColor.high)

proc getRandomHexagonColorExcluding*(colors: set[HexagonColor]): HexagonColor =
  if colors == ALL_COLORS:
    raise newException(Exception, "getRandomHexagonColorExcluding given all colors!")
  return sample(ALL_COLORS - colors)

Hexagon.renderAsChildOf(PhysicsBody):
  hexagonImage.setRGB(this.rgb.r, this.rgb.g, this.rgb.b)
  hexagonImage.blitScale(nil, ctx, this.x + offsetX, this.y + offsetY, this.scale, this.scale)

