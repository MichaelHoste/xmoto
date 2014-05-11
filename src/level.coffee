b2AABB = b2.AABB
b2Vec2 = b2.Vec2

class Level

  constructor: (options) ->
    @options = options

    # Context
    @canvas = $(@options.canvas).get(0)
    @ctx    = @canvas.getContext('2d')

    # Assets manager
    @assets        = new Assets()

    # Box2D physics
    @physics       = new Physics(this)

    # Inputs
    @input         = new Input(this)

    # Camera
    @camera        = new Camera(this)

    # Listeners
    @listeners     = new Listeners(this)

    # Replay: actual run of the player
    @replay        = new Replay(this)

    # Ghosts: previous saved run of various players (included himself)
    @ghosts        = new Ghosts(this)

    # Moto (level independant)
    @moto          = new Moto(this)

    # Particles (level independant)
    @particles     = new Particles(this)

    # Level dependent objects
    @infos         = new Infos(this)
    @sky           = new Sky(this)
    @blocks        = new Blocks(this)
    @limits        = new Limits(this)
    @layer_offsets = new LayerOffsets(this)
    @script        = new Script(this)
    @entities      = new Entities(this)

    # Buffer
    @buffer        = new Buffer(this)

  load_from_file: (file_name) ->
    $.ajax({
      type:     "GET",
      url:      "#{@options.levels_path}/#{file_name}",
      dataType: "xml",
      success:  @load_level
      async:    false
      context:  @
    })

  load_level: (xml) ->
    # Level dependent objects
    @infos        .parse(xml).init()
    @sky          .parse(xml).init()
    @blocks       .parse(xml).init()
    @limits       .parse(xml).init()
    @layer_offsets.parse(xml).init()
    @script       .parse(xml).init()
    @entities     .parse(xml).init()

    # Moto and ghosts (level independant)
    @moto.init()
    @ghosts.init()

    @input.init()
    @camera.init()
    @listeners.init()

  init_canvas: ->
    @canvas_width  = parseFloat(@canvas.width)
    @canvas_height = parseFloat(@canvas.height)

  display: ->
    @init_canvas()  if not @canvas_width
    @update_timer() if not @moto.dead

    # visible screen limits of the world (don't show anything outside of these limits)
    @compute_visibility()

    @sky.display()

    # Redraw buffer if needed (the buffer is bigger than the canvas)
    # And display it (copy the right pixels from the buffer to the canvas)
    @buffer.redraw() if @buffer.redraw_needed()
    @buffer.display()

    @ctx.save()

    # initialize position of camera
    @ctx.translate(@canvas_width/2, @canvas_height/2)               # Center of canvas
    @ctx.scale(@camera.scale.x, @camera.scale.y)                    # Scale (zoom)
    @ctx.translate(-@camera.target().x, -@camera.target().y - 0.25) # Camera on moto

    # Display entities, moto and ghost (blocks etc. are already drawn from the buffer)
    @entities.display_items()
    @moto    .display()
    @ghosts  .display()

    @particles.display()

    @physics.display() if Constants.debug

    @ctx.restore()

  update_timer: (update_now = false) ->
    new_time = new Date().getTime() - @start_time

    if update_now or Math.floor(new_time/10) > Math.floor(@current_time/10)
      minutes = Math.floor(new_time / 1000 / 60)
      seconds = Math.floor(new_time / 1000) % 60
      seconds = "0#{seconds}" if seconds < 10
      cents   = Math.floor(new_time / 10) % 100
      cents   = "0#{cents}" if cents < 10
      $(@options.chrono).text("#{minutes}:#{seconds}:#{cents}")

    @current_time = new_time

  compute_visibility: ->
    @visible =
      left:   @camera.target().x - (@canvas_width  / 2) / @camera.scale.x
      right:  @camera.target().x + (@canvas_width  / 2) / @camera.scale.x
      bottom: @camera.target().y + (@canvas_height / 2) / @camera.scale.y
      top:    @camera.target().y - (@canvas_height / 2) / @camera.scale.y
    @visible.aabb = new b2AABB()
    @visible.aabb.lowerBound.Set(@visible.left,  @visible.bottom)
    @visible.aabb.upperBound.Set(@visible.right, @visible.top)

  got_strawberries: ->
    for strawberry in @entities.strawberries
      if strawberry.display
        return false
    return true

  restart: ->
    @replay = new Replay(this)

    @ghosts.reload()

    @moto.destroy()
    @moto = new Moto(this)
    @moto.init()

    @start_time   = new Date().getTime()
    @current_time = 0
    @update_timer(true)

    for entity in @entities.strawberries
      entity.display = true
