Get system log from macOS(10.12+) much easier
============

Well as the arrival of macOS Sierra, we can no more get system.log from
/var/log/system.log. Which made developers' life innocence for further
debugging. That's why I start this project to just simply log all the system.log
to console. More functions will be added later, if you have good idea for this project,
don't hesitate to pull issue for me :)

I wait for you. Wish you all enjoy this tiny but useful program.

How to use maclog?
----------------
- Download binary exectuable program [here] (https://github.com/syscl/maclog/files/691679/maclog-v1.1.zip)
- Double left click to execute it(Note: for first time launch: ```Right Click``` ▶ ```Open```)

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

# Change Log
2017-1-7

- Release v1.0 binary executable program
- Release source code
