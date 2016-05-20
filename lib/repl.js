var fs = require('fs')
var spawn = require('child_process').spawn

// {Range} = require 'atom'
// {$} = require 'atom-space-pen-views'

var CONST_LINE = 'line'
var CONST_MULTI_LINE = 'multi_line'

var bootFilePath = __dirname + "/BootTidal.hs"

class REPL {

    constructor(consoleView) {
        this.repl = null;
        this.consoleView = null;
        this.consoleView = consoleView;

        atom.commands.add('atom-workspace', {
            'tidalcycles:boot': function() {
                if (this.editorIsTidal()) {
                    this.start();
                }
            }
        });

        atom.commands.add('atom-text-editor', {
            'tidalcycles:eval': this.eval(CONST_LINE, false),
            'tidalcycles:eval-multi-line': this.eval(CONST_MULTI_LINE, false),
            'tidalcycles:eval-copy': this.eval(CONST_LINE, true)
            'tidalcycles:eval-multi-line-copy': this.eval(CONST_MULTI_LINE, true)
            'tidalcycles:hush': this.hush()
        });

    }

    editorIsTidal() {
        var editor = this.getEditor();
        return editor && editor.getGrammar().scopeName === 'source.tidalcycles';
    }

    hush() {
        this.tidalSendExpression("hush");
    }

    doSpawn() {
        this.repl = spawn(this.getGhciPath(), ['-XOverloadedStrings'])
        this.repl.stdout.on('data', (data) => this.consoleView.logStdout(data.toString('utf8')))
        this.repl.stderr.on('data', (data) => this.consoleView.logStderr(data.toString('utf8')))
    }

    getGhciPath() {
        var path = atom.config.get('tidalcycles.ghciPath');
        return path;
    }

    initTidal() {
        var commands = fs.readFileSync(bootFilePath).toString().split('\n');
        for (var i = 0; i < commands.length; i++) {
            this.tidalSendLine(commands[i]);
        }
    }

    stdinWrite(command) {
        this.repl.stdin.write(command);
    }

    tidalSendLine(command) {
        this.stdinWrite(command);
        this.stdinWrite('\n');
    }

    tidalSendExpression(expression) {
        this.tidalSendLine(':{');
        var splits = expression.split('\n');
        for (var i = 0; i < splits.length; i++) {
            this.tidalSendLine(splits[i]);
        }
        this.tidalSendLine(':}');
    }

    start() {
        this.consoleView.initUI();
        this.doSpawn();
        this.initTidal();
    }
    getEditor() {
        atom.workspace.getActiveTextEditor();
    }

    eval(evalType, copy) {
        if (!this.editorIsTidal()) return;

        if (!this.repl) this.start();



        var expressionAndRange = this.currentExpression(evalType);
        var expression = expressionAndRange[0];
        var range = expressionAndRange[1];
        this.evalWithRepl(expression, range, copy);
    }

    evalWithRepl(expression, range, copy) {

        if (!expression) return;

        function doIt() {
            if (range) {
                var unflash = this.evalFlash(range);
                var copyRange;
                if (copy) {
                    copyRange = this.copyRange(range);
                }
            }

            function onSuccess() {
                this.unflash('eval-success');
            }

            // this is never used ????
            // function onError(error){
            //   if (error.type === 'SyntaxError'){
            //     this.unflash('eval-syntax-error');
            //     if (path){
            //       // offset syntax error by position of selected text in file
            //       var row = range.getRows()[0] + error.error.line;
            //       var col = error.error.charPos;
            //       this.openToSyntaxError(path, parseInt(row), parseInt(col));
            //     }
            //     else{
            //       // syntax error
            //       this.unflash.('eval-error');
            //     }
            //   }
            // }

            this.tidalSendExpression(expression);
            onSuccess();
        }

        doIt();
    }

    destroy() {
        if (this.repl) {
            this.repl.kill();
        }
    }

    currentExpression(evalType) {

        var editor = this.getEditor();
        if (!editor) return;


        var selection = editor.getLastSelection();
        var expression = selection.getText();

        if (expression) {
            var range = selection.getBufferRange();
            return [expression, range];
        } else {
            if (evalType === CONST_LINE) {
                return this.getLineExpression(editor);
            }
            return this.getMultiLineExpression(editor);
        }
    }

    copyRange(range) {
        var editor = this.getEditor();
        var endRow = range.end.row;
        endRow++
        var text = editor.getTextInBufferRange(range);
        text = '\n' + text + '\n';

        if (endRow > editor.getLastBufferRow()) {
            text = '\n' + text
        }
        console.log(text);
        editor.getBuffer().insert([endRow, 0], text);
    }

    getLineExpression(editor) {
        var cursor = editor.getCursors()[0];
        var range = cursor.getCurrentLineBufferRange();
        var expression = range && editor.getTextInBufferRange(range); // ???
        return [expression, range];
    }

    getMultiLineExpression(editor) {
        var range = editor.getCurrentParagraphBufferRange();
        //var expression = range and editor.getTextInBufferRange(range)[expression, range]
        var expression = editor.getTextInBufferRange(range);
        return [expression, range];
    }

    evalFlash(range) {
        var editor = this.getEditor();
        var marker = editor.markBufferRange(range, {
            invalidate: 'touch'
        });

        var decoration = editor.decorateMarker({
            marker,
            type: 'line',
            class: "eval-flash"
        }); // return fn to flash error / success and destroy the flash

        return function(cssClass) {
            decoration.setProperties({
                type: 'line',
                class: cssClass
            });
            var destroy = function() {
                marker.destroy();
            };
            setTimeout(destroy, 120);
        };
    }
}

export default REPL;
