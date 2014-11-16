TidalView = require './tidal-view'
Repl = require './repl'

module.exports =
  tidalView: null

  activate: (state) ->
    @tidalRepl = new Repl()
    @tidalView = new TidalView(state.tidalViewState)

  deactivate: ->
    @tidalRepl.destroy()
    @tidalView.destroy()

  serialize: ->
    tidalViewState: @tidalView.serialize()
