import sdl2, sdl2/image, sdl2/ttf, sdl2/mixer, sdl2/audio

discard image.init(IMG_INIT_PNG)
discard ttfinit()
discard mixer.init(MIX_INIT_MP3)

discard openAudio(22050, AUDIO_S16LSB, 2, 640)

let 
  music = loadMUS("resources/sounds/music.wav")
  jumpSound = loadWAV("resources/sounds/jump.mp3")

discard playMusic(music, -1)

const
  screenWidth = 800
  screenHeight = 400

proc isColliding(r1, r2: Rect): bool = 
  return r1.x + r1.w >= r2.x and 
  r1.x <= r2.x + r2.w and r1.y + r1.h >= r2.y and 
  r1.y <= r2.y + r2.h

var
  window: WindowPtr
  render: RendererPtr
  event: Event = defaultEvent
  runningGame: bool = true
  welcomeScreen: bool = true
  startTime: uint32 = 0

window = createWindow("SDL-Nim", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, screenWidth, screenHeight, 0)
render = createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync)

#sky
var
  skySurface: SurfacePtr = load("resources/graphics/Sky.png")
  skyTexture: TexturePtr = createTextureFromSurface(render, skySurface)
  skyRect: sdl2.Rect = rect(0, 0, screenWidth, skySurface.h)
freeSurface(skySurface)

#ground
var
  groundSurface: SurfacePtr = load("resources/graphics/ground.png")
  groundTexture: TexturePtr = createTextureFromSurface(render, groundSurface)
  groundRect: sdl2.Rect = rect(0, skySurface.h, screenWidth, groundSurface.h)

freeSurface(groundSurface)

#snail 
var
  snailSurface: SurfacePtr = load("resources/graphics/snail/snail1.png")
  snailTexture: TexturePtr = createTextureFromSurface(render, snailSurface)
  snailGround = groundRect.y - snailSurface.h
  snailRect: sdl2.Rect = rect(750, snailGround, snailSurface.w, snailSurface.h)
freeSurface(snailSurface)

#character 
var
  walkSurface: SurfacePtr = load("resources/graphics/Player/player_walk_1.png")
  walk2Surface: SurfacePtr = load("resources/graphics/Player/player_walk_2.png")
  jumpSurface: SurfacePtr = load("resources/graphics/Player/jump.png")
  walkTexture: TexturePtr = createTextureFromSurface(render, walkSurface)
  walk2Texture: TexturePtr = createTextureFromSurface(render, walk2Surface)
  jumpTexture: TexturePtr = createTextureFromSurface(render, jumpSurface)
  playerWalk: array[2, TexturePtr] = [walkTexture, walk2Texture]
  playerIndex: float32 = 0
  charGround = groundRect.y - walkSurface.h
  charRect: sdl2.Rect = rect(50, charGround, walkSurface.w, walkSurface.h)
  playerGravity: cint = 0
freeSurface(walkSurface)
freeSurface(walk2Surface)
freeSurface(jumpSurface)

proc playerAnimation(): TexturePtr  =
  if charRect.y + charRect.h < charGround:
    result = jumpTexture
  else:
    playerIndex += 0.1
    if playerIndex >= playerWalk.len().float:
      playerIndex = 0
    result = playerWalk[playerIndex.int]
    

#font
var
  font: FontPtr = openFont("resources/font/Pixeltype.ttf", 64)
  fontSurface: SurfacePtr
  fontTexture: TexturePtr
  fontRect: Rect

proc updateScore() = 
  var score = $(getTicks() div 1000 - startTime)
  fontSurface = renderTextSolid(font, score.cstring, color(0, 0, 0, 255))
  fontTexture = createTextureFromSurface(render, fontSurface)
  fontRect = rect(screenWidth div 2 - fontSurface.w div 2, 20, 32, 32)
  freeSurface(fontSurface)

while runningGame:
  while pollEvent(event):
    if event.kind == QuitEvent:
      runningGame = false
  
    if welcomeScreen:
      if event.kind == KeyDown and event.key.keysym.sym == K_SPACE:
        welcomeScreen = false
        startTime = getTicks() div 1000
        snailRect.x = 750
    else:
      if event.kind == KeyDown:
          if (event.key.keysym.sym == K_SPACE or event.key.keysym.sym == K_UP) and charRect.y == charGround:
            playerGravity = -22
            discard playChannel(-1, jumpSound, 0)

  if welcomeScreen:
    render.setDrawColor(94, 129, 162, 255)
    render.clear()
    var iconRect = rect(screenWidth div 2 - charRect.w, screenHeight div 2 - charRect.h, charRect.w * 2, charRect.h * 2)
    var titleSurface: SurfacePtr = renderTextSolid(font, "Pixel Runner", color(111, 196, 169, 255))
    var subSurface: SurfacePtr = renderTextSolid(font, "Press space to start", color(111, 196, 169, 255))
    var titleRect = rect(screenWidth div 2 - titleSurface.w div 2 , 20, 256, 64)
    var subRect = rect(screenWidth div 2 - titleSurface.w div 2 , screenHeight - 80, 256, 64)
    copy(render, loadTexture(render,"resources/graphics/Player/player_stand.png"), nil, iconRect.addr)
    copy(render, createTextureFromSurface(render, titleSurface), nil, titleRect.addr)
    copy(render, createTextureFromSurface(render, subSurface), nil, subRect.addr)
    render.present()

  else:
    updateScore()
    snailRect.x -= 4
    
    if snailRect.x < - snailRect.w:
      snailRect.x = 750
    
    playerGravity += 1
    charRect.y += playerGravity

    if charRect.y >= charGround:
      charRect.y = charGround

    welcomeScreen = isColliding(charRect, snailRect)

    copy(render, skyTexture, nil, skyRect.addr)
    copy(render, groundTexture, nil, groundRect.addr)
    copy(render, fontTexture, nil, fontRect.addr)
    copy(render, playerAnimation(), nil, charRect.addr)
    copy(render, snailTexture, nil, snailRect.addr)
    render.present()

freeChunk(jumpSound)
freeMusic(music)
close(font)
destroy(window)
destroy(render)
mixer.quit()
image.quit()
sdl2.quit()
