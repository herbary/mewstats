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

stock float Mewstats_NormalizeVector(const float vec[3], float out[3])
{
    float length = SquareRoot(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
    if (length > 0.0)
    {
        out[0] = vec[0] / length;
        out[1] = vec[1] / length;
        out[2] = vec[2] / length;
    }
    return length;
}

stock float Mewstats_RelativeDeviation(const float arg1[3], const float arg2[3])
{
    float vec1[3];
    vec1[0] = arg1[0];
    vec1[1] = arg1[1];
    vec1[2] = 0.0;

    float vec2[3];
    vec2[0] = arg2[0];
    vec2[1] = arg2[1];
    vec2[2] = 0.0;

    if (Mewstats_NormalizeVector(vec1, vec1) == 0.0)
    {
        return 0.0;
    }
    if (Mewstats_NormalizeVector(vec2, vec2) == 0.0)
    {
        return 0.0;
    }

    float dot = vec1[0] * vec2[0] + vec1[1] * vec2[1];
    if (dot > 1.0)
    {
        dot = 1.0;
    }
    if (dot < -1.0)
    {
        dot = -1.0;
    }

    float angle = RadToDeg(ArcCosine(dot));
    if (angle > 90.0)
    {
        angle = 180.0 - angle;
    }

    float cross = vec1[0] * vec2[1] - vec1[1] * vec2[0];
    if (cross < 0.0)
    {
        return -angle;
    }

    return angle;
}

stock bool Mewstats_IsAlivePlayerInGame(int client)
{
    return Mewstats_IsPlayerInGame(client) && IsPlayerAlive(client);
}

stock bool Mewstats_IsPlayerInGame(int client)
{
    return Mewstats_IsClientInGame(client) && !IsFakeClient(client);
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
