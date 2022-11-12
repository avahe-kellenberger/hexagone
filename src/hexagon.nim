import shade

import std/[tables, random]

type HexagonColor* {.pure.} = enum
  RED
  YELLOW
  GREEN
  BLUE
  PURPLE

const
  HEXAGON_IMAGE_PATH = "./assets/gfx/hexagon.png"
  COLOR_TABLE = {
    HexagonColor.RED: newColor(246, 76, 59),
    HexagonColor.YELLOW: newColor(243, 228, 17),
    HexagonColor.GREEN: newColor(113, 255, 61),
    HexagonColor.BLUE: newColor(61, 210, 255),
    HexagonColor.PURPLE: newColor(202, 60, 255)
  }.toTable()
  HEXAGON_SIZE* = vector(50, 58)
  HEXAGON_HALF_WIDTH* = HEXAGON_SIZE.x * 0.5
  HEXAGON_THREE_QUARTER_HEIGHT* = HEXAGON_SIZE.y * 0.75
  HEXAGON_QUARTER_HEIGHT* = HEXAGON_SIZE.y * 0.25
  PERFECT_MATERIAL* = initMaterial(1, 1, 0)

const ALL_COLORS: set[HexagonColor] = { HexagonColor.low .. HexagonColor.high }

var hexagonImage: Image = nil

type Hexagon* = ref object of PhysicsBody
  color*: HexagonColor
  rgb: Color
  alpha*: float
  scale: float

proc newHexagon*(color: HexagonColor, scale: float, inGrid: bool): Hexagon =
  result = Hexagon(
    kind: if inGrid: PhysicsBodyKind.STATIC else: PhysicsBodyKind.KINEMATIC,
    color: color,
    rgb: COLOR_TABLE[color],
    alpha: 1.0,
    scale: scale
  )
  var collisionShape = newCollisionShape(
    newCircle(VECTOR_ZERO, HEXAGON_HALF_WIDTH * scale * 0.9),
    PERFECT_MATERIAL
  )
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
  let alpha = uint8(clamp(0, uint8 (this.alpha * 255), 255))
  hexagonImage.setBlendMode(BLEND_NORMAL_FACTOR_ALPHA)
  hexagonImage.setRGBA(this.rgb.r, this.rgb.g, this.rgb.b, alpha)
  hexagonImage.blitScale(nil, ctx, this.x + offsetX, this.y + offsetY, this.scale, this.scale)

