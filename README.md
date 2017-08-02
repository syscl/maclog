Maclog
======

[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)

> Get system log from macOS much easier for debugging

macOS Sierra introduced a new mechanism for both application and system level logging.
Thus we can no longer get system.log from /var/log/system.log.
Which made developer's debugging life further from innocence.
That's why I started this project to just simply log all of system.log to console.
More functionality will be added later, if you have a good idea for this project, don't hesitate to make a pull request for me :)

I wait for you. Wish you all enjoy this tiny but useful program.

Install
-------
- Download binary executable program [here](https://github.com/syscl/maclog/files/692460/maclog-v1.2.zip).
- Double left click to execute it (Note: for first time launch: ```Right Click ▶ Open```)

If you want to compile it, follow these step in a terminal window:
- Download the latest source code by entering the following command:
```sh
git clone https://github.com/syscl/maclog
```
- Change to project directory:
```sh
cd maclog
```
- Build the project:
```sh
clang src/*.c -Os -Iinclude -fobjc-arc -fmodules -mmacosx-version-min=10.6 -o maclog
```
- Or if you have Xcode installed:
```sh
xcodebuild
```

Usage
-----
### CLI
```
USAGE: maclog [--version|-v] [--help|-h]
USAGE: maclog [log mode] [filter]
```

#### Arguments:
  - `--help`, `-h`: Show maclog help info.
  - `--version`, `-v`: Show maclog version info.
  - Log Modes:
    - `--boot`, `-b`: Show log messages since last boot time.
    - `--darkWake`, `-d`: Show log messages since last darkWake time.
    - `--sleep`, `-s`: Show log messages since last sleep time.
    - `--stream`, `-S`: Show log messages in real time.
    - `--wake`, `-w`: Show log messages since last wake time.
  - Filter:
    - `--filter`, `-f`: Show log messages filtered by the <query>.
    - `--filterMessage`, `-F`: Shorthand for `-f "eventMessage CONTAINS[c] <query>"`

*__NOTE__: The default behaviour is to show all log messages of the current day.*

*__NOTE__: The messages returned by `--boot`, `--sleep`, `--wake`, `--darkWake` can be from previous days, depending on the last time each action occurred.*

*__NOTE__: The `--filter` option can be used with any other above arguments. This can be handy for sorting out certain logs.*

Change Log
----------
2017-8-1
- Fixes filter's "Failed to allocate memory" bug on default mode
- Fixed clang build command
- Bump version to v1.7 (c) @HeavenVolkoff

2017-7-27
- Code organization overhaul
- Added `--filterMessage` option 
- Added License file
- Cleaner process management

2017-7-19
- Better error handling
- Better memory management
- No longer hangs process on `--stream` mode 
- Open a new instance of Console.app for each `maclog` execution
- Prevents multiple instances of `maclog` from executing and altering the same file
- Delete /tmp/system.log on exit

2017-7-18
- Better parsing of command line arguments
- Fixed sizeof filter bug
- Bump version to v1.6 (c) @MuntashirAkon @HeavenVolkoff 

2017-7-17
- Added `--filter` option
- Added help in case of providing an invalid argument
- Code improvements 

2017-6-22
- Added `--stream` option
- Added .xcodeproj file
- Some code improvements

2017-6-21

- Added `--sleep`, `--wake`, `--darkWake`  options
- Added `char *gPowerManagerDomainTime(const char *domain)`
- Added Power Management's ASL keys definitions
- Changed error handling logic in `char *gBootTime(void)`
- Bump version to v1.4 (c) @HeavenVolkoff 


2017-6-20

- Added `--boot` option
- Added `char *gBootTime(void)`
- Removed some unneeded headers

2017-1-8

- Release v1.2 binary executable program credit @schdt899 @smolderas @BreBo
- Add *gCurTime(void)
- Remove strdup(char *)
- Optimize code 

2017-1-7

- Release v1.0 binary executable program
- Release source code

## License
[![Creative Commons Licence](https://i.creativecommons.org/l/by-nc/4.0/88x31.png)](https://creativecommons.org/licenses/by-nc/4.0/)

Maclog by [syscl](https://github.com/syscl/maclog) is licensed under a [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/).
