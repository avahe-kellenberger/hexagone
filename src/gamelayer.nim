import shade

import
  hexagon_grid as hexagonGridModule,
  hexagon as hexagonModule,
  background as backgroundModule

const
  isMobile = defined(mobile)
  paddingFromSides = when isMobile: vector(104, 16) else: vector(52, 8)
  gridPadding = when isMobile: 4 else: 2
  columns = 6
  rows = 5
  indicatorCircleRadius = 35.0
  transparentWhite = newColor(255, 255, 255, 100)
  slingshotLineColor = newColor(247, 114, 41)

type GameLayer = ref object of Layer
  background: Background
  touchLoc: Vector
  score: int
  grid: HexagonGrid
  gameobjectsScalar: float
  projectileAnchor: Vector
  projectile: Hexagon
  projectileBounces: int
  projectileHasBeenFired: bool
  maxProjectilePullBackDistance: float
  minProjectileVelocity: float
  maxProjectileVelocity: float

proc onFingerDown(this: GameLayer, x, y: float)
proc onFingerUp(this: GameLayer, x, y: float)
proc onFingerDrag(this: GameLayer, x, y: float)
proc resetGame(this: GameLayer)

proc newGameLayer*(): GameLayer =
  result = GameLayer()
  initLayer(Layer result)
  let this = result
  
  this.background = newBackground()

  this.projectileAnchor = vector(
    gamestate.resolution.x / 2,
    gamestate.resolution.y * 0.75
  )

  this.maxProjectilePullBackDistance = this.projectileAnchor.x - HEXAGON_SIZE.y * 0.5
  this.minProjectileVelocity = gamestate.resolution.y / 3
  this.maxProjectileVelocity = gamestate.resolution.y * 2

  when isMobile:
    Input.onEvent(FINGERDOWN):
      let touch = e.tfinger
      this.onFingerDown(touch.x, touch.y)

    Input.onEvent(FINGERUP):
      let touch = e.tfinger
      this.onFingerUp(
        touch.x * gamestate.resolution.x,
        touch.y * gamestate.resolution.y
      )

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
  if not this.projectileHasBeenFired:
    this.touchLoc.x = x
    this.touchLoc.y = y

proc onFingerUp(this: GameLayer, x, y: float) =
  if this.projectileHasBeenFired:
    return

  this.touchLoc.x = x
  this.touchLoc.y = y

  if this.projectile == nil:
    return

  let dist = this.projectileAnchor.subtract(x, y)
  if dist.y >= 0:
    # Reset projectile
    this.projectile.setLocation(this.projectileAnchor)
  else:
    # Launch projectile
    let newVelocityMagnitude = max(
      this.minProjectileVelocity,
      (dist.getMagnitude() / this.maxProjectilePullBackDistance) * this.maxProjectileVelocity
    )
    this.projectile.velocity = dist.normalize(newVelocityMagnitude)
    this.projectileHasBeenFired = true

proc onFingerDrag(this: GameLayer, x, y: float) =
  if this.projectileHasBeenFired:
    return

  this.touchLoc.x = x
  this.touchLoc.y = y

  if this.projectile != nil:
    let dist = vector(
      x - this.projectileAnchor.x,
      max(0, y - this.projectileAnchor.y)
    ).maxMagnitude(this.maxProjectilePullBackDistance)

    this.projectile.setLocation(this.projectileAnchor + dist)

proc resetProjectile(this: GameLayer) =
  if this.projectile != nil:
    this.removeChild(this.projectile)
  
  this.projectile = newHexagon(getRandomHexagonColor(), this.gameobjectsScalar)
  this.projectile.setLocation(this.projectileAnchor)
  this.projectileBounces = 0
  this.projectileHasBeenFired = false

proc resetGame(this: GameLayer) =
  this.score = 0
  let gridWidthInPixels = widthInPixels(columns, rows, gridPadding)
  this.gameobjectsScalar = (gamestate.resolution.x - paddingFromSides.x * 2) / gridWidthInPixels
  this.grid = createRandomHexagonGrid(columns, rows, gridPadding, this.gameobjectsScalar)
  this.grid.location = paddingFromSides
  
  this.resetProjectile()

proc renderIndicator(this: GameLayer, ctx: Target) =
  when isMobile:
    discard setLineThickness(4.0)
  else:
    discard setLineThickness(2.0)

  ctx.line(
    0,
    this.projectileAnchor.y,
    this.projectileAnchor.x - indicatorCircleRadius,
    this.projectileAnchor.y,
    transparentWhite
  )

  ctx.line(
    this.projectileAnchor.x + indicatorCircleRadius,
    this.projectileAnchor.y,
    gamestate.resolution.x,
    this.projectileAnchor.y,
    transparentWhite
  )

  ctx.circle(
    this.projectileAnchor.x,
    this.projectileAnchor.y,
    indicatorCircleRadius,
    transparentWhite
  )

proc renderLineToAnchor(this: GameLayer, ctx: Target) =
  const lineThickness =
    when isMobile:
      8.0
    else:
      4.0

  if not this.projectileHasBeenFired:
    discard setLineThickness(lineThickness)
    ctx.circleFilled(
      this.projectileAnchor.x,
      this.projectileAnchor.y,
      lineThickness * 0.5,
      slingshotLineColor
    )

    ctx.line(
      this.projectileAnchor.x,
      this.projectileAnchor.y,
      this.projectile.x,
      this.projectile.y,
      slingshotLineColor
    )

method update*(this: GameLayer, deltaTime: float) =
  procCall update(Layer this, deltaTime)
  if this.projectile != nil:
    this.projectile.update(deltaTime)

GameLayer.renderAsChildOf(Layer):
  this.background.render(ctx)
  if this.grid != nil:
    this.grid.render(ctx, offsetX, offsetY)

  this.renderIndicator(ctx)

  if this.projectile != nil:
    this.renderLineToAnchor(ctx)
    this.projectile.render(ctx)

