#if defined _mewstats_util_included_
#endinput
#endif
#define _mewstats_util_included_

#include <clients>
#include <float>

stock bool Mewstats_IsFlag(int val, int flag)
{
    return (val & flag) == flag;
}

stock int Mewstats_FloatSign(float val)
{
    if (val > 0.0)
    {
        return 1;
    }
    if (val < 0.0)
    {
        return -1;
    }
    return 0;
}

stock float Mewstats_TruncateFloat(float val, int digits)
{
    if (val == 0.0)
    {
        return 0.0;
    }

    int sign = Mewstats_FloatSign(val);
    val = FloatAbs(val);

    if (digits <= 0)
    {
        return float(sign) * float(RoundToFloor(val));
    }

    float factor = Pow(10.0, float(digits));
    return float(sign) * float(RoundToFloor(val * factor)) / factor;
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
