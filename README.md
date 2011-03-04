
ARM Simulator
=============

This project implements an ARM architecture emulator in Perl. I worked on it during 2005-2006 in an effort to learn about assembly, emulation, and ARM, and I am releasing it in case anybody finds it useful. I have no plans to continue maintaining it.

It supports most of the ARM architecture up to version 4 or so, although several important features are missing -- interrupts and MUL (multiply) come to mind. It has some support for ELF binaries and a few Linux syscalls, so it is possible to run C programs compiled with GCC. I used a version of GCC from a contemporary iPodLinux toolchain, and I know that not all GCC configurations work.

It's worth noting that this project was not originally intended to be distributed, and some parts of the source tree reflect this. Additionally, the website no longer exists, Feedfetcher-Google's behavior notwithstanding (Despite my best attempts to get it to stop, Feedfetcher-Google has been faithfully checking the RSS feed every three hours for the last five years).

I'd be interested to hear from you if this code is useful to you.

nandhp <nandhp@gmail.com>
4 March 2011

