# ev3dev-arm-bbr
Behavior Based Robotics Platform for LEGO Mindstorms EV3 using ARM Assembly Language

# History
ev3dev-arm-bbr is a combination of several projects: it originated from [nxos-armdebug](https://github.com/tcwan/nxos-armdebug/), a bare-metal OS developed for the LEGO Mindstorms NXT platform, and ported to the EV3 platform using the ev3dev-c C Libraries by Vitaly Kravtsov (in4lio).

nxos-armdebug itself was based on the [NxOS](https://github.com/danderson/nxos) project started by David Anderson and others, a from-the-ground-up development of a bare-metal OS for the NXT platform. ARM Assembly Language support was added to NxOS to simplify the programming and debugging of ARM Assembly programs by TC Wan and Nicholas Schodet.

# Behavior Based Robotics
Behavior Based Robotics ([BBR](https://en.wikipedia.org/wiki/Behavior-based_robotics)) is a concept introduced by Rodney Brooks and expanded upon to support robotic systems development using low complexity devices, such as the microcontrollers found in the EV3. 

The book by Joseph L. Jones, Robot Programming: A practical guide to Behavior-Based Robotics, ISBN 0-07-142778-3, is a good introduction to the use of BBR for implementing actual robots. The BBR portion of ev3dev-arm-bbr implements the behavior/arbiter/actuator concepts to simplify the development of BBR-based robotic software.

# Getting Started
TBD