# Introduction

[Back to the QSP homepage](../)

QSP lets you operate your own amateur radio transceiver from a web browser: tune, change mode and band, and hear the band live, from wherever you are.

This documentation has two parts.

- **User guide.** For radio amateurs who want to put their station on QSP. It walks you through installing and running the QSP agent next to your rig, then operating from your browser. Start with [How QSP works](how-qsp-works.md), then follow [Getting started](getting-started/index.md).
- **Advanced.** For people who want to understand the pieces or run their own QSP instance: the [architecture](advanced/architecture.md), a [self-hosting quick start](advanced/self-hosting.md) and a [developer guide](advanced/developer-guide.md).

## Status of the hosted service

The hosted QSP service is **not open to the public yet**. The user guide describes how things will work with the hosted service, and some steps, such as getting an account, are provisional and done by hand for now. Nothing here means you can already sign up. If you would like to run your own instance in the meantime, see the [self-hosting quick start](advanced/self-hosting.md).

## What you need to know first

- The QSP agent runs on **Linux only**. The guide uses a Raspberry Pi with 64-bit Raspberry Pi OS as its reference setup, but any Debian-based Linux on amd64 or arm64 works the same way.
- Your radio is controlled through [Hamlib](https://hamlib.github.io/), so it must be supported by Hamlib.
