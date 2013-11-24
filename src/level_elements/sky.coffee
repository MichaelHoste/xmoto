class Sky

  constructor: (level) ->
    @level  = level
    @assets = level.assets

  parse: (xml) ->
    xml_sky    = $(xml).find('level info sky')
    @name      = xml_sky.text().toLowerCase()
    @color_r   = parseInt(xml_sky.attr('color_r'))
    @color_g   = parseInt(xml_sky.attr('color_g'))
    @color_b   = parseInt(xml_sky.attr('color_b'))
    @color_a   = parseInt(xml_sky.attr('color_a'))
    @zoom      = parseFloat(xml_sky.attr('zoom'))
    @offset    = parseFloat(xml_sky.attr('offset'))

    @name = 'sky1' if @name == ''

    return this

  init: ->
    @assets.textures.push(@name)

  display: (ctx) ->
    ctx.beginPath()
    ctx.moveTo(@level.canvas_width, @level.canvas_height)
    ctx.lineTo(0,                   @level.canvas_height)
    ctx.lineTo(0,                   0)
    ctx.lineTo(@level.canvas_width, 0)
    ctx.closePath()

    ctx.save()
    ctx.scale(4.0, 4.0)
    ctx.translate(-@level.moto.position().x*4, @level.moto.position().y*2)
    ctx.fillStyle = ctx.createPattern(@assets.get(@name), "repeat")
    ctx.fill()
    ctx.restore()
