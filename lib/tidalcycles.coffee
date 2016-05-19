ConsoleView = require './console-view'
Repl = require './repl'

module.exports =
  consoleView: null

  config:
    ghciPath:
      type: 'string'
      default: 'ghci'

  activate: (state) ->
    @consoleView = new ConsoleView(state.consoleViewState)
    @tidalRepl = new Repl(@consoleView)

  deactivate: ->
    @tidalRepl.destroy()
    @consoleView.destroy()

  serialize: ->
    consoleViewState: @consoleView.serialize()
