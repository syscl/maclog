Get system log from macOS(10.12+) much easier
============

macOS Sierra introduced a new mechanism for both application and system level logging.
Thus we can no longer get system.log from /var/log/system.log.
Which made developer's debugging life further from innocence.
That's why I started this project to just simply log all of system.log to console.
More functionality will be added later, if you have a good idea for this project, don't hesitate to make a pull request for me :)

I wait for you. Wish you all enjoy this tiny but useful program.

How to use maclog?
----------------
- Download binary executable program [here](https://github.com/syscl/maclog/files/692460/maclog-v1.2.zip).
- Double left click to execute it (Note: for first time launch: ```Right Click ▶ Open```)

If you want to compile it, following the below step:
- Download the latest source code by entering the following command in a terminal window:
```sh
git clone https://github.com/syscl/maclog
```
- Build the project by typing:
```sh
cd maclog
clang maclog.m -fobjc-arc -fmodules -mmacosx-version-min=10.6 -o maclog
```

Arguments
---------
maclog default behaviour is to show all log messages of the current day.

The following arguments modify this behavior:
- `--boot`: Show log messages since last boot time.
- `--sleep`: Show log messages since last sleep time.
- `--wake`: Show log messages since last wake time.
- `--darkWake`: Show log messages since last darkWake time.
- `--stream`: Show log messages in real time.
- `--filter <query>`: Filter log messages by `<query>`

*note: The messages returned by `--boot`, `--sleep`, `--wake`, `--darkWake` can be from previous days, depending on the last time each action occurred.*

*note: The `--filter` option can be used with any other above arguments. This can be handy for sorting out certain logs.*
 

# Change Log
2017-7-19
- Fixed bug in stream mode that resulted in system log process never being killed
- Better process management
- Delete /tmp/system.log on exit
- Code improvements

2017-7-18
- Better error handling
- Better memory management
- `--stream` no longer hangs process
- Code improvements
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
