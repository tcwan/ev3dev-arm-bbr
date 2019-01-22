# [ev3dev-arm-bbr](https://github.com/tcwan/ev3dev-arm-bbr)
Behavior Based Robotics Platform for LEGO Mindstorms EV3 using ARM Assembly Language

# History

The **ev3dev-arm-bbr** platform is inspired by [nxos-armdebug](https://github.com/tcwan/nxos-armdebug/), a bare-metal OS developed for the LEGO Mindstorms NXT platform. While it is not possible to port *nxos-armdebug* directly to *ev3dev* since the I/O driver model implemented for the Linux-based EV3 platform is so different, the goal of providing a structured software framework for exploring C and ARM Assembly Language programming on the EV3 platform remains the same. The I/O interfacing in *ev3dev-arm-bbr* is handled by the C-based [ev3dev-c](https://github.com/in4lio/ev3dev-c) Library developed by Vitaly Kravtsov (in4lio).

nxos-armdebug itself was based on the [NxOS](https://github.com/danderson/nxos) project started by David Anderson and others, a from-the-ground-up development of a bare-metal OS for the NXT platform. ARM Assembly Language support was added to NxOS to simplify the programming and debugging of ARM Assembly programs by TC Wan and Nicholas Schodet.

# Behavior Based Robotics

Behavior Based Robotics ([BBR](https://en.wikipedia.org/wiki/Behavior-based_robotics)) is a concept introduced by Rodney Brooks and expanded upon to support robotic systems development using low complexity devices, such as the microcontrollers found in the EV3. 

The book by Joseph L. Jones and Daniel Roth, *Robot Programming: A practical guide to Behavior-Based Robotics*, [ISBN 0-07-142778-3](https://isbnsearch.org/isbn/0071427783), is a good introduction to the use of BBR for implementing actual robots. The BBR portion of *ev3dev-arm-bbr* implements the *behavior/arbiter/actuator* concepts to simplify the development of BBR-based robotic software.

# Getting Started

TBD

# Updating dependent libraries

ev3dev-arm-bbr is dependent on the ev3dev-c library. In order to avoid breaking changes, updating of ev3dev-c is not automatic. To perform an update, the following steps must be taken:

```
run `scripts/updatelibs.sh`
$ cd ev3dev-c
Determine the latest commit from `git log`
$ git checkout <commit id> # to select the latest commit for ev3dev-c
$ `cd ..`
$ git checkin ev3dev-c # to commit updated ev3dev-c module to project
```
