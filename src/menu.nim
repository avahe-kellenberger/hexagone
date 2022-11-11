import shade

import background as backgroundModule

const
  fragShaderPath = "./assets/shaders/menu_bg.frag"

type Menu* = ref object of Layer
  visible: bool
  background: Background

  uiRoot: UIComponent
  playButton: UIImage
  optionsButton: UIImage
  exitButton: UIImage

proc newMenu*(): Menu =
  result = Menu(visible: true)
  initLayer(Layer result)

  result.background = newBackground(fragShaderPath)

  result.uiRoot = newUIComponent()
  result.uiRoot.stackDirection = Vertical
  result.uiRoot.alignHorizontal = Alignment.SpaceEvenly

  let title = newUIImage("./assets/gfx/MainMenu_Title.png", FILTER_LINEAR_MIPMAP)

  result.playButton = newUIImage("./assets/gfx/MainMenu_PlayButton.png")
  result.optionsButton = newUIImage("./assets/gfx/MainMenu_OptionsButton.png")
  result.exitButton = newUIImage("./assets/gfx/MainMenu_ExitButton.png")

  title.height = title.image.h * (gamestate.resolution.x / title.image.w)
  title.margin = margin(0, gamestate.resolution.y * 0.08, 0, 0)

  result.uiRoot.addChild(title)

  let buttonContainer = newUIComponent()
  buttonContainer.height = gamestate.resolution.y * 0.35

  result.playButton.width = gamestate.resolution.x * 0.4
  result.playButton.height =
    result.playButton.image.h * (result.playButton.width.pixelValue / result.playButton.image.w)

  result.optionsButton.width = gamestate.resolution.x * 0.4
  result.optionsButton.height =
    result.optionsButton.image.h * (result.optionsButton.width.pixelValue / result.optionsButton.image.w)

  result.exitButton.width = gamestate.resolution.x * 0.4
  result.exitButton.height =
    result.exitButton.image.h * (result.exitButton.width.pixelValue / result.exitButton.image.w)

  buttonContainer.alignVertical = Alignment.SpaceEvenly
  buttonContainer.alignHorizontal = Alignment.Center

  buttonContainer.margin = margin(0, gamestate.resolution.y * 0.12, 0, 0)
  buttonContainer.addChild(result.playButton)
  buttonContainer.addChild(result.optionsButton)
  buttonContainer.addChild(result.exitButton)

  result.uiRoot.addChild(buttonContainer)

  Game.setUIRoot(result.uiRoot)

template onPlayButtonPressed*(this: Menu, body: untyped) =
  this.playButton.onPressed(body)

template onOptionsButtonPressed*(this: Menu, body: untyped) =
  this.optionsButton.onPressed(body)

template onExitButtonPressed*(this: Menu, body: untyped) =
  this.exitButton.onPressed(body)

proc setVisible*(this: Menu, visible: bool) =
  this.visible = visible
  this.uiRoot.visible = visible

Menu.renderAsChildOf(Layer):
  if this.visible:
    this.background.render(ctx)

