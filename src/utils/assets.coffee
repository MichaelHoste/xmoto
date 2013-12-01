class Assets

  constructor: ->
    @queue    = new createjs.LoadQueue()
    @theme    = new Theme('modern.xml') # or "original.xml"

    @textures = [] # texture list
    @anims    = [] # anim list
    @effects  = [] # effect list (edge etc.)
    @moto     = [] # moto list
    @sounds   = [] # Sounds

  load: (callback) ->
    # Format list for loading
    items = []
    for item in @textures
      items.push(
        id:  item
        src: "data/Textures/Textures/#{item.toLowerCase()}"
      )
    for item in @anims
      items.push(
        id:  item
        src: "data/Textures/Anims/#{item.toLowerCase()}"
      )
    for item in @effects
      items.push(
        id:  item
        src: "data/Textures/Effects/#{item.toLowerCase()}"
      )
    for item in @moto
      items.push(
        id:  item
        src: "data/Textures/Riders/#{item.toLowerCase()}.png"
      )

    createjs.Sound.registerSound(
      id:  "PickUpStrawberry"
      src: "data/Sounds/PickUpStrawberry.ogg"
    )

    createjs.Sound.registerSound(
      id:  "Headcrash"
      src: "data/Sounds/Headcrash.ogg"
    )

    createjs.Sound.registerSound(
      id:  "EndOfLevel"
      src: "data/Sounds/EndOfLevel.ogg"
    )

    #for rpm in ['0000', '1000', '2000', '3000', '4000', '5000', '6000']
    #  createjs.Sound.registerSound(
    #    id:  "engine_#{rpm}"
    #    src: "data/Sounds/engine_#{rpm}.ogg"
    #  )

    items = @remove_duplicate_textures(items)

    @queue.addEventListener("complete", callback)
    @queue.loadManifest(items)

  # Get an asset by its name ("id")
  get: (name) ->
    @queue.getResult(name)

  remove_duplicate_textures: (array) ->
    unique = []
    for image in array
      found = false
      for unique_image in unique
        found = true if image.id == unique_image.id
      unique.push(image) if not found
    unique

  get_rider_style: (style) ->
    if style == "ghost"
      new_style =
        torso:    "ghosttorso"
        upperleg: "ghostupperleg"
        lowerleg: "ghostlowerleg"
        upperarm: "ghostupperarm"
        lowerarm: "ghostlowerarm"
        body:     "ghostbikerbody"
        wheel:    "ghostbikerwheel"
        front:    "front_ghost"
        rear:     "rear_ghost"
        ugly_rider_color: "#008800"
        ugly_moto_color: "#880000"
      return new_style
    if style == "player"
      new_style =
        torso:    "playertorso"
        upperleg: "playerupperleg"
        lowerleg: "playerlowerleg"
        upperarm: "playerupperarm"
        lowerarm: "playerlowerarm"
        body:     "playerbikerbody"
        wheel:    "playerbikerwheel"
        front:    "front1"
        rear:     "rear1"
        ugly_rider_color: "#00FF00"
        ugly_moto_color: "#FF0000"
      return new_style


