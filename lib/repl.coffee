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
  consoleView = null

  constructor: (consoleView) ->
    @consoleView = consoleView

    atom.commands.add 'atom-workspace',
      'tidal:boot': =>
        return unless @editorIsTidal()
        @start()
    atom.commands.add 'atom-text-editor',
      'tidal:eval': => @eval(CONST_LINE, false)
      'tidal:eval-multi-line': => @eval(CONST_MULTI_LINE, false)
      'tidal:eval-copy': => @eval(CONST_LINE, true)
      'tidal:eval-multi-line-copy': => @eval(CONST_MULTI_LINE, true)
      'tidal:hush': => @hush()

  editorIsTidal: ->
   editor = @getEditor()
   editor and editor.getGrammar().scopeName is 'source.tidal'

  hush: ->
    @tidalSendExpression("hush")

  doSpawn: ->
    @repl = spawn(@getGhciPath(), ['-XOverloadedStrings'])
    @repl.stdout.on('data', (data) => @consoleView.logStdout(data.toString('utf8')))
    @repl.stderr.on('data', (data) => @consoleView.logStderr(data.toString('utf8')))

  getGhciPath: ->
    path = atom.config.get('tidal.ghciPath')
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
    @consoleView.initUI()
    @doSpawn()
    @initTidal()

  getEditor: ->
    atom.workspace.getActiveTextEditor()

  eval: (evalType, copy) ->
    return unless @editorIsTidal()

    if not @repl?
      atom.confirm
        message: "You haven't boot your tidal server!"
        buttons:
          'Boot': =>
            @start()
          'Cancel': =>
      return

    [expression, range] = @currentExpression(evalType)
    @evalWithRepl(expression, range, copy)

  evalWithRepl: (expression, range, copy)->
    return unless expression

    doIt = () =>
      if range?
        unflash = @evalFlash(range)
        copyRange = if copy then @copyRange(range)

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
    @repl?.kill()

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

  copyRange: (range) ->
    editor = @getEditor()
    endRow = range.end.row
    endRow++
    text = editor.getTextInBufferRange(range)
    text = '\n' + text + '\n'
    text = '\n' + text if endRow > editor.getLastBufferRow()
    console.log text
    editor.getBuffer().insert([endRow, 0], text)

  getLineExpression: (editor) ->
    cursor = editor.getCursors()[0]
    range =  cursor.getCurrentLineBufferRange()
    expression = range and editor.getTextInBufferRange(range)
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
      decoration.setProperties({type: 'line', class: cssClass})
      destroy = ->
        marker.destroy()
      setTimeout(destroy, 120)
