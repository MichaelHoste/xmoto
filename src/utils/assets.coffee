class Assets

  constructor: ->
    @theme    = {}

    @textures = [] # texture list
    @anims    = [] # anim list
    @effects  = [] # effect list (edge etc.)
    @moto     = [] # moto list
    @sounds   = [] # Sounds

    @resources = {}

  parse_theme: (filename, callback) ->
    # extend to keep the same pointer to @theme that is already in other objects
    @theme = $.extend(@theme,
      new Theme('modern.xml', callback)
    )

  load: (callback) ->
    PIXI.Loader.shared.reset()

    items = []
    for item in @textures
      items.push(
        id:  item
        src: "/data/Textures/Textures/#{item.toLowerCase()}"
      )
    for item in @anims
      items.push(
        id:  item
        src: "/data/Textures/Anims/#{item.toLowerCase()}"
      )
    for item in @effects
      items.push(
        id:  item
        src: "/data/Textures/Effects/#{item.toLowerCase()}"
      )
    for item in @moto
      items.push(
        id:  item
        src: "/data/Textures/Riders/#{item.toLowerCase()}.png"
      )

    for item in @remove_duplicate_textures(items)
      PIXI.Loader.shared.add(item.id, item.src)

    PIXI.Loader.shared.load((loader, resources) =>
      @resources = resources
      callback()
    )

  # Get an asset by its name ("id")
  get: (name) ->
    @resources[name].data

  get_url: (name) ->
    @resources[name].url

  remove_duplicate_textures: (array) ->
    unique = []
    for image in array
      found = false
      for unique_image in unique
        found = true if image.id == unique_image.id
      unique.push(image) if not found
    unique
