# Register your station

{{#include ../includes/service-host.md}}

> **Provisional process.** The hosted QSP service is not open to the public yet, and registration is done by hand for now. It is planned to become self-service later, and this page will then change.

Today, the procedure is:

1. Ask the QSP operator for an account on the service.
2. The operator creates your **station** and an **agent** for it in the service.
3. The operator gives you two values:
   - the **agent ID**, which identifies your agent;
   - the **agent secret**, which proves it is really your agent.

Keep the agent secret private, like a password. Anyone who has it can connect an agent as your station.

You will put these two values, and the service address, in the agent's configuration file in [Configure the agent](configure-agent.md).
