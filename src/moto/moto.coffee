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

  constructor: (level, ghost = false) ->
    @level  = level
    @assets = level.assets
    @world  = level.physics.world
    @mirror = 1                    # 1 = right-oriented, -1 = left-oriented
    @dead   = false
    @ghost  = ghost
    @rider  = new Rider(level, this)

  destroy: ->
    @rider.destroy()

    # physics
    @world.DestroyBody(@body)
    @world.DestroyBody(@left_wheel)
    @world.DestroyBody(@right_wheel)
    @world.DestroyBody(@left_axle)
    @world.DestroyBody(@right_axle)

    # graphics
    @level.camera.translate_container.removeChild(@body_sprite)
    @level.camera.translate_container.removeChild(@left_wheel_sprite)
    @level.camera.translate_container.removeChild(@right_wheel_sprite)
    @level.camera.translate_container.removeChild(@left_axle_sprite)
    @level.camera.translate_container.removeChild(@right_axle_sprite)

  load_assets: ->
    parts = [ Constants.body, Constants.left_wheel, Constants.right_wheel,
              Constants.left_axle, Constants.right_axle ]
    for part in parts
      if @ghost
        @assets.moto.push(part.ghost_texture)
      else
        @assets.moto.push(part.texture)

    @rider.load_assets()

  init: ->
    @init_physics_parts()
    @init_sprites()

  init_physics_parts: ->
    @player_start = @level.entities.player_start

    @body         = @create_body()
    @left_wheel   = @create_wheel(Constants.left_wheel)
    @right_wheel  = @create_wheel(Constants.right_wheel)
    @left_axle    = @create_axle(Constants.left_axle)
    @right_axle   = @create_axle(Constants.right_axle)

    @left_revolute_joint  = @create_revolute_joint(@left_axle,  @left_wheel)
    @right_revolute_joint = @create_revolute_joint(@right_axle, @right_wheel)

    @left_prismatic_joint  = @create_prismatic_joint(@left_axle,  Constants.left_suspension)
    @right_prismatic_joint = @create_prismatic_joint(@right_axle, Constants.right_suspension)

    @rider.init_physics_parts()

  init_sprites: ->
    for part in ['body', 'left_wheel', 'right_wheel', 'left_axle', 'right_axle']
      if @ghost
        asset_name = Constants[part].ghost_texture
      else
        asset_name = Constants[part].texture

      @["#{part}_sprite"] = new PIXI.Sprite.fromImage(@assets.get_url(asset_name))
      @level.camera.translate_container.addChild(@["#{part}_sprite"])

    @rider.init_sprites()

  move: (input = @level.input) ->
    moto_acceleration = Constants.moto_acceleration
    biker_force       = Constants.biker_force

    if not @dead
      # Accelerate
      if input.up
        @left_wheel.ApplyTorque(- @mirror * moto_acceleration)

      # Brakes
      if input.down
        # block wheels
        @right_wheel.SetAngularVelocity(0)
        @left_wheel.SetAngularVelocity(0)

      # Back wheeling
      if (input.left && @mirror == 1) || (input.right && @mirror == -1)
        @wheeling(biker_force)

      # Front wheeling
      if (input.right && @mirror == 1) || (input.left && @mirror == -1)
        biker_force = -biker_force * 0.8 # a bit less force for front wheeling
        @wheeling(biker_force)

      if input.space
        @flip()

    if !input.up && !input.down
      # Engine brake
      v = @left_wheel.GetAngularVelocity()
      @left_wheel.ApplyTorque((if Math.abs(v) >= 0.2 then -v/10))

      # Friction on right wheel
      v = @right_wheel.GetAngularVelocity()
      @right_wheel.ApplyTorque((if Math.abs(v) >= 0.2 then -v/100))

    # Left wheel suspension
    back_force = Constants.left_suspension.back_force
    rigidity   = Constants.left_suspension.rigidity
    @left_prismatic_joint.SetMaxMotorForce(rigidity+Math.abs(rigidity*100*Math.pow(@left_prismatic_joint.GetJointTranslation(), 2)))
    @left_prismatic_joint.SetMotorSpeed(-back_force*@left_prismatic_joint.GetJointTranslation())

    # Right wheel suspension
    back_force = Constants.right_suspension.back_force
    rigidity   = Constants.right_suspension.rigidity
    @right_prismatic_joint.SetMaxMotorForce(rigidity+Math.abs(rigidity*100*Math.pow(@right_prismatic_joint.GetJointTranslation(), 2)))
    @right_prismatic_joint.SetMotorSpeed(-back_force*@right_prismatic_joint.GetJointTranslation())

    # Drag (air resistance)
    air_density        = Constants.air_density
    object_penetration = 0.025
    squared_speed      = Math.pow(@body.GetLinearVelocity().x, 2)
    drag_force         = air_density * squared_speed * object_penetration
    @body.SetLinearDamping(drag_force)

    # Limitation of wheel rotation speed (and by extension, of moto)
    if @right_wheel.GetAngularVelocity() > Constants.max_moto_speed
      @right_wheel.SetAngularVelocity(Constants.max_moto_speed)
    else if @right_wheel.GetAngularVelocity() < -Constants.max_moto_speed
      @right_wheel.SetAngularVelocity(-Constants.max_moto_speed)

    if @left_wheel.GetAngularVelocity() > Constants.max_moto_speed
      @left_wheel.SetAngularVelocity(Constants.max_moto_speed)
    else if @left_wheel.GetAngularVelocity() < -Constants.max_moto_speed
      @left_wheel.SetAngularVelocity(-Constants.max_moto_speed)

    # Detection of drifting
    #rotation_speed = -(moto.left_wheel.GetAngularVelocity()*Math.PI/180)*2*Math.PI*Constants.left_wheel.radius
    #linear_speed   = moto.left_wheel.GetLinearVelocity().x/10
    #if linear_speed > 0 and rotation_speed > 1.5*linear_speed
    #  @level.particles.create()

  wheeling: (force) ->
    moto_angle = @mirror * @body.GetAngle()

    @body.ApplyTorque(@mirror * force * 0.50)

    force_torso   = Math2D.rotate_point({x: @mirror * (-force), y: 0}, moto_angle, {x: 0, y: 0})
    force_torso.y = @mirror * force_torso.y
    @rider.torso.ApplyForce(force_torso, @rider.torso.GetWorldCenter())

    force_leg   = Math2D.rotate_point({x: @mirror * force, y: 0}, moto_angle, {x: 0, y: 0})
    force_leg.y = @mirror * force_leg.y
    @rider.lower_leg.ApplyForce(force_leg, @rider.lower_leg.GetWorldCenter())

  flip: ->
    if not @dead
      MotoFlipService.execute(this)

  create_body: ->
    # Create fixture
    fixDef = new b2FixtureDef()

    fixDef.shape       =  new b2PolygonShape()
    fixDef.density     =  Constants.body.density
    fixDef.restitution =  Constants.body.restitution
    fixDef.friction    =  Constants.body.friction
    fixDef.isSensor    = !Constants.body.collisions
    fixDef.filter.groupIndex = -1

    Physics.create_shape(fixDef, Constants.body.shape, @mirror == -1)

    # Create body
    bodyDef = new b2BodyDef()

    # Assign body position
    bodyDef.position.x = @player_start.x + @mirror * Constants.body.position.x
    bodyDef.position.y = @player_start.y +           Constants.body.position.y

    bodyDef.userData =
      name: 'moto'
      type: if @ghost then 'ghost' else 'player'
      moto: this

    bodyDef.type = b2Body.b2_dynamicBody

    # Assign fixture to body and add body to 2D world
    body = @world.CreateBody(bodyDef)
    body.CreateFixture(fixDef)

    body

  create_wheel: (part_constants) ->
    # Create fixture
    fixDef = new b2FixtureDef()

    fixDef.shape       =  new b2CircleShape(part_constants.radius)
    fixDef.density     =  part_constants.density
    fixDef.restitution =  part_constants.restitution
    fixDef.friction    =  part_constants.friction
    fixDef.isSensor    = !part_constants.collisions
    fixDef.filter.groupIndex = -1

    # Create body
    bodyDef = new b2BodyDef()

    # Assign body position
    bodyDef.position.x = @player_start.x + @mirror * part_constants.position.x
    bodyDef.position.y = @player_start.y +           part_constants.position.y

    bodyDef.userData =
      name: 'moto'
      type: if @ghost then 'ghost' else 'player'
      moto: this

    bodyDef.type = b2Body.b2_dynamicBody

    # Assign fixture to body and add body to 2D world
    wheel = @world.CreateBody(bodyDef)
    wheel.CreateFixture(fixDef)

    wheel

  create_axle: (part_constants) ->
    # Create fixture
    fixDef = new b2FixtureDef()

    fixDef.shape       =  new b2PolygonShape()
    fixDef.density     =  part_constants.density
    fixDef.restitution =  part_constants.restitution
    fixDef.friction    =  part_constants.friction
    fixDef.isSensor    = !part_constants.collisions
    fixDef.filter.groupIndex = -1

    Physics.create_shape(fixDef, part_constants.shape, @mirror == -1)

    # Create body
    bodyDef = new b2BodyDef()

    # Assign body position
    bodyDef.position.x = @player_start.x + @mirror * part_constants.position.x
    bodyDef.position.y = @player_start.y +           part_constants.position.y

    bodyDef.userData =
      name: 'moto'
      type: if @ghost then 'ghost' else 'player'
      moto: this

    bodyDef.type = b2Body.b2_dynamicBody

    # Assign fixture to body and add body to 2D world
    body = @world.CreateBody(bodyDef)
    body.CreateFixture(fixDef)

    body

  create_revolute_joint: (axle, wheel) ->
    jointDef = new b2RevoluteJointDef()
    jointDef.Initialize(axle, wheel, wheel.GetWorldCenter())
    @world.CreateJoint(jointDef)

  create_prismatic_joint: (axle, part_constants) ->
    jointDef = new b2PrismaticJointDef()
    angle = part_constants.angle
    jointDef.Initialize(@body, axle, axle.GetWorldCenter(), new b2Vec2(@mirror * angle.x, angle.y))
    jointDef.enableLimit      = true
    jointDef.lowerTranslation = part_constants.lower_translation
    jointDef.upperTranslation = part_constants.upper_translation
    jointDef.enableMotor      = true
    jointDef.collideConnected = false
    @world.CreateJoint(jointDef)

  update: ->
    @aabb = @compute_aabb()

    if !Constants.debug_physics
      visible = @visible()

      @update_wheel(     @left_wheel,  Constants.left_wheel,  visible)
      @update_wheel(     @right_wheel, Constants.right_wheel, visible)
      @update_left_axle( @left_axle,   Constants.left_axle,   visible)
      @update_right_axle(@right_axle,  Constants.right_axle,  visible)
      @update_body(      @body,        Constants.body,        visible)

      @rider.update(visible)

  update_wheel: (part, part_constants, visible) ->
    if part_constants.position.x < 0
      wheel_sprite = @left_wheel_sprite
    else
      wheel_sprite = @right_wheel_sprite

    wheel_sprite.visible = visible

    if visible
      position = part.GetPosition()
      angle    = part.GetAngle()

      wheel_sprite.width    = 2 * part_constants.radius
      wheel_sprite.height   = 2 * part_constants.radius
      wheel_sprite.anchor.x = 0.5
      wheel_sprite.anchor.y = 0.5
      wheel_sprite.x        = position.x
      wheel_sprite.y        = -position.y
      wheel_sprite.rotation = -angle
      wheel_sprite.scale.x  = @mirror * Math.abs(wheel_sprite.scale.x)

  update_body: (part, part_constants, visible) ->
    @body_sprite.visible = visible

    if visible
      position = part.GetPosition()
      angle    = part.GetAngle()

      @body_sprite.width    = part_constants.texture_size.x
      @body_sprite.height   = part_constants.texture_size.y
      @body_sprite.anchor.x = 0.5
      @body_sprite.anchor.y = 0.5
      @body_sprite.x        = position.x
      @body_sprite.y        = -position.y
      @body_sprite.rotation = -angle
      @body_sprite.scale.x  = @mirror * Math.abs(@body_sprite.scale.x)

  update_left_axle: (part, part_constants, visible) ->
    axle_thickness = 0.09

    wheel_position = @left_wheel.GetPosition()
    wheel_position =
      x: wheel_position.x - @mirror * axle_thickness/2.0
      y: wheel_position.y - 0.025

    # Position relative to center of body
    axle_position =
      x: -0.17 * @mirror
      y: -0.30

    texture = if @ghost then part_constants.ghost_texture else part_constants.texture
    @update_axle_common(wheel_position, axle_position, axle_thickness, texture, 'left', visible)

  update_right_axle: (part, part_constants, visible) ->
    axle_thickness = 0.07

    wheel_position = @right_wheel.GetPosition()
    wheel_position =
      x: wheel_position.x + @mirror * axle_thickness/2.0 - @mirror * 0.03
      y: wheel_position.y - 0.045

    # Position relative to center of body
    axle_position =
      x: 0.52 * @mirror
      y: 0.025

    texture = if @ghost then part_constants.ghost_texture else part_constants.texture
    @update_axle_common(wheel_position, axle_position, axle_thickness, texture, 'right', visible)

  update_axle_common: (wheel_position, axle_position, axle_thickness, texture, side, visible) ->
    axle_sprite = @["#{side}_axle_sprite"]
    axle_sprite.visible = visible

    if visible
      body_position = @body.GetPosition()
      body_angle    = @body.GetAngle()

      # Adjusted position depending of rotation of body
      axle_adjusted_position = Math2D.rotate_point(axle_position, body_angle, body_position)

      # Distance
      distance = Math2D.distance_between_points(wheel_position, axle_adjusted_position)

      # Angle
      angle = Math2D.angle_between_points(axle_adjusted_position, wheel_position) + @mirror * Math.PI/2

      axle_sprite.width    = distance
      axle_sprite.height   = axle_thickness
      axle_sprite.anchor.x = 0.0
      axle_sprite.anchor.y = 0.5
      axle_sprite.x        =  wheel_position.x
      axle_sprite.y        = -wheel_position.y
      axle_sprite.rotation = -angle
      axle_sprite.scale.x  = @mirror * Math.abs(axle_sprite.scale.x)

  # estimation of aabb of moto + rider (based on wheels and head)
  compute_aabb: ->
    # lower position of wheels or head (in case or looping)
    lower1 = @left_wheel.GetFixtureList().GetAABB().lowerBound
    lower2 = @right_wheel.GetFixtureList().GetAABB().lowerBound
    lower3 = @rider.head.GetFixtureList().GetAABB().lowerBound

    # upper position of wheels or head (in case or looping)
    upper1 = @left_wheel.GetFixtureList().GetAABB().upperBound
    upper2 = @right_wheel.GetFixtureList().GetAABB().upperBound
    upper3 = @rider.head.GetFixtureList().GetAABB().upperBound

    aabb = new b2AABB()
    aabb.lowerBound.Set(Math.min(lower1.x, lower2.x, lower3.x), Math.min(lower1.y, lower2.y, lower3.y))
    aabb.upperBound.Set(Math.max(upper1.x, upper2.x, upper3.x), Math.max(upper1.y, upper2.y, upper3.y))

    return aabb

  visible: ->
    @aabb.TestOverlap(@level.camera.aabb)
