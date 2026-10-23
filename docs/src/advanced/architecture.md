# Architecture

QSP is made of a few small components, each in its own repository under [github.com/Ham-QSP](https://github.com/Ham-QSP). This page is a map: each repository's README is the reference for that component, and is the place to look for build, configuration and API details.

The big picture is the one in [How QSP works](../how-qsp-works.md): the browser and the agent exchange audio and control **directly** over WebRTC, and the services only sign users in and introduce the two to each other.

| Component | Role | README |
|-----------|------|--------|
| **qsp-agent** | Rust daemon that runs next to the rig. Controls the transceiver through Hamlib, captures audio, connects to the signaling server and opens WebRTC sessions with browsers. | [Ham-QSP/qsp-agent](https://github.com/Ham-QSP/qsp-agent) |
| **qsp-signaling-server** | Introduces browsers and agents to each other: stations, agents and the WebSocket signaling used to set up WebRTC. | [Ham-QSP/qsp-signaling-server](https://github.com/Ham-QSP/qsp-signaling-server) |
| **qsp-authentication** | Signs users in (OpenID Connect) and issues the tokens the web client and signaling server use. | [Ham-QSP/qsp-authentication](https://github.com/Ham-QSP/qsp-authentication) |
| **qsp-web** | The web client you operate from in your browser. | [Ham-QSP/qsp-web](https://github.com/Ham-QSP/qsp-web) |
| **qsp-proto-files** | Shared Protocol Buffers definitions for the messages between components. | [Ham-QSP/qsp-proto-files](https://github.com/Ham-QSP/qsp-proto-files) |

The umbrella repository, [Ham-QSP/Qsp](https://github.com/Ham-QSP/Qsp), holds this documentation, the homepage and the [self-hosting example](self-hosting.md).

## How a session starts

1. The agent connects to the signaling server (outgoing connection) and identifies itself with its agent ID and secret.
2. You sign in to the authentication server from the web client and get a token.
3. The web client asks the signaling server for the available agents and picks yours.
4. The signaling server relays the WebRTC negotiation between the browser and the agent.
5. The browser and the agent are now connected directly. Audio and control flow between them, not through the services.

There is no TURN relay in QSP today, so both ends must be able to reach each other (see [Troubleshooting](../troubleshooting.md)).
