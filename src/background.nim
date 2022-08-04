import shade

const vertShaderPath = "./assets/shaders/common.vert"

type Background* = object
  shader: Shader

proc newBackground*(fragShaderPath: string): Background =
  result.shader = newShader(vertShaderPath, fragShaderPath)

Background.render:
  this.shader.render(gamestate.runTime, gamestate.resolution)
  ctx.rectangleFilled(0, 0, gamestate.resolution.x, gamestate.resolution.y, WHITE)
  deactivateShaderProgram()

