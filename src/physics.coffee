b2World         = Box2D.Dynamics.b2World
b2Vec2          = Box2D.Common.Math.b2Vec2
b2AABB          = Box2D.Collision.b2AABB
b2BodyDef       = Box2D.Dynamics.b2BodyDef
b2Body          = Box2D.Dynamics.b2Body
b2FixtureDef    = Box2D.Dynamics.b2FixtureDef
b2Fixture       = Box2D.Dynamics.b2Fixture
b2MassData      = Box2D.Collision.Shapes.b2MassData
b2PolygonShape  = Box2D.Collision.Shapes.b2PolygonShape
b2CircleShape   = Box2D.Collision.Shapes.b2CircleShape
b2EdgeShape     = Box2D.Collision.Shapes.b2EdgeShape
b2EdgeChainDef  = Box2D.Collision.Shapes.b2EdgeChainDef
b2DebugDraw     = Box2D.Dynamics.b2DebugDraw
b2MouseJointDef = Box2D.Dynamics.Joints.b2MouseJointDef
b2Settings      = Box2D.Common.b2Settings

class Physics

  constructor: (level) ->
    @scale = level.scale.x
    @level = level
    @world = new b2World(new b2Vec2(0, -Constants.gravity), true) # gravity vector, and doSleep

    # Double default precision between wheel and ground
    b2Settings.b2_linearSlop = 0.0025;

    context = @level.ctx

    # debug initialization
    debugDraw = new b2DebugDraw()
    debugDraw.SetSprite(context)    # context
    debugDraw.SetFillAlpha(0.3)     # transparency
    debugDraw.SetLineThickness(1.0) # thickness of line
    #debugDraw.SetDrawScale(1)      # scale

    # Assign debug to world
    debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit)
    @world.SetDebugDraw(debugDraw)

    @world

  create_polygon: (vertices, name) ->
    # Create fixture
    fixDef = new b2FixtureDef()

    fixDef.shape       = new b2PolygonShape()
    fixDef.density     = 1.0
    fixDef.restitution = 0.5
    fixDef.friction    = 1.0
    fixDef.filter.groupIndex = -2

    # Create polygon
    Physics.create_shape(fixDef, vertices)

    # Create body
    bodyDef = new b2BodyDef()

    # Assign body position
    bodyDef.position.x = 0
    bodyDef.position.y = 0

    bodyDef.userData =
      name: name

    bodyDef.type = b2Body.b2_staticBody

    # Assign fixture to body and add body to 2D world
    @world.CreateBody(bodyDef).CreateFixture(fixDef)

  create_lines: (block, name) ->
    # Create body
    bodyDef = new b2BodyDef()

    # Assign body position
    bodyDef.position.x = block.position.x
    bodyDef.position.y = block.position.y

    bodyDef.userData =
      name: name

    bodyDef.type = b2Body.b2_staticBody

    # add body to the world
    body = @world.CreateBody(bodyDef)

    # assign each couple of vertices to a line
    for vertex, i in block.vertices
      # Create fixture
      fixDef = new b2FixtureDef()

      fixDef.shape       = new b2PolygonShape()
      fixDef.density     = 1.0
      fixDef.restitution = 0.5
      fixDef.friction    = 1.0
      fixDef.filter.groupIndex = -2

      # Create line (from polygon because box2Dweb cannot do otherwise)
      vertex1 = vertex
      vertex2 = if i == block.vertices.length-1 then block.vertices[0] else block.vertices[i+1]
      fixDef.shape.SetAsArray([new b2Vec2(vertex1.x, vertex1.y), new b2Vec2(vertex2.x, vertex2.y)], 2)

      # Assign fixture (line) to body
      body.CreateFixture(fixDef)

  @create_shape: (fix_def, shape, mirror = false) ->
    b2vertices = []

    if mirror == false
      for vertex in shape
        b2vertices.push(new b2Vec2(vertex.x, vertex.y))
    else
      for vertex in shape
        b2vertices.unshift(new b2Vec2(-vertex.x, vertex.y))

    fix_def.shape.SetAsArray(b2vertices)
