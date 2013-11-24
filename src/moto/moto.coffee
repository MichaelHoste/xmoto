b2Vec2              = Box2D.Common.Math.b2Vec2
b2BodyDef           = Box2D.Dynamics.b2BodyDef
b2Body              = Box2D.Dynamics.b2Body
b2FixtureDef        = Box2D.Dynamics.b2FixtureDef
b2Fixture           = Box2D.Dynamics.b2Fixture
b2PolygonShape      = Box2D.Collision.Shapes.b2PolygonShape
b2CircleShape       = Box2D.Collision.Shapes.b2CircleShape
b2PrismaticJointDef = Box2D.Dynamics.Joints.b2PrismaticJointDef
b2RevoluteJointDef  = Box2D.Dynamics.Joints.b2RevoluteJointDef

class Moto

  constructor: (level, mirror = false) ->
    @level    = level
    @assets   = level.assets
    if mirror then @mirror = -1 else @mirror = 1
    @rider    = new Rider(level, this)
    @dead     = false

  destroy: ->
    world = @level.world

    @rider.destroy()

    world.DestroyBody(@body)
    world.DestroyBody(@left_wheel)
    world.DestroyBody(@right_wheel)
    world.DestroyBody(@left_axle)
    world.DestroyBody(@right_axle)

    world.DestroyJoint(@left_revolute_joint)
    world.DestroyJoint(@left_prismatic_joint)
    world.DestroyJoint(@right_revolute_joint)
    world.DestroyJoint(@right_prismatic_joint)

  display: ->
    @display_wheel(@left_wheel)
    @display_wheel(@right_wheel)
    @display_left_axle()
    @display_right_axle()
    @display_body()
    @rider.display()

  init: ->
    # Assets
    textures = [ 'playerbikerbody', 'playerbikerwheel', 'front1', 'rear1' ]
    for texture in textures
      @assets.moto.push(texture)

    # Creation of moto parts
    @player_start = @level.entities.player_start

    @body         = @create_body(@player_start.x + @mirror * Constants.body.position.x,
                                 @player_start.y + Constants.body.position.y)

    @left_wheel   = @create_wheel(@player_start.x - @mirror * Constants.wheels.position.x,
                                  @player_start.y + Constants.wheels.position.y)

    @right_wheel  = @create_wheel(@player_start.x + @mirror * Constants.wheels.position.x,
                                  @player_start.y + Constants.wheels.position.y)

    @left_axle    = @create_left_axle( @player_start.x + @mirror * Constants.left_axle.position.x,
                                       @player_start.y + Constants.left_axle.position.y)

    @right_axle   = @create_right_axle(@player_start.x + @mirror * Constants.right_axle.position.x,
                                       @player_start.y + Constants.right_axle.position.y)

    @left_revolute_joint  = @create_left_revolute_joint()
    @left_prismatic_joint = @create_left_prismatic_joint()

    @right_revolute_joint  = @create_right_revolute_joint()
    @right_prismatic_joint = @create_right_prismatic_joint()

    @rider.init()

  position: ->
    @body.GetPosition()

  create_body: (x, y)  ->
    # Create fixture
    fixDef = new b2FixtureDef()

    fixDef.shape       = new b2PolygonShape()
    fixDef.density     = Constants.body.density
    fixDef.restitution = Constants.body.restitution
    fixDef.friction    = Constants.body.friction
    fixDef.filter.groupIndex = -1

    Physics.create_shape(fixDef, Constants.body.collision_box, @mirror == -1)

    # Create body
    bodyDef = new b2BodyDef()

    # Assign body position
    bodyDef.position.x = x
    bodyDef.position.y = y

    bodyDef.userData =
      name: 'moto'

    bodyDef.type = b2Body.b2_dynamicBody

    # Assign fixture to body and add body to 2D world
    body = @level.world.CreateBody(bodyDef)
    body.CreateFixture(fixDef)

    body

  create_wheel: (x, y) ->
    # Create fixture
    fixDef = new b2FixtureDef()

    fixDef.shape = new b2CircleShape(0.35)
    fixDef.density     = Constants.wheels.density
    fixDef.restitution = Constants.wheels.restitution
    fixDef.friction    = Constants.wheels.friction
    fixDef.filter.groupIndex = -1

    # Create body
    bodyDef = new b2BodyDef()

    # Assign body position
    bodyDef.position.x = x
    bodyDef.position.y = y

    bodyDef.userData =
      name: 'moto'

    bodyDef.type = b2Body.b2_dynamicBody

    # Assign fixture to body and add body to 2D world
    wheel = @level.world.CreateBody(bodyDef)
    wheel.CreateFixture(fixDef)

    wheel

  create_left_axle: (x, y) ->
    # Create fixture
    fixDef = new b2FixtureDef()

    fixDef.shape       = new b2PolygonShape()
    fixDef.density     = Constants.left_axle.density
    fixDef.restitution = Constants.left_axle.restitution
    fixDef.friction    = Constants.left_axle.friction
    fixDef.filter.groupIndex = -1

    Physics.create_shape(fixDef, Constants.left_axle.collision_box, @mirror == -1)

    # Create body
    bodyDef = new b2BodyDef()

    # Assign body position
    bodyDef.position.x = x
    bodyDef.position.y = y

    bodyDef.userData =
      name: 'moto'

    bodyDef.type = b2Body.b2_dynamicBody

    # Assign fixture to body and add body to 2D world
    body = @level.world.CreateBody(bodyDef)
    body.CreateFixture(fixDef)

    body

  create_right_axle: (x, y) ->
    # Create fixture
    fixDef = new b2FixtureDef()

    fixDef.shape       = new b2PolygonShape()
    fixDef.density     = Constants.right_axle.density
    fixDef.restitution = Constants.right_axle.restitution
    fixDef.friction    = Constants.right_axle.friction
    fixDef.filter.groupIndex = -1

    Physics.create_shape(fixDef, Constants.right_axle.collision_box, @mirror == -1)

    # Create body
    bodyDef = new b2BodyDef()

    # Assign body position
    bodyDef.position.x = x
    bodyDef.position.y = y

    bodyDef.userData =
      name: 'moto'

    bodyDef.type = b2Body.b2_dynamicBody

    # Assign fixture to body and add body to 2D world
    body = @level.world.CreateBody(bodyDef)
    body.CreateFixture(fixDef)

    body

  create_left_revolute_joint: ->
    jointDef = new b2RevoluteJointDef()
    jointDef.Initialize(@left_axle, @left_wheel, @left_wheel.GetWorldCenter())
    @level.world.CreateJoint(jointDef)

  create_right_revolute_joint: ->
    jointDef = new b2RevoluteJointDef()
    jointDef.Initialize(@right_axle, @right_wheel, @right_wheel.GetWorldCenter())
    @level.world.CreateJoint(jointDef)

  create_left_prismatic_joint: ->
    jointDef = new b2PrismaticJointDef()
    angle = Constants.left_suspension.angle
    jointDef.Initialize(@body, @left_axle, @left_axle.GetWorldCenter(), new b2Vec2(@mirror * angle.x, angle.y))
    jointDef.enableLimit      = true
    jointDef.lowerTranslation = Constants.left_suspension.lower_translation
    jointDef.upperTranslation = Constants.left_suspension.upper_translation
    jointDef.enableMotor      = true
    jointDef.collideConnected = false
    @level.world.CreateJoint(jointDef)

  create_right_prismatic_joint: ->
    jointDef = new b2PrismaticJointDef()
    angle = Constants.right_suspension.angle
    jointDef.Initialize(@body, @right_axle, @right_axle.GetWorldCenter(), new b2Vec2(@mirror * angle.x, angle.y))
    jointDef.enableLimit      = true
    jointDef.lowerTranslation = Constants.right_suspension.lower_translation
    jointDef.upperTranslation = Constants.right_suspension.upper_translation
    jointDef.enableMotor      = true
    jointDef.collideConnected = false
    @level.world.CreateJoint(jointDef)

  display_wheel: (wheel) ->
    # Position
    position = wheel.GetPosition()

    # Radius
    radius = wheel.GetFixtureList().GetShape().m_radius

    # Angle
    angle = wheel.GetAngle()

    # Draw texture
    @level.ctx.save()
    @level.ctx.translate(position.x, position.y)
    @level.ctx.rotate(angle)

    if @level.get_render_mode() == "normal" or @level.get_render_mode() == "uglyOver"
      @level.ctx.drawImage(
        @assets.get('playerbikerwheel'), # texture
        -radius,   # x
        -radius,   # y
         radius*2, # size-x
         radius*2  # size-y
      )
    if @level.get_render_mode() == "ugly" or @level.get_render_mode() == "uglyOver"
      @level.ctx.beginPath()
      @level.ctx.strokeStyle="#FF0000"
      @level.ctx.lineWidth = 0.05
      @level.ctx.arc(0, 0, radius, 0, 2*Math.PI)
      @level.ctx.stroke()

    @level.ctx.restore()

  display_body: ->
    # Position
    position = @body.GetPosition()

    # Angle
    angle = @body.GetAngle()

    # Draw texture
    if @level.get_render_mode() == "normal" or @level.get_render_mode() == "uglyOver"
      @level.ctx.save()
      @level.ctx.translate(position.x, position.y)
      @level.ctx.scale(1*@mirror, -1)
      @level.ctx.rotate(@mirror*(-angle))
      
      @level.ctx.drawImage(
        @assets.get('playerbikerbody'), # texture
        -1.0, # x
        -0.5, # y
         2.0, # size-x
         1.0  # size-y
      )
      
      @level.ctx.restore()

  display_left_axle: ->
    axle_thickness = 0.09

    # Position
    left_wheel_position = @left_wheel.GetPosition()
    left_wheel_position =
      x: left_wheel_position.x - @mirror * axle_thickness/2.0
      y: left_wheel_position.y - 0.025

    # Position relative to center of body
    left_axle_position =
      x: -0.17 * @mirror
      y: -0.30

    # Adjusted position depending of rotation of body
    left_axle_adjusted_position = Math2D.rotate_point(left_axle_position, @body.GetAngle(), @body.GetPosition())

    # Distance
    distance = Math2D.distance_between_points(left_wheel_position, left_axle_adjusted_position)

    # Angle
    angle = Math2D.angle_between_points(left_axle_adjusted_position, left_wheel_position) + @mirror * Math.PI/2

    # Draw texture
    if @level.get_render_mode() == "normal" or @level.get_render_mode() == "uglyOver"
      @level.ctx.save()
      @level.ctx.translate(left_wheel_position.x, left_wheel_position.y)
      @level.ctx.scale(1*@mirror, -1)
      @level.ctx.rotate(@mirror*(-angle))
      
      @level.ctx.drawImage(
        @assets.get('rear1'), # texture
        0.0,               # x
        -axle_thickness/2, # y
        distance,          # size-x
        axle_thickness     # size-y
      )
      
      @level.ctx.restore()

  display_right_axle: ->
    axle_thickness = 0.07

    # Position
    right_wheel_position = @right_wheel.GetPosition()
    right_wheel_position =
      x: right_wheel_position.x + @mirror * axle_thickness/2.0 - @mirror * 0.03
      y: right_wheel_position.y - 0.045

    # Position relative to center of body
    right_axle_position =
      x: 0.52 * @mirror
      y: 0.025

    # Adjusted position depending of rotation of body
    right_axle_adjusted_position = Math2D.rotate_point(right_axle_position, @body.GetAngle(), @body.GetPosition())

    # Distance
    distance = Math2D.distance_between_points(right_wheel_position, right_axle_adjusted_position)

    # Angle
    angle = Math2D.angle_between_points(right_axle_adjusted_position, right_wheel_position) + @mirror * Math.PI/2

    # Draw texture
    if @level.get_render_mode() == "normal" or @level.get_render_mode() == "uglyOver"
      @level.ctx.save()
      @level.ctx.translate(right_wheel_position.x, right_wheel_position.y)
      @level.ctx.scale(1*@mirror, -1)
      @level.ctx.rotate(@mirror*(-angle))
      
      @level.ctx.drawImage(
        @assets.get('front1'), # texture
        0.0,               # x
        -axle_thickness/2, # y
        distance,          # size-x
        axle_thickness     # size-y
      )
      
      @level.ctx.restore()
