import shade

const
  isMobile = defined(mobile)
  width = if isMobile: 720 else: 360
  height = if isMobile: 1440 else: 720
  ballRadius = if isMobile: 20.0 else: 10.0

initEngineSingleton(
"Hexagone",
  width,
  height,
  windowFlags = (WINDOW_ALLOW_HIGHDPI and int(INIT_ENABLE_VSYNC))
)

var
  touchX = float.low
  touchY = float.low

when isMobile:
  Input.onEvent(FINGERDOWN):
    echo "FINGERDOWN"

  Input.onEvent(FINGERUP):
    echo "FINGERUP"

  Input.onEvent(FINGERMOTION):
    let touch = e.tfinger
    touchX = touch.x * gamestate.resolution.x
    touchY = touch.y * gamestate.resolution.y

else:
  var isMouseDown = false

  Input.onEvent(MOUSEBUTTONDOWN):
    echo "MOUSEBUTTONDOWN"
    isMouseDown = true

  Input.onEvent(MOUSEBUTTONUP):
    echo "MOUSEBUTTONUP"
    isMouseDown = false

  Input.onEvent(MOUSEMOTION):
    if isMouseDown:
      let motion = e.motion
      touchX = float motion.x
      touchY = float motion.y

let layer = newLayer()
Game.scene.addLayer(layer)

layer.onRender = proc(this: Layer, ctx: Target) =
  ctx.circleFilled(touchX, touchY, ballRadius, RED)

# let song = loadMusic("./assets/music/song.ogg")
# if song != nil:
#   play(song)

Game.start()
