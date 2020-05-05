title: Tweaking Visual Studio Code for Python and Pyramid
briefing: Installing and configuring VS Code for Python programming is not enough documented. Here are my findings.
date_time: 2017-01-15 16:00
slug: configuring-vs-code-for-python-pyramid
tags: python, ide, pyramid, in_english
type: post


As I recently became a full-time Python developer (often using the 
[Pyramid framework](https://trypyramid.com/)) I tried to find a cool IDE, and 
gave a chance to [Visual Studio Code](https://code.visualstudio.com/). 
At first I liked the editor but the Python extension suffered many glitches, 
especially with virtual environments.
A month after everything is configured correctly, 
turning VS Code into a comfortable IDE. 
The relevant tweaking is not enough documented so I'm sharing here my findings.

I'm assuming you already installed VS Code and that you're already familiar 
with the Python language and environment.
Check that the `code` command is in your `$PATH` (on a Mac you'll have to do it 
manually) and install Don Jayamanne's 
[Python extension](https://github.com/DonJayamanne/pythonVSCode).

## Linting, correctly

The linter is the code analyzer which will add warning and error annotations 
in your code: it's the most visible part of the Python extension.

The extension we're using relies on [pylint](https://www.pylint.org/), by default.
You should `pip install pylint` in each virtual environment you work with, 
so `pylint` will be able to find libraries correctly. 
It will check the respect of coding standards, detect syntax errors, predict runtime 
exceptions, give refactoring hints, and more. It's very useful, but the default 
configuration is very, very strict so I suggest you configure it otherwise.
You can use [my own .pylintrc file](/2017-01-15/pylintrc) or 
create your own by invoking:

    :::bash
    pylint --generate-rcfile >> ~/.pylintrc

When editing this file you may need the detailed documentation
[available here](https://pylint.readthedocs.io/en/latest/reference_guide/features.html).



## Using the right virtual environment in each workspace

Opening a folder in VS Code creates a workspace, which is analogous 
to "projects" is other IDEs. VS Code will create a `.vscode/` folder at the
workspace's root and save its stuff inside (state, debug configurations, ...).
It's also possible to define workspace parameters, which will override default 
or system-wide parameters. These are accessible in the preferences menu aside 
the system-wide parameters. 

If you invoke `code .` from a shell which has activated a virtual environment,
Python invocations in VS Code will use this 
environment... but it's not completely reliable, especially on MacOS. 
Sometimes VS Code will use system's Python, or another environment.
Workspace parameters can circumvent this. 
For example, I'm setting at least the following two in each of my workspaces:

    :::json
    {
        "python.linting.pylintPath": "/Users/martin/.virtualenvs/my_env/bin/pylint",
        "python.pythonPath": "/Users/martin/.virtualenvs/my_env/bin/python"
    }





## Debugging Pyramid applications

Before using the debugger panel of VSCode, you should add configurations.
When you open this panel in a new workspace, the "Edit 'launch.json'" button 
has a red point, suggesting you to click on it, then select one of the templates. 
Select "Python", of course.

Default configuration provides useful settings for a single Python script, 
among others. 
Pyramid applications are a bit more complicated, because `pserve` launches 
sub-processes that may run below the debugger's radar, missing your breakpoints. 
With the following configuration, you can even put breakpoints on local 
libraries:

    :::json
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

Do **not** add `--reload` to the ``args`` array. 

## Unit tests integration... or not

VS Code has the ability to detect, run and show reports on your project's 
unit test. I did not find it perticularly useful, so disabled it with:

    :::json
    "python.unitTest.promptToConfigure":false

Instead I'm writing each test case as a standalone runnable script, 
using the following snippet:

    :::python
    if __name__ == '__main__':
        unittest.main(failfast=True)

Thus I can also debug a single test case by hitting F5 while editing it.

## Other parameters

To finish I also copy and explain the rest of my configuration, pick what you 
prefer. Hovering the property name in the settings edition panel will provide 
you explanations about what each setting does.

    :::json
    "workbench.editor.enablePreview": false,
    "workbench.statusBar.visible": true,
    "explorer.openEditors.dynamicHeight": false,
    "explorer.openEditors.visible": 4,
    "editor.rulers": [80],
    "window.reopenFolders": "all",
    "files.insertFinalNewline": true,
    "editor.renderLineHighlight": "all",

Do not show all files in the explorer panel:

    :::json
    "files.exclude": {
        "**/.git": true,
        "**/.svn": true,
        "**/.hg": true,
        "**/.DS_Store": true,
        ".idea": true,
        "**/*.pyc": true,
    },

You wil likely also add `.vscode/` to your `.gitignore` files.

For now Mako templates are not recognized, so let's highlight HTML at least:

    :::json
    "files.associations": {
        "*.mako" : "html"
    },

## Keyboard shortcuts

As a suggestion, here are my key bindings (on a Mac keyboard). 
VS Code will show you some hints in the configuration file as you edit it, 
so non-US or Mac keyboards are easy to configure. 

    :::json
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

`cmd+g` is definitely my favorite.

A final remark: you can start block editing by holding `Shift+Alt` while selecting.

Enjoy!

