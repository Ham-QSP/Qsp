# How QSP works

QSP has two ends that matter to you:

- **Your browser**, wherever you are.
- **The QSP agent**, a small program that runs next to your rig (for example on a Raspberry Pi), talks to your transceiver and listens to its audio.

**Your browser and the agent talk to each other directly.** Audio and radio control travel over a direct, two-way, peer-to-peer connection (WebRTC) between the two. They do not go through a QSP server.

The QSP services are only used to **sign you in** and to **introduce your browser and your agent to each other**, so that they can open that direct connection. After the introduction, the audio and control never pass through them.

<svg viewBox="0 0 760 330" role="img" aria-labelledby="hqw-title hqw-desc" style="width:100%;max-width:640px;height:auto;color:inherit" font-family="sans-serif" fill="currentColor">
  <title id="hqw-title">How QSP connects your browser to your rig</title>
  <desc id="hqw-desc">Your browser and the QSP agent next to your rig are joined by a direct, two-way, peer-to-peer connection carrying audio and control. The QSP services, drawn above in dashed lines, are only used to sign in and to introduce the browser and the agent to each other.</desc>
  <rect x="250" y="10" width="260" height="68" rx="10" fill="none" stroke="currentColor" stroke-width="2" stroke-dasharray="6 5"/>
  <text x="380" y="40" text-anchor="middle" font-size="20" font-weight="bold">QSP services</text>
  <text x="380" y="62" text-anchor="middle" font-size="15">only used to connect</text>
  <line x1="300" y1="78" x2="140" y2="190" stroke="currentColor" stroke-width="2" stroke-dasharray="6 5"/>
  <line x1="460" y1="78" x2="620" y2="190" stroke="currentColor" stroke-width="2" stroke-dasharray="6 5"/>
  <text x="205" y="125" text-anchor="end" font-size="14">sign in</text>
  <text x="555" y="125" font-size="14">sign in</text>
  <text x="380" y="125" text-anchor="middle" font-size="14">introduce browser</text>
  <text x="380" y="145" text-anchor="middle" font-size="14">and agent</text>
  <rect x="30" y="190" width="220" height="90" rx="10" fill="none" stroke="currentColor" stroke-width="2"/>
  <text x="140" y="230" text-anchor="middle" font-size="20" font-weight="bold">Your browser</text>
  <text x="140" y="254" text-anchor="middle" font-size="15">anywhere</text>
  <rect x="510" y="190" width="220" height="90" rx="10" fill="none" stroke="currentColor" stroke-width="2"/>
  <text x="620" y="230" text-anchor="middle" font-size="20" font-weight="bold">QSP agent</text>
  <text x="620" y="254" text-anchor="middle" font-size="15">next to your rig</text>
  <line x1="270" y1="235" x2="490" y2="235" stroke="currentColor" stroke-width="6"/>
  <polygon points="252,235 276,219 276,251"/>
  <polygon points="508,235 484,219 484,251"/>
  <text x="380" y="209" text-anchor="middle" font-size="16" font-weight="bold">Direct connection</text>
  <text x="380" y="272" text-anchor="middle" font-size="14">audio + control</text>
</svg>

## What this means for you

- **Your audio does not pass through QSP servers.** It goes straight between your browser and your agent.
- **Both ends must be able to reach each other.** Most home connections allow this without any setup, but some networks do not. QSP has no relay server today, so if the direct connection cannot be made, you will not get audio. See [Troubleshooting](troubleshooting.md).
- **The agent only makes outgoing connections to the QSP services.** You do not need to open a port on your router for the sign-in and introduction step.

For the technical details, see the [Architecture](advanced/architecture.md) page.
