#if defined _mewstats_util_included_
#endinput
#endif
#define _mewstats_util_included_

#include <clients>

stock bool Mewstats_IsFlag(int val, int flag)
{
    return view_as<bool>(val & flag);
}

stock bool Mewstats_IsAlivePlayerInGame(int client)
{
    return Mewstats_IsPlayerInGame(client) && IsPlayerAlive(client);
}

stock bool Mewstats_IsPlayerInGame(int client)
{
    return Mewstats_IsPlayer(client) && IsClientInGame(client);
}

stock bool Mewstats_IsAlivePlayer(int client)
{
    return Mewstats_IsPlayer(client) && IsPlayerAlive(client);
}

stock bool Mewstats_IsPlayer(int client)
{
    return Mewstats_IsClient(client) && !IsFakeClient(client);
}

stock bool Mewstats_IsAliveClientInGame(int client)
{
    return Mewstats_IsClientInGame(client) && IsPlayerAlive(client);
}

stock bool Mewstats_IsClientInGame(int client)
{
    return Mewstats_IsClient(client) && IsClientInGame(client);
}

stock bool Mewstats_IsAliveClient(int client)
{
    return Mewstats_IsClient(client) && IsPlayerAlive(client);
}

stock bool Mewstats_IsClient(int client)
{
    return client >= 1 && client <= MaxClients;
}
