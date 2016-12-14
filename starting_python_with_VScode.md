# First Python/Pyramid steps with VSCode

*First publication: 14 December 2016*

Let's say you're a Pyramid developer. 

## General editor parameters




```json
    "workbench.editor.enablePreview": false,
    "workbench.statusBar.visible": true,
    "explorer.openEditors.dynamicHeight": false,
    "explorer.openEditors.visible": 4,
    "editor.rulers": [80],
    "window.reopenFolders": "all",
```


```json
    "files.exclude": {
        "**/.git": true,
        "**/.svn": true,
        "**/.hg": true,
        "**/.DS_Store": true,
        ".idea": true,
        "**/*.pyc": true,
    },
```




## Linting, correctly

Linting is 

Run `pip install pylint` in each virtual environment.

It's slow, but it's great. 
I'm still trying to find how to speed up linting, 
started with:

```json
    "python.linting.pylintArgs": ["-r", "no"],
```

`pylint -r no` runs pylint without generating a report (you won't see it anyway). 

## Leveraging virtual environments with workspace parameters 

If you invoke `code .` from a shell in which a virtual environment has  
been activated, python invocations in VS Code will happen as in this 
environment... except the linter, thus all your imports may turn red, for example.

Workspace parameters come to the rescue. 
These are proposed by the preferences menu aside the global parameters. 
These global parameters can be overriden locally,  
These are akin to per-virtual-environment parameters. 

```json
{
"python.linting.pylintPath": "/Users/martin/.virtualenvs/ofre/bin/pylint",
"python.pythonPath": "/Users/martin/.virtualenvs/ofre/bin/python"
}
```


## Debugging Pyramid applications

To start using the debugger panel of VSCode, you should add configurations.
When you open this panel in a new workspace, the "Edit 'launch.json'" button 
has a red point, suggesting you to click on it using one of the templates. 
Select "Python", of course.

Default configuration provide useful settings for a single Python script, 
among others. For example, to debug a single test case, hit F5 while editing 
this case. 

Pyramid applications are a bit more complicated, because `pserve` launches 
sub-processes that may run below the debugger's radar, missing your breakpoints. 

With the following configuration, you can even put breakpoints on any local 
library your site is using:

```json
{
    "name": "Pserve",
    "type": "python",
    "request": "launch",
    "stopOnEntry": false,
    "pythonPath": "/Users/martin/.virtualenvs/ofre/bin/python",
    "program": "/Users/martin/.virtualenvs/ofre/bin/pserve",
    "cwd": "${workspaceRoot}",
    "args": [
        "-v",
        "development.ini"
    ],
    "console": "integratedTerminal",
    "debugOptions": [
        "WaitOnAbnormalExit",
        "WaitOnNormalExit"
    ]
},
```

Do **not** add `--reload` to the parameters. 

## Other parameters

For now Mako templates are not recognized. 

```json
    "files.associations": {
        "*.mako" : "html"
    },
```

## Unit tests integration

TODO : does it work better with a correct pythonPath ? 
or by setting per-environment path ?

```json
"python.unitTest.promptToConfigure":false
```

For now I'm writing each test case as a standalone runnable script, 
using the `if __name__=='__main__':` idiom, 

## Keyboard shortcuts

As a suggestion, here are my key bindings.

```json
[
{ "key": "cmd+.", "command": "editor.action.commentLine",
                    "when": "editorTextFocus && !editorReadonly" },
{ "key": "cmd+l", "command": "workbench.action.gotoLine" },
{ "key": "cmd+g", "command": "editor.action.addSelectionToNextFindMatch",
                    "when": "editorFocus" },
{ "key": "cmd+d",  "command": "editor.action.deleteLines",
                    "when": "editorTextFocus && !editorReadonly" },
{ "key": "cmd+down", "command": "editor.action.moveLinesDownAction",
                        "when": "editorTextFocus && !editorReadonly" },
{ "key": "cmd+up", "command": "editor.action.moveLinesUpAction",
                    "when": "editorTextFocus && !editorReadonly" },

{ "key": "alt+down", "command": "scrollLineDown",
                        "when": "editorTextFocus" },
{ "key": "alt+up", "command": "scrollLineUp" ,
                     "when": "editorTextFocus" },
{ "key": "cmd+shift+e", "command": "python.execSelectionInTerminal" },
{ "key": "cmd+e", "command": "python.execInTerminal" },
{ "key": "cmd+r",  "command": "python.refactorExtractVariable" },

]
```