# Requirements

## A computer next to your rig

The QSP agent runs on **Linux only**. The reference setup in this guide is a **Raspberry Pi running 64-bit Raspberry Pi OS**. Any Debian-based Linux on a 64-bit ARM (arm64) or Intel/AMD (amd64) machine works the same way.

The computer must be on all the time you want your station to be reachable, and it needs an internet connection. It only makes outgoing connections, so no port forwarding is needed for signing in.

## A radio Hamlib can control

The agent controls your transceiver through [Hamlib](https://hamlib.github.io/). Check that your radio is in the Hamlib list and note its **Hamlib model number** (`rigctl --list` shows them). You also need a way to connect it to the computer, typically a USB or serial CAT cable.

## Audio

The agent listens to the transceiver audio through the computer's **default audio input device**. Connect your radio's audio output to a sound card input (a USB audio interface, or the radio's own USB audio) and make sure that is the default input.

## A QSP account and station

You need an agent ID and secret for your station. See [Register your station](register-station.md).

## A modern browser

To operate, use a current desktop or mobile browser with WebRTC support.
