import shade
import hexagon as hexagonModule

const
  isMobile = defined(mobile)
  columns = 6
  rows = 5
  gridPadding = 20
  paddingFromSides = vector(200, 20)

type GameLayer = ref object of Layer
  touchLoc: Vector

proc onFingerDown(this: GameLayer, x, y: float)
proc onFingerUp(this: GameLayer, x, y: float)
proc onFingerDrag(this: GameLayer, x, y: float)

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

  for i in 0 .. 12:
    let hexagon = newHexagon(getRandomHexagonColor())
    hexagon.setLocation(float i * 32, float i * 32)
    this.addChild(hexagon)

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

