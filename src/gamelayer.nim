import shade
import
  hexagon as hexagonModule,
  hexagon_grid as hexagonGridModule

const
  isMobile = defined(mobile)
  paddingFromSides = if isMobile: vector(52, 8) else: vector(26, 4)
  gridPadding = if isMobile: 4 else: 2
  columns = 6
  rows = 5

type GameLayer = ref object of Layer
  touchLoc: Vector
  score: int
  grid: HexagonGrid
  gameobjectsScalar: float
  inverseGameobjectsScalar: float

proc onFingerDown(this: GameLayer, x, y: float)
proc onFingerUp(this: GameLayer, x, y: float)
proc onFingerDrag(this: GameLayer, x, y: float)
proc resetGame(this: GameLayer)

proc newGameLayer*(): GameLayer =
  result = GameLayer()
  initLayer(Layer result)
  let this = result

  when isMobile:
    Input.onEvent(FINGERDOWN):
      let touch = e.tfinger
      this.onFingerDown(touch.x, touch.y)

    Input.onEvent(FINGERUP):
      let touch = e.tfinger
      this.onFingerUp(touch.x, touch.y)

    Input.onEvent(FINGERMOTION):
      let touch = e.tfinger
      this.onFingerDrag(
        touch.x * gamestate.resolution.x,
        touch.y * gamestate.resolution.y
      )

  else:
    var isMouseDown = false
    Input.onEvent(MOUSEBUTTONDOWN):
      isMouseDown = true
      let motion = e.motion
      this.onFingerDown(float motion.x, float motion.y)

    Input.onEvent(MOUSEBUTTONUP):
      isMouseDown = false
      let motion = e.motion
      this.onFingerUp(float motion.x, float motion.y)

    Input.onEvent(MOUSEMOTION):
      if isMouseDown:
        let motion = e.motion
        this.onFingerDrag(float motion.x, float motion.y)

  result.resetGame()

# NOTE: Can get events off screen, even negative coords.
proc onFingerDown(this: GameLayer, x, y: float) =
  this.touchLoc.x = x
  this.touchLoc.y = y

proc onFingerUp(this: GameLayer, x, y: float) =
  this.touchLoc.x = x
  this.touchLoc.y = y

proc onFingerDrag(this: GameLayer, x, y: float) =
  this.touchLoc.x = x
  this.touchLoc.y = y

proc resetGame(this: GameLayer) =
  reset this.score

  let gridWidthInPixels = widthInPixels(columns, rows, gridPadding)
  this.gameobjectsScalar = (gamestate.resolution.x - paddingFromSides.x * 2) / gridWidthInPixels
  this.grid = createRandomHexagonGrid(columns, rows, gridPadding, this.gameobjectsScalar)
  this.inverseGameobjectsScalar = 1.0 / this.gameobjectsScalar
  this.grid.location = paddingFromSides

GameLayer.renderAsChildOf(Layer):
  if this.grid != nil:
    this.grid.render(ctx, offsetX, offsetY)

