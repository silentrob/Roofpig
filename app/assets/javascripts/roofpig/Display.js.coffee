#= require three.min
#= require roofpig/Alg
#= require roofpig/DomHandler
#= require roofpig/InputHandler
#= require roofpig/Move
#= require roofpig/Pieces3D
#= require roofpig/Settings

class @Display
  @unique_id = 0

  constructor: (roofpig_div) ->
    @id = Display.unique_id += 1

    @input_handler = new InputHandler(this)
    @settings = new Settings(roofpig_div)
    @renderer = new THREE.WebGLRenderer({ antialias: true })
#    @renderer = new THREE.CanvasRenderer()
    @dom_handler = new DomHandler(@id, roofpig_div, @renderer)
    @camera = new Camera(@settings.hover)
    @scene = new THREE.Scene()
    @pieces3d = new Pieces3D(@scene, @settings)
    @alg = new Alg(@settings.alg, @dom_handler).premix(@pieces3d)

    @changers = {}
    this.force_render()

    this.animate()

  # this function is executed on each animation frame
  animate: ->
    now = (new Date()).getTime()

    for own category, changer of @changers
      if changer
        changer.update(now)
        if changer.finished then @changers[category] = null
        any_change = true

    if any_change
      @renderer.render @scene, @camera.cam

    requestAnimationFrame => this.animate() # request new frame

  add_changer: (category, changer) ->
    if @changers[category] then @changers[category].finish()
    @changers[category] = changer

  next: ->
    unless @alg.at_end()
      this.add_changer('move', @alg.next_move().do(@pieces3d))

  prev: ->
    unless @alg.at_start()
      this.add_changer('move', @alg.prev_move().undo(@pieces3d))

  reset: ->
    until @alg.at_start()
      @alg.prev_move().undo(@pieces3d).finish()
    this.force_render()

  button_click: (name) ->
    switch name
      when 'play'
        this.add_changer('move', @alg.play(@pieces3d))
      when 'pause'
        @alg.stop()
      when 'next'
        this.next()
      when 'prev'
        this.prev()
      when 'reset'
        this.reset()

  force_render: ->
    this.add_changer('force_render', { finished: true, update: (now) -> })