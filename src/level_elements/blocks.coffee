class Blocks

  constructor: (level) ->
    @level  = level
    @assets = level.assets
    @list       = [] # total list
    @back_list  = [] # background list
    @front_list = [] # front list (collisions)

  parse: (xml) ->
    xml_blocks = $(xml).find('block')

    for xml_block in xml_blocks
      block =
        id: $(xml_block).attr('id')
        position:
          x:          parseFloat($(xml_block).find('position').attr('x'))
          y:          parseFloat($(xml_block).find('position').attr('y'))
          dynamic:    $(xml_block).find('position').attr('dynamic')    == 'true'
          background: $(xml_block).find('position').attr('background') == 'true'
        usetexture:
          id:         $(xml_block).find('usetexture').attr('id').toLowerCase()
          scale:      parseFloat($(xml_block).find('usetexture').attr('scale'))
        physics:
          grip:       parseFloat($(xml_block).find('physics').attr('grip'))
        edges:
          angle:      parseFloat($(xml_block).find('edges').attr('angle'))
          materials:  []
        vertices:     []

      block.usetexture.id = 'dirt' if block.usetexture.id == 'default'

      xml_materials = $(xml_block).find('edges material')
      for xml_material in xml_materials
        material =
          name:    $(xml_material).attr('name')
          edge:    $(xml_material).attr('edge')
          color_r: parseInt($(xml_material).attr('color_r'))
          color_g: parseInt($(xml_material).attr('color_g'))
          color_b: parseInt($(xml_material).attr('color_b'))
          color_a: parseInt($(xml_material).attr('color_a'))
          scale:   parseFloat($(xml_material).attr('scale'))
          depth:   parseFloat($(xml_material).attr('depth'))

        block.edges.materials.push(material)

      xml_vertices = $(xml_block).find('vertex')
      for xml_vertex in xml_vertices
        vertex =
          x:    parseFloat($(xml_vertex).attr('x'))
          y:    parseFloat($(xml_vertex).attr('y'))
          edge: $(xml_vertex).attr('edge').toLowerCase() if $(xml_vertex).attr('edge')

        block.vertices.push(vertex)

      @list.push(block)
      if block.position.background
        @back_list.push(block)
      else
        @front_list.push(block)

    @list      .sort( sort_blocks_by_texture )
    @back_list .sort( sort_blocks_by_texture )
    @front_list.sort( sort_blocks_by_texture )

    return this

  init: ->
    # Assets
    for block in @list
      @assets.textures.push(block.usetexture.id)

    # Triangulation (for collisions in box2D)
    @triangles = triangulate(@front_list)

    # Create triangles in box2D
    for triangle in @triangles
      @level.physics.create_polygon(triangle, 'ground')

    # Init edges
    @edges = new Edges(@level, @list)

  display: (ctx) ->
    # draw back blocks before front blocks
    for block in @back_list.concat(@front_list)
      ctx.beginPath()

      for vertex, i in block.vertices
        if i == 0
          ctx.moveTo(block.position.x + vertex.x, block.position.y + vertex.y)
        else
          ctx.lineTo(block.position.x + vertex.x, block.position.y + vertex.y)

      ctx.closePath()

      ctx.save()
      ctx.scale(1.0 / 40.0, -1.0 / 40.0)
      ctx.fillStyle = ctx.createPattern(@assets.get(block.usetexture.id), 'repeat')
      ctx.fill()
      ctx.restore()

    @edges.display(ctx)

# Out of class methods
triangulate = (blocks) ->
  triangles = []
  for block in blocks
    vertices = []
    for vertex in block.vertices
      vertices.push( new poly2tri.Point(block.position.x + vertex.x, block.position.y + vertex.y ))

    Math2D.not_collinear_vertices(vertices)
    triangulation = new poly2tri.SweepContext(vertices, { cloneArrays: true })
    triangulation.triangulate()
    set_of_triangles = triangulation.getTriangles()

    for triangle in set_of_triangles
      triangles.push([ { x: triangle.points_[0].x, y: triangle.points_[0].y },
                       { x: triangle.points_[1].x, y: triangle.points_[1].y },
                       { x: triangle.points_[2].x, y: triangle.points_[2].y } ])
  triangles

# http://wiki.xmoto.tuxfamily.org/index.php?title=Others_tips_to_make_levels#Parallax_layers
sort_blocks_by_texture = (a, b) ->
  return 1  if a.usetexture.id > b.usetexture.id
  return -1 if a.usetexture.id <= b.usetexture.id
  return 0
