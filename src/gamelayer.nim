import std/random

import shade
import safeset

import
  hexagon_grid as hexagonGridModule,
  hexagon as hexagonModule,
  background as backgroundModule,
  shockwave as shockwaveModule,
  sounds as soundsModule

const
  gravity = 2000.0
  fragShaderPath = "./assets/shaders/gameplay_bg.frag"
  isMobile = defined(mobile)
  paddingFromSides = when isMobile: vector(104, 16) else: vector(52, 8)
  gridPadding = when isMobile: 4 else: 2
  columns = 6
  rows = 5
  shotsTillNewRow = columns * 4
  indicatorCircleRadius = when isMobile: 70.0 else: 35.0
  transparentWhite = newColor(255, 255, 255, 100)
  slingshotLineColor = newColor(247, 114, 41)

type
  Iterable[T] = concept i
    typeof(i.items) is T

  GameLayer = ref object of PhysicsLayer
    background: Background
    shockwave: Shockwave
    touchLoc: Vector
    score: int
    grid: HexagonGrid
    gameobjectsScalar: float
    projectileAnchor: Vector
    projectile: Hexagon
    projectileBounces: int
    projectileHasBeenFired: bool
    numShotsTaken: int
    maxProjectilePullBackDistance: float
    minProjectileVelocity: float
    maxProjectileVelocity: float
    fallingHexagons: SafeSet[Hexagon]

proc onFingerDown(this: GameLayer, x, y: float)
proc onFingerUp(this: GameLayer, x, y: float)
proc onFingerDrag(this: GameLayer, x, y: float)
proc breakFromGrid(this: GameLayer, hexagon: Hexagon, velocity: Vector): int
proc resetProjectile(this: GameLayer, color: int = -1)
proc resetGame(this: GameLayer)

proc newGameLayer*(width, height: int): GameLayer =
  result = GameLayer()
  initPhysicsLayer(PhysicsLayer result, newSpatialGrid(1, 2, width + 1), VECTOR_ZERO)
  let this = result

  # Place big rectangles outisde the viewable bounds to act as walls.
  block:
    var sideWallAABB = newCollisionShape(
      aabb(
        -50,
        -gamestate.resolution.y * 0.5,
        50,
        gamestate.resolution.y * 0.5,
      ),
      PERFECT_MATERIAL
    )
    let leftWall = newPhysicsBody(PhysicsBodyKind.STATIC, sideWallAABB)
    leftWall.setLocation(-sideWallAABB.width / 2, sideWallAABB.height / 2)
    this.addChild(leftWall)

    let rightWall = newPhysicsBody(PhysicsBodyKind.STATIC, sideWallAABB)
    rightWall.setLocation(gamestate.resolution.x + sideWallAABB.width / 2, sideWallAABB.height / 2)
    this.addChild(rightWall)

    var topWallAABB = newCollisionShape(
      aabb(
        -gamestate.resolution.x / 2,
        -50,
        gamestate.resolution.x / 2,
        50
      )
    )
    let topWall = newPhysicsBody(PhysicsBodyKind.STATIC, topWallAABB)
    topWall.setLocation(topWallAABB.width / 2, -topWall.height / 2)
    this.addChild(topWall)

  this.background = newBackground(fragShaderPath)
  this.shockwave = newShockwave()
  Game.postProcessingShader = this.shockwave

  this.projectileAnchor = vector(
    gamestate.resolution.x / 2,
    gamestate.resolution.y * 0.7
  )

  this.maxProjectilePullBackDistance = (this.projectileAnchor.x * 0.65) - HEXAGON_SIZE.y * 0.5
  this.minProjectileVelocity = gamestate.resolution.y / 3
  this.maxProjectileVelocity = gamestate.resolution.y * 1.2
  this.fallingHexagons = newSafeSet[Hexagon]()

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
    this.numShotsTaken += 1
    let newVelocityMagnitude = max(
      this.minProjectileVelocity,
      (dist.getMagnitude() / this.maxProjectilePullBackDistance) * this.maxProjectileVelocity
    )
    this.projectile.velocity = dist.normalize(newVelocityMagnitude)
    this.projectileHasBeenFired = true

proc hasHexagonGridPassedIndicator(this: GameLayer): bool =
  let gridBottom = this.grid.getLocation().y + this.grid.heightInPixels() * this.gameobjectsScalar
  return  gridBottom >= this.projectileAnchor.y - HEXAGON_SIZE.y

proc endGame(this: GameLayer) =
  # TODO: Game lost things
  this.removeChild(this.projectile)

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

proc createGridMovementTween(this: GameLayer): Tween =
  result = newTween(
    0.5,
    (
      proc(thisTween: Tween, deltaTime: float) =
        let
          gridLocY = this.grid.getLocation().y
          ratio = min(1.0, thisTween.elapsedTime / thisTween.duration)
          newY = easeInAndOutQuadratic(gridLocY, paddingFromSides.y, ratio)
        this.grid.translateY(newY - gridLocY)
    ),
    proc(thisTween: Tween) = this.removeChild(thisTween)
  )

