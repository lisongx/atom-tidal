'use babel';

class ConsoleView {
    constructor(serializeState) {
        this.tidalConsole = null;
        this.log = null;
    }

    initUI() {
        this.tidalConsole = document.createElement('div');
        this.tidalConsole.classList.add('tidalcycles', 'console');

        this.log = document.createElement('div');
        this.tidalConsole.appendChild(this.log);

        atom.workspace.addBottomPanel({
            item: this.tidalConsole
        });
    }

    serialize() {

    }

    destroy() {
        this.tidalConsole.remove();
    }

    logStdout(text) {
        this.logText(text);
    }

    logStderr(text) {
        this.logText(text);
    }
    logText(text) {
        if (!text) return;
        this.tidalConsole.scrollTop = this.tidalConsole.scrollHeight;
        var textNode = document.createElement("span");
        textNode.innerHTML = text.replace('\n', '<br/>');
        this.log.appendChild(textNode);
    }
}

export default ConsoleView;
