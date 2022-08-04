import shade

var
  hexagonClickSfx*: SoundEffect
  hexagonBreakSfx*: SoundEffect

proc loadSoundEffects*() =
  hexagonClickSfx = loadSoundEffect("./assets/sfx/hex_click.wav")
  hexagonBreakSfx = loadSoundEffect("./assets/sfx/hex_break.wav")

