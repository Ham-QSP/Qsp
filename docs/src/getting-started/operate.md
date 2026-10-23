# Operate from your browser

{{#include ../../includes/service-host.md}}

Once your agent is running and connected, you operate your station from the QSP web client in any browser.

1. Open the QSP web client at the address of the service, `https://<service-host>`, and sign in with your QSP account.
2. Your station appears in the list of available agents when its agent is connected. Select it.
3. Your browser and your agent open their [direct connection](../how-qsp-works.md). You hear the band live and can tune, change mode and band.

If your station does not appear in the list, check that the agent is running (`systemctl status qsp-agent.service`) and read its logs. See [Troubleshooting](../troubleshooting.md).

Remember that you are the operator: a remote station is still your station, with the same licence conditions and responsibilities.
