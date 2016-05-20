'use babel';

import ConsoleView from './console-view';
import Repl from './repl';

var consoleView, tidalRepl;

const TidalCycles = {
    config: {
        "ghciPath": {
            type: "string",
            default: "ghci"
        }
    },

    activate(state) {
        consoleView = new ConsoleView(state.consoleViewState);
        tidalRepl = new Repl(consoleView);
    },

    deactivate() {
        consoleView.destroy();
        tidalRepl.destroy();
    },

    serialize() {
        return {
            consoleViewState: consoleView.serialize()
        };
    }

};

export default TidalCycles