proc onProjectileCollision(this: GameLayer, other: PhysicsBody): bool =
  if not this.projectileHasBeenFired or not(other of Hexagon):
    return

  let collidedHexagon = Hexagon other
  let cell = this.grid.indexOf(collidedHexagon)
  if cell == NULL_CELL:
    raise newException(Exception, "Collided with hexagon not in the grid!")

  let insertionCell = this.grid.getInsertionIndex(this.projectile.getLocation(), cell)
  if insertionCell == NULL_CELL:
    # When could this happen?
    return
  
  let
    insertedHexagon = newHexagon(this.projectile.color, this.gameobjectsScalar, true)
    # NOTE: Hack work-around.
    # We can't use the projectile's current velocity, because it is reflected during collision resolution.
    # We can't simply invert it, because it seems to be incorrect sometimes (at least the x component).
    # i.e. the x component becomes flipped when it should not, _sometimes_.
    projectileVel = this.projectile.lastMoveVector * 60

  let projectileScreenCoord = vector(
    this.projectile.x / gamestate.resolution.x,
    this.projectile.y / gamestate.resolution.y
  )

  this.resetProjectile()

  this.grid.setHexagon(insertionCell.x, insertionCell.y, insertedHexagon)
  this.addChild(insertedHexagon)

  if this.breakFromGrid(insertedHexagon, projectileVel) > 0:
    hexagonBreakSfx.play()
    # Start shockwave animation!
    this.shockwave.center = projectileScreenCoord
    this.shockwave.playAnimation()
  else:
    hexagonClickSfx.play()

  if this.hasHexagonGridPassedIndicator():
    # Player has lost the game
    this.endGame()
    return

  # Check if we need to make a new row at top
  if this.numShotsTaken >= shotsTillNewRow:
    for hexagon in this.grid.addRandomRowAtTop(columns, this.gameobjectsScalar):
      this.addChild(hexagon)
    this.addChild(this.createGridMovementTween())
    this.numShotsTaken = 0

proc dropFromGrid(this: GameLayer, hexagons: Iterable[Hexagon]) =
  let tween: Tween = newTween(
    1.0,
    (
      proc(thisTween: Tween, deltaTime: float) =
        for hexagon in hexagons:
          hexagon.alpha = 1.0 - min(1.0, thisTween.elapsedTime / thisTween.duration)
    ),
    proc(thisTween: Tween) =
      this.removeChild(thisTween)
      for hexagon in hexagons:
        this.fallingHexagons.remove(hexagon)
  )
  this.addChild(tween)

  for hexagon in hexagons:
    this.removeChild(hexagon)
    discard this.grid.removeHexagon(hexagon)
    this.fallingHexagons.add(hexagon)

proc random(v1, v2: float): float =
  if v1 >= 0:
    rand(v1 .. v2)
  else:
    rand(v2 .. v1)

proc breakFromGrid(this: GameLayer, hexagon: Hexagon, velocity: Vector): int =
  var adjacentSimilarHexagons = this.grid.floodfill(hexagon)
  if adjacentSimilarHexagons.len < 3:
    return 0

  this.dropFromGrid(adjacentSimilarHexagons)
  for hexagon in adjacentSimilarHexagons:
    hexagon.velocity = vector(
      random(velocity.x / 4, velocity.x / 2),
      random(velocity.y / 4, velocity.y / 2)
    )

  var reachableHexagons = initHashSet[Hexagon](8)
  for x in 0 ..< this.grid.width:
    this.grid.floodfill(x, 0, reachableHexagons)

  var danglers: seq[Hexagon]
  for hexagon in this.grid.values():
    if hexagon != nil and hexagon notin reachableHexagons:
      danglers.add(hexagon)
  this.dropFromGrid(danglers)

  return adjacentSimilarHexagons.len + danglers.len

proc resetProjectile(this: GameLayer, color: int = -1) =
  if this.projectile != nil:
    this.removeChild(this.projectile)
  
  this.projectile = newHexagon(
    if color < 0: getRandomHexagonColor() else: HexagonColor(color),
    this.gameobjectsScalar,
    false
  )
  this.projectile.setLocation(this.projectileAnchor)
  this.projectileBounces = 0
  this.projectileHasBeenFired = false
  this.projectile.addCollisionListener(
    proc(thisBody, other: PhysicsBody, collisionResult: CollisionResult, gravityNormal: Vector): bool =
      this.onProjectileCollision(other)

  )
  this.addChild(this.projectile)

proc resetGame(this: GameLayer) =
  this.score = 0
  let gridWidthInPixels = widthInPixels(columns, rows, gridPadding)
  this.gameobjectsScalar = (gamestate.resolution.x - paddingFromSides.x * 2) / gridWidthInPixels
  this.grid = createRandomHexagonGrid(paddingFromSides, columns, rows, gridPadding, this.gameobjectsScalar)
  # Add all grid hexagons to the physics layer.
  for hexagon in this.grid.values():
    this.addChild(hexagon)

  this.resetProjectile()

method update*(this: GameLayer, deltaTime: float) =
  procCall update(PhysicsLayer this, deltaTime)
  # Reset projectile if it goes off the bottom of the screen
  if this.projectile != nil and this.projectileHasBeenFired and this.projectile.y > gamestate.resolution.y:
    this.resetProjectile(ord this.projectile.color)

  for hexagon in this.fallingHexagons:
    hexagon.velocity.y += gravity * deltaTime
    hexagon.update(deltaTime)

  this.shockwave.update(deltaTime)

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

method render*(this: GameLayer, ctx: Target, offsetX, offsetY: float = 0) =
  this.background.render(ctx)
  this.renderIndicator(ctx)
  this.renderLineToAnchor(ctx)

  procCall render(PhysicsLayer this, ctx, offsetX, offsetY)

  for hexagon in this.fallingHexagons:
    hexagon.render(ctx, offsetX, offsetY)

