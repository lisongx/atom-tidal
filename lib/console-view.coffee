module.exports =
class ConsoleView
  constructor: (serializeState) ->

  initUI: ->
    @tidalConsole = document.createElement('div')
    @tidalConsole.classList.add('tidal', 'console')

    @log = document.createElement('div')
    @tidalConsole.appendChild(@log)

    atom.workspace.addBottomPanel({item: @tidalConsole})

  serialize: ->

  destroy: ->
    @tidalConsole.remove()

  logStdout: (text)->
    @logText(text)

  logStderr: (text)->
    @logText(text)

  logText: (text) ->
    @tidalConsole.scrollTop = @tidalConsole.scrollHeight;
    textNode = document.createElement("span");
    textNode.innerHTML = text.replace('\n', '</br>')
    @log.appendChild(textNode)
