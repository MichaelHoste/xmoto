play_level = (name) ->
  level = new Level()
  #level.load_from_file(name)

  level.load_from_file("l1.lvl")
  level.load_as_replay("replay_1383574.rpl")

  #level.load_from_file("l2813.lvl")
  #level.load_as_replay("credits.rpl")

  # Load assets for this level before doing anything else
  level.assets.load( ->
    createjs.Sound.setMute(true)
    #level.create_background_buffer()

    update = ->
      level.input.move_moto()
      level.engine_sound.play()
      level.world.Step(1.0 / 60.0, 10, 10)
      level.world.ClearForces()
      level.display(false)

    # Render 2D environment
    window.game_loop = setInterval(update, 1000 / 60)

    hide_loading()
  )

show_loading = ->
  $(".xmoto-loading").show()

hide_loading = ->
  $(".xmoto-loading").hide()

full_screen = ->
  $("#game").width($("body").width())
  $("#game").height($("body").height())
  window.onresize = ->
    $("#game").width($("body").width())
    $("#game").height($("body").height())

$ ->
  play_level($("#levels option:selected").val())

  $("#levels").on('change', ->
    show_loading()
    clearInterval(window.game_loop)
    play_level($(this).val())
  )

  #full_screen()
