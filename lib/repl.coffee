fs = require('fs')
spawn = require('child_process').spawn

{Range} = require 'atom'
{$} = require 'atom-space-pen-views'

CONST_LINE = 'line'
CONST_MULTI_LINE = 'multi_line'

bootFilePath = __dirname + "/BootTidal.hs"

module.exports =
class REPL
  repl = null

  constructor: (serializeState) ->
    atom.workspaceView.command 'tidal:boot', => @start()
    atom.commands.add 'atom-text-editor',
      'tidal:eval': => @eval(CONST_LINE)
      'tidal:eval-multi-line': => @eval(CONST_MULTI_LINE)

  editorIsTidal: ->
   editor = @getEditor()
   editor and editor.getGrammar().scopeName is 'source.tidal'

  doSpawn: ->
    @repl = spawn(@getGhciPath(), ['-XOverloadedStrings'])
    @repl.stdout.on('data', (data) -> console.log(data.toString('utf8')))
    @repl.stderr.on('data', (data) -> console.log(data.toString('utf8')))

  getGhciPath: ->
    path = atom.config.get('tidal.ghciPath')

    if not fs.existsSync(path)
      throw "Your ghci path is not valid"
    path

  initTidal: ->
    commands = fs.readFileSync(bootFilePath).toString().split('\n')

    (@tidalSendLine(command) for command in commands)

  stdinWrite: (command) ->
    @repl.stdin.write(command)

  tidalSendLine: (command) ->
    @stdinWrite(command)
    @stdinWrite('\n')

  tidalSendExpression: (expression) ->
    @tidalSendLine(':{')
    (@tidalSendLine(e) for e in expression.split('\n'))
    @tidalSendLine(':}')

  start: ->
    @doSpawn()
    @initTidal()

  getEditor: ->
    atom.workspace.getActiveEditor()

  eval: (evalType) ->
    return unless @repl
    return unless @editorIsTidal()
    [expression, range] = @currentExpression(evalType)
    @evalWithRepl(expression, range)

  evalWithRepl: (expression, range)->
    return unless expression

    doIt = () =>
      if range?
        unflash = @evalFlash(range)

      onSuccess = () ->
        unflash?('eval-success')

      onError = (error) =>
        if error.type is 'SyntaxError'
          unflash?('eval-syntax-error')
          if path
            # offset syntax error by position of selected text in file
            row = range.getRows()[0] + error.error.line
            col = error.error.charPos
            @openToSyntaxError(path, parseInt(row), parseInt(col))
        else
          # runtime error
          unflash?('eval-error')
      @tidalSendExpression(expression)
      onSuccess()
    doIt()

  destroy: ->
    @repl.kill()

  currentExpression: (evalType) ->
    editor = @getEditor()
    return unless editor?

    selection = editor.getLastSelection()
    expression = selection.getText()

    if expression
      range = selection.getBufferRange()
      [expression, range]
    else
      switch evalType
        when CONST_LINE then @getLineExpression(editor)
        when CONST_MULTI_LINE then @getMultiLineExpression(editor)

  getLineExpression: (editor) ->
    pos = editor.getCursorBufferPosition()
    row = editor.getCursorScreenRow()

    if row?
      range = new Range([row, 0], [row + 1, 0])
      expression = editor.lineForBufferRow(row)
    else
      range = null
      expression = null
    [expression, range]

  getMultiLineExpression: (editor) ->
    range = editor.getCurrentParagraphBufferRange()
    expression = range and editor.getTextInBufferRange(range)
    [expression, range]

  evalFlash: (range) ->
    editor = @getEditor()
    marker = editor.markBufferRange(range, invalidate: 'touch')

    decoration = editor.decorateMarker(
      marker,
      type: 'line',
      class: "eval-flash"
    )
    # return fn to flash error/success and destroy the flash

    (cssClass) ->
      decoration.update(type: 'line', class: cssClass)
      destroy = ->
        marker.destroy()
      setTimeout(destroy, 120)
