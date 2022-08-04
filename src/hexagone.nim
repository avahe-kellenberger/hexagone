import shade
import gamelayer, sounds
import std/[random]

randomize()

const
  isMobile = defined(mobile)
  width = if isMobile: 720 else: 360
  height = if isMobile: 1440 else: 720
  windowFlags =
    if isMobile:
      (WINDOW_ALLOW_HIGHDPI and int(INIT_ENABLE_VSYNC)) or WINDOW_FULLSCREEN
    else:
      (WINDOW_ALLOW_HIGHDPI and int(INIT_ENABLE_VSYNC))

initEngineSingleton(
  "Hexagone",
  width,
  height,
  windowFlags = windowFlags,
  clearColor = newColor(30, 30, 30)
)

let layer = newGameLayer(width, height)
Game.scene.addLayer(layer)

let song = loadMusic("./assets/music/song.ogg")
song.play(0.5)

loadSoundEffects()

Game.start()

