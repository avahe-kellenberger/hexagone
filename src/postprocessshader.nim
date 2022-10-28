import shade

const vertShaderPath = "./assets/shaders/common.vert"

type PostProcessShader* = object
  shader: Shader

proc newPostProcessShader*(fragShaderPath: string): PostProcessShader =
  result.shader = newShader(vertShaderPath, fragShaderPath)

PostProcessShader.render:
  this.shader.render(gamestate.runTime, gamestate.resolution)
  # TODO: Do I need to render the game image again for this shader?
  # blit(ctx.image, nil, ctx, 0, 0)
  deactivateShaderProgram()

