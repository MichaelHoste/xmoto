play_level = (name) ->
  level = new Level()
  #level.pause()

  #level.load_from_file(name)

  level.load_from_file("l1.lvl")
  #level.load_as_replay("replay_1383574.rpl")

  #level.load_from_file("l2813.lvl")
  #level.load_as_replay("credits.rpl")

  #level.load_from_file("l24.lvl")
  #level.load_as_replay("replay_1436520.rpl")

  # Load assets for this level before doing anything else
  level.assets.load( ->
    createjs.Sound.setMute(true)

    last_step    = new Date().getTime()
    physics_step = 1000.0/60.0

    window.cancelAnimationFrame(window.game_loop)

    update_physics = ->
      while (new Date()).getTime() - last_step > physics_step
        level.input.move()
        level.world.Step(1.0/60.0, 10, 10)
        level.world.ClearForces()
        last_step += physics_step

    update = ->
      if level.is_paused() == false
        update_physics()
        level.display(false)
      window.game_loop = window.requestAnimationFrame(update)

    update()

    hide_loading()
    # display at least one time the buffer in case the level is started in pause mode
    level.display(false)
  )

show_loading = ->
  $("#loading").show()

hide_loading = ->
  $("#loading").hide()

full_screen = ->
  window.onresize = ->
    $("#game").width($("body").width())
    $("#game").height($("body").height())
  window.onresize()

bind_select = ->
  $("#levels").on('change', ->
    show_loading()
    play_level($(this).val())
  )

select_level_from_url = ->
  level = location.search.substr(1)
  $("#levels").val(level)
  $("#levels").trigger("change")

$ ->
  bind_select()

  if location.search != ''
    select_level_from_url()
  else
    play_level($("#levels option:selected").val())

  #full_screen()
