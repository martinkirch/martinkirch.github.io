# Tweaking Visual Studio Code for Python

*First publication: 14 December 2016*

As I recently became a full-time Python developer (often using the 
[Pyramid framework](https://trypyramid.com/)) I tried to find a cool IDE, and 
gave a chance to [Visual Studio Code](https://code.visualstudio.com/). 
At first I liked the editor but the Python extension suffered many glitches, 
especially with virtual environments.
A month after, my installation and workspaces are configured correctly, 
turning VS Code into a comfortable IDE. 
The relevant tweaking is not enough documented so I'm sharing here my findings.  

I'm assuming you already installed VS Code and that you're already familiar 
with the Python language and environment.
Check that the `code` command is in your `$PATH` (on a Mac you'll have to do it 
manually) and install Don Jayamanne's 
[Python extension](https://github.com/DonJayamanne/pythonVSCode).

Now let's edit your user preferences.


## Linting, correctly

Linting is 

Run `pip install pylint` in each virtual environment you work with. 
The first time, create yourself a pylint configuration file with :

```
pylint --generate-rcfile >> ~/.pylintrc
```

TODO: configuration suggestions.

It's slow, but it's great. 
I'm still trying to find how to speed up linting, 
started with:

```json
    "python.linting.pylintArgs": ["-r", "no"],
```

`pylint -r no` runs pylint without generating a report - as the output is 
parsed by the Python extension, you never see this report anyway.

## Enforcing the use of virtual environments with workspace parameters 

If you invoke `code .` from a shell in which a virtual environment has  
been activated, python invocations in VS Code will happen in this 
environment... But it's not completely reliable (because you're on a 
Mac with multiple editors in different environments, or forget to install 
pylint in your environment, or ...). 

Workspace parameters may help. 
These are proposed by the preferences menu aside the global parameters. 
These global parameters can be overriden locally,  
These are akin to per-virtual-environment parameters. 

```json
{
"python.linting.pylintPath": "/Users/martin/.virtualenvs/my_env/bin/pylint",
"python.pythonPath": "/Users/martin/.virtualenvs/my_env/bin/python"
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
    "pythonPath": "/Users/martin/.virtualenvs/my_env/bin/python",
    "program": "/Users/martin/.virtualenvs/my_env/bin/pserve",
    "cwd": "${workspaceRoot}",
    "args": [
        "-v",
        "development.ini"
    ],
    "console": "integratedTerminal",
    "debugOptions": [
        "RedirectOutput",
        "WaitOnAbnormalExit",
        "WaitOnNormalExit"
    ]
},
```

Do **not** add `--reload` to the parameters. 

## Unit tests integration

TODO : does it work better with a correct pythonPath ? 
or by setting per-environment path ?

```json
"python.unitTest.promptToConfigure":false
```

For now I'm writing each test case as a standalone runnable script, 
using the `if __name__=='__main__':` idiom, 

## Other parameters

To finish I also copy and explain the rest of my configuration, pick what you 
prefer. Hovering the property name in the settings edition panel will provide 
you explanations about what each setting does.

```json
    "workbench.editor.enablePreview": false,
    "workbench.statusBar.visible": true,
    "explorer.openEditors.dynamicHeight": false,
    "explorer.openEditors.visible": 4,
    "editor.rulers": [80],
    "window.reopenFolders": "all",
    "files.insertFinalNewline": true,
    "editor.renderLineHighlight": "all",
```

Do not show all files in the explorer panel:

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

You wil likely also add `.vscode/` to your `.gitignore` files.

For now Mako templates are not recognized, so let's highlight HTML at least:

```json
    "files.associations": {
        "*.mako" : "html"
    },
```

## Keyboard shortcuts

As a suggestion, here are my key bindings, on a french Mac keyboard. 
VS Code will show you some hints in the configuration file as you edit it, 
so non-US or Mac keyboards are easy to configure. 

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
