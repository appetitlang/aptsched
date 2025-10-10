## Appetit Scheduler (aptsched)
This is a simple companion application to run [Appetit](https://github.com/appetitlang/appetit) scripts according to a scheduler. While something like cron, systemd timers, or launchd could be used here, the goal of this project is to create something simple, cross-platform, and quick to get up and running. All you need is a simple JSON file to schedule multiple and recurring tasks.

Technically, this could run anything but it is designed with the Appetit interpreter in mind and scripts that may need to run on a recurring basis.

**NOTE: This is very much an early release so this may very well not work.**


### Building
The following will get you up and going:

    go build -o aptsched main.go

This will still be flagged as a development build. This doesn't change the functionality though.

#### Make Files
A conventional `Makefile` is available that lets you build platform specific builds or running `make` will build all binaries for all platforms in `dist/`.

A `Make.ps1` file sits in for Windows users who may not have `make` installed.

### Command Line Flags
| Flag | Comment |
|-----|-----|
| nostdoutlog | Prevent aptsched from logging out each execution to standard out. This doesn't prevent logging to a file though. |
| version | Print out version info. |

## Setting up Aptsched
The scheduler pulls in information from a file called `aptsched.json` that sits in the same spot as the `aptsched` binary. This file is an array of JSON objects that each have four key-value pairs:

| Key | Value | Comment |
|-----|-----|-----|
| name | The name of the task | This has no role in the execution of the scripts but, rather, serves as an easy identifier in logs or quick identification of the task. |
| interpreter | The path to the interpreter | This allows you to point specifically to the interpreter that you want to use. This needs to be a full path or resolved by your shell. |
| path | The path to the Appetit script | This needs to be a resolvable path relative to the scheduler or a full path. |
| time | The frequency with which to run the script | This value requires an integer followed by one of `h` (for hours), `m` (for minutes), and `s` (for seconds). See the examples below for how to craft valid times. |


### Starter Template
The following is a simple template that you can copy and paste into an `aptsched.json` file.

    [
        {
            "name": "",
            "interpreter": "",
            "path": "",
            "time": ""
        }
    ]


### Examples
The following `aptsched.json` would run a script every `10 seconds` (the `10s`) and the task would be called `Hello World`. Here, we've set the interpreter to `/usr/local/bin/appetit` and the path to the script to `/Users/user/helloworld.apt`.

    [
        {
            "name": "Hello World",
            "interpreter": "/usr/local/bin/appetit",
            "path": "/Users/user/helloworld.apt",
            "time": "10s"
        }
    ]

You can schedule more than one task at a time by simply adding another JSON object. Let's adapt the one above.

    [
        {
            "name": "Hello World",
            "interpreter": "/usr/local/bin/appetit",
            "path": "/Users/user/helloworld.apt",
            "time": "10s"
        },
        {
            "name": "Print Hourly Reminder",
            "interpreter": "/usr/local/bin/appetit",
            "path": "/Users/user/hourtimer.apt",
            "time": "1h"
        }
    ]

The second object here -- `Print Hourly Reminder` -- would run the `/Users/user/hourtimer.apt` through the same interpreter as before and do so every `1 hour`. Notice here that the timer is noted as `1h` for one hour. With this config, the original `Hello World` task will run every ten seconds and the `Print Hourly Reminder` script will run every one hour.

### Logging
The scheduler will log to both the console and a log file: `aptsched.log`. A typical line in the console and logfile will look like so:

    [Mon Oct  6 2025, 17:25:09] Running Hello World -> /usr/local/bin/appetit /Users/user/helloworld.apt

You can disable logging to standard out by passing the `-nostdout` flag to the scheduler.

### Quitting
There is no elegant way to shut the scheduler down at this point so you will need to send an interrupt signal (ie. Ctrl-C).


## LICENCE
Copyright 2025 Bryan Smith.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.