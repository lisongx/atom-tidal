fs = require('fs')
spawn = require('child_process').spawn


execPath = "/usr/local/bin/ghci"
bootFilePath = __dirname + "/BootTidal.hs"

module.exports =
class REPL
  repl = null

  constructor: (serializeState) ->
    console.log('start')
    @start()
    atom.commands.add 'atom-text-editor', 'tidal:eval': => @eval()

  doSpawn: ->
    @repl = spawn(execPath, ["-XOverloadedStrings"])
    @repl.stdout.on('data', (data) -> console.log(data.toString('utf8')))
    @repl.stderr.on('data', (data) -> console.log(data.toString('utf8')))    

  initTidal: ->
    commands = fs.readFileSync(bootFilePath).toString().split('\n')

    (@writeLine(command) for command in commands)

  write: (command) ->
    @repl.stdin.write(command)

  writeLine: (command)->
    @write(command)
    @write('\n')

  start: ->
    @doSpawn()
    @initTidal()

  getEditor: ->
    atom.workspace.getActiveEditor()

  eval: ->
    # return unless @editorIsSC()
    [expression, range] = @currentExpression()
    console.log('write line')
    @write(expression)
    @write('\n')
    console.log(expression)
    # @evalWithRepl(expression, @currentPath(), range)

  destroy: ->
    @repl.kill()

  currentExpression: ->
    editor = @getEditor()
    return unless editor?

    selection = editor.getLastSelection()
    expression = selection.getText()

    if expression
      range = selection.getBufferRange()
    else
     # execute the line you are on
      pos = editor.getCursorBufferPosition()
      row = editor.getCursorScreenRow()

      if row?
        range = new Range([row, 0], [row + 1, 0])
        expression = editor.lineForBufferRow(row)
      else
        range = null
        expression = null

    [expression, range]

  evalFlash: (range) ->
