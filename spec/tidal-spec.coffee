{WorkspaceView} = require 'atom'
#TidalCycles = require '../lib/tidalcycles'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "TidalCycles", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('tidalcycles')

  describe "when the tidalcycles:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.tidalcycles')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch atom.workspaceView.element, 'tidalcycles:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.tidalcycles')).toExist()
        atom.commands.dispatch atom.workspaceView.element, 'tidalcycles:toggle'
        expect(atom.workspaceView.find('.tidalcycles')).not.toExist()
