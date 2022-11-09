import shade

const
  vertShaderPath = "./assets/shaders/common.vert"
  fragShaderPath = "./assets/shaders/shockwave.frag"

type Shockwave* = ref object of Shader
  forceUniformID: int
  sizeUniformID: int
  thicknessUniformID: int
  centerUniformID: int

  force*: float
  size*: float
  thickness*: float
  center*: Vector

  animPlayer: AnimationPlayer

proc newShockwave*(): Shockwave =
  result = Shockwave()
  initShader(Shader result, vertShaderPath, fragShaderPath)

  result.forceUniformID = getUniformLocation(result.programID, "force")
  result.sizeUniformID = getUniformLocation(result.programID, "size")
  result.thicknessUniformID = getUniformLocation(result.programID, "thickness")
  result.centerUniformID = getUniformLocation(result.programID, "center")

  result.force = 0.0
  result.size = 0.0
  result.thickness = 0.5
  result.center = vector(0.5, 0.5)

  let
    this = result
    anim = newAnimation(0.5, false)
  anim.addNewAnimationTrack[:float](this.force, [KeyFrame[float] (0.2, 0.0), (0.0, 0.2)])
  anim.addNewAnimationTrack[:float](this.size, [KeyFrame[float] (0.0, 0.0), (0.75, 0.5)])
  result.animPlayer = newAnimationPlayer(("shockwave", anim))

proc updateForceUniform(this: Shockwave) =
  setUniformf(this.forceUniformID, cfloat this.force)

proc updateSizeUniform(this: Shockwave) =
  setUniformf(this.sizeUniformID, cfloat this.size)

proc updateThicknessUniform(this: Shockwave) =
  setUniformf(this.thicknessUniformID, cfloat this.thickness)

proc updateCenterUniform(this: Shockwave) =
  var center = [cfloat this.center.x, this.center.y]
  setUniformfv(this.centerUniformID, 2, 1, cast[ptr cfloat](center.addr))

proc playAnimation*(this: Shockwave) =
  this.animPlayer.play("shockwave")

proc update*(this: Shockwave, deltaTime: float) =
  this.animPlayer.update(deltaTime)
  this.updateForceUniform()
  this.updateSizeUniform()
  this.updateThicknessUniform()
  this.updateCenterUniform()

