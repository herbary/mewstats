// Mewstats
//
// Copyright (C) 2026  Mee;w
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#include <sourcemod>
#include <clientprefs>
#include <string>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <shavit/partner>
#define REQUIRE_PLUGIN

#include <mewstats/info>
#include <mewstats/phrases>
#include <mewstats/cookie>
#include <mewstats/menu>
#include <mewstats/event>
#include <mewstats/prop>
#include <mewstats/util>
#include <mewstats/chat>
#include <mewstats/classname>
#include <mewstats/theme>
#include <mewstats/color>

#pragma newdecls required
#pragma semicolon 1

#define _MEWSTATS_TICK_UNKNOWN -1
#define _MEWSTATS_MLS_STORE_LIMIT 12

public Plugin myinfo = {
    name = MEWSTATS_NAME,
    author = MEWSTATS_AUTHOR,
    description = MEWSTATS_DESCRIPTION,
    version = MEWSTATS_VERSION,
    url = MEWSTATS_URL
};

bool g_bLateLoaded = false;

Cookie g_ckThrowSpeed;
Cookie g_ckThrowAngle;
Cookie g_ckThrowTime;
Cookie g_ckThrowDeviation;
Cookie g_ckThrowStatus;
Cookie g_ckSkyStats;
Cookie g_ckMlsStats;
// Cookie g_ckNadeVelocity;
// Cookie g_ckPartnerStats;
Cookie g_ckShortNames;
Cookie g_ckCrouchName;
Cookie g_ckColorValues;
Cookie g_ckValuePreicision;
Cookie g_ckChatTheme;
Cookie g_ckChatSeparator;
Cookie g_ckChatSound;
Cookie g_ckLastBitflags;

int g_iThrowSpeed[MAXPLAYERS + 1];
int g_iThrowAngle[MAXPLAYERS + 1];
int g_iThrowTime[MAXPLAYERS + 1];
int g_iThrowDeviation[MAXPLAYERS + 1];
int g_iThrowStatus[MAXPLAYERS + 1];
int g_iSkyStats[MAXPLAYERS + 1];
int g_iMlsStats[MAXPLAYERS + 1];
// int g_iNadeVelocity[MAXPLAYERS + 1];
// int g_iPartnerStats[MAXPLAYERS + 1];
int g_iShortNames[MAXPLAYERS + 1];
int g_iCrouchName[MAXPLAYERS + 1];
int g_iColorValues[MAXPLAYERS + 1];
int g_iValuePrecision[MAXPLAYERS + 1];
int g_iChatTheme[MAXPLAYERS + 1];
int g_iChatSeparator[MAXPLAYERS + 1];
int g_iChatSound[MAXPLAYERS + 1];
int g_iLastBitflags[MAXPLAYERS + 1];

char g_szThrowSpeedModes[MEWSTATS_COOKIE_VALUE_THROW_SPEED_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowAngleModes[MEWSTATS_COOKIE_VALUE_THROW_ANGLE_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowTimeModes[MEWSTATS_COOKIE_VALUE_THROW_TIME_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowDeviationModes[MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowStatusModes[MEWSTATS_COOKIE_VALUE_THROW_STATUS_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szSkyStatsModes[MEWSTATS_COOKIE_VALUE_SKY_STATS_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szMlsStatsModes[MEWSTATS_COOKIE_VALUE_MLS_STATS_COUNT][MEWSTATS_MENU_ITEM_SIZE];
// char g_szNadeVelocityModes[MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_COUNT][MEWSTATS_MENU_ITEM_SIZE];
// char g_szPartnerStatsModes[MEWSTATS_COOKIE_VALUE_PARTNER_STATS_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szShortNamesModes[MEWSTATS_COOKIE_VALUE_SHORT_NAMES_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szCrouchNameModes[MEWSTATS_COOKIE_VALUE_CROUCH_NAME_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szColorValuesModes[MEWSTATS_COOKIE_VALUE_COLOR_VALUES_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szValuePrecisionModes[MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szChatThemeModes[MEWSTATS_COOKIE_VALUE_CHAT_THEME_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_COUNT][MEWSTATS_THEME_COLOR_COUNT][MEWSTATS_THEME_COLOR_SIZE];
char g_szChatSeparatorModes[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szChatSeparatorValues[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_COUNT][MEWSTATS_CHAT_SEPARATOR_SIZE];
char g_szChatSoundModes[MEWSTATS_COOKIE_VALUE_CHAT_SOUND_COUNT][MEWSTATS_MENU_ITEM_SIZE];

int g_iThrowJumpTick[MAXPLAYERS + 1];
int g_iSkyJumpTick[MAXPLAYERS + 1];
int g_iFlashHitTick[MAXPLAYERS + 1];
int g_iMlsFlashCount[MAXPLAYERS + 1];
int g_iMlsLastPartner[MAXPLAYERS + 1];
float g_fMlsPreHitSpeed[MAXPLAYERS + 1][_MEWSTATS_MLS_STORE_LIMIT];
float g_fMlsHitSpeed[MAXPLAYERS + 1][_MEWSTATS_MLS_STORE_LIMIT];
float g_fMlsFirstHitSpeed[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int err_max)
{
    g_bLateLoaded = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations(MEWSTATS_MESSAGE_FILENAME);

    Mewstats_CreateGlobals();
    Mewstats_CreateCookies();
    Mewstats_CreateCommands();
    Mewstats_HookEvents();

    if (!g_bLateLoaded)
    {
        return;
    }
    for (int client = 1; client <= MaxClients; ++client)
    {
        if (IsClientInGame(client))
        {
            OnClientPutInServer(client);
        }
        if (AreClientCookiesCached(client))
        {
            OnClientCookiesCached(client);
        }
    }
}

public void OnClientPutInServer(int client)
{
    g_iThrowJumpTick[client] = _MEWSTATS_TICK_UNKNOWN;
    g_iSkyJumpTick[client] = _MEWSTATS_TICK_UNKNOWN;
    g_iFlashHitTick[client] = _MEWSTATS_TICK_UNKNOWN;
    g_iMlsFlashCount[client] = 0;
    g_iMlsLastPartner[client] = -1;

    Mewstats_InitStateVars(client);

    SDKHook(client, SDKHook_StartTouch, Hook_StartTouch);
}

public void OnClientCookiesCached(int client)
{
    Mewstats_InitStateVars(client);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (!Mewstats_IsClientInGame(client))
    {
        return Plugin_Continue;
    }

    if (g_iSkyJumpTick[client] != _MEWSTATS_TICK_UNKNOWN)
    {
        if (tickcount - g_iSkyJumpTick[client] >= 2)
        {
            g_iSkyJumpTick[client] = _MEWSTATS_TICK_UNKNOWN;
        }
    }
    if (g_iFlashHitTick[client] != _MEWSTATS_TICK_UNKNOWN)
    {
        if (tickcount - g_iFlashHitTick[client] >= 2)
        {
            g_iFlashHitTick[client] = _MEWSTATS_TICK_UNKNOWN;

            float velocity[3];
            GetEntPropVector(client, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, velocity);

            velocity[2] = 0.0;
            float speed = GetVectorLength(velocity, false);

            int index = g_iMlsFlashCount[client] - 1;
            if (index >= _MEWSTATS_MLS_STORE_LIMIT)
            {
                g_fMlsFirstHitSpeed[client] = g_fMlsHitSpeed[client][0];
            }
            Mewstats_InsertMlsSpeed(client, g_fMlsHitSpeed, g_iMlsFlashCount[client] - 1, speed);
        }
    }

    int flags = GetEntProp(client, Prop_Data, MEWSTATS_PROP_M_FFLAGS);
    if (g_iSkyJumpTick[client] == _MEWSTATS_TICK_UNKNOWN && g_iFlashHitTick[client] == _MEWSTATS_TICK_UNKNOWN && Mewstats_IsFlag(flags, FL_ONGROUND))
    {
        Mewstats_PrintMlsStats(client, client);
        Mewstats_PrintMlsStats(g_iMlsLastPartner[client], client);
        for (int klient = 1; klient <= MaxClients; ++klient)
        {
            if (!Mewstats_IsPlayerInGame(klient))
            {
                continue;
            }
            if (IsPlayerAlive(klient))
            {
                continue;
            }

            int mode = GetEntProp(klient, Prop_Send, MEWSTATS_PROP_M_IOBSERVERMODE);
            if (mode < 4 || mode > 6)
            {
                continue;
            }

            int target = GetEntPropEnt(klient, Prop_Send, MEWSTATS_PROP_M_HOBSERVERTARGET);
            if (target != client && target != g_iMlsLastPartner[client])
            {
                continue;
            }

            Mewstats_PrintMlsStats(klient, client);
        }

        g_iMlsFlashCount[client] = 0;
    }

    return Plugin_Continue;
}


static Action Hook_StartTouch(int client, int entity)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return Plugin_Continue;
    }
    if (!IsValidEntity(entity))
    {
        return Plugin_Continue;
    }

    char szClassname[MEWSTATS_CLASSNAME_SIZE] = "";
    GetEntityClassname(entity, szClassname, sizeof(szClassname));

    bool bProjectile = StrContains(szClassname, "_projectile") != -1;
    if (!bProjectile)
    {
        Mewstats_ProcessSky(client, entity);
        return Plugin_Continue;
    }

    Mewstats_ProcessMls(client, entity);
    return Plugin_Continue;
}

static void Mewstats_ProcessSky(int client, int entity)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return;
    }
    if (!Mewstats_IsClientInGame(entity))
    {
        return;
    }

    // Client is Top
    // Entity is Bottom

    float clientPosition[3];
    GetEntPropVector(client, Prop_Data, MEWSTATS_PROP_M_VECORIGIN, clientPosition);

    float entityPosition[3];
    GetEntPropVector(entity, Prop_Data, MEWSTATS_PROP_M_VECORIGIN, entityPosition);

    float entityMaxs[3];
    float entityVelocity[3];

    float clientZ;
    float entityZ;

    int clientFlags;

    if (clientPosition[2] < entityPosition[2])
    {
        clientZ = entityPosition[2];
        entityZ = clientPosition[2];

        GetEntPropVector(client, Prop_Data, MEWSTATS_PROP_M_VECMAXS, entityMaxs);
        GetEntPropVector(client, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, entityVelocity);
        clientFlags = GetEntProp(entity, Prop_Data, MEWSTATS_PROP_M_FFLAGS);
    }
    else
    {
        clientZ = clientPosition[2];
        entityZ = entityPosition[2];

        GetEntPropVector(entity, Prop_Data, MEWSTATS_PROP_M_VECMAXS, entityMaxs);
        GetEntPropVector(entity, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, entityVelocity);
        clientFlags = GetEntProp(client, Prop_Data, MEWSTATS_PROP_M_FFLAGS);
    }

    float diff = clientZ - entityZ - entityMaxs[2];
    if (diff < 0.0 || diff > 2.0)
    {
        return;
    }

    float strength = entityVelocity[2];
    if (strength <= 0.0 || strength > 290 || Mewstats_IsFlag(clientFlags, FL_DUCKING))
    {
        return;
    }

    g_iSkyJumpTick[client] = GetEntProp(client, Prop_Send, MEWSTATS_PROP_M_NTICKBASE);

    Mewstats_PrintSkyStats(client, strength);
    for (int klient = 1; klient <= MaxClients; ++klient)
    {
        if (!Mewstats_IsPlayerInGame(klient))
        {
            continue;
        }
        if (IsPlayerAlive(klient))
        {
            continue;
        }

        int mode = GetEntProp(klient, Prop_Send, MEWSTATS_PROP_M_IOBSERVERMODE);
        if (mode < 4 || mode > 6)
        {
            continue;
        }

        int target = GetEntPropEnt(klient, Prop_Send, MEWSTATS_PROP_M_HOBSERVERTARGET);
        if (target != client)
        {
            continue;
        }

        Mewstats_PrintSkyStats(klient, strength);
    }
}

static void Mewstats_PrintSkyStats(int client, float strength)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return;
    }
    if (g_iSkyStats[client] != MEWSTATS_COOKIE_VALUE_SKY_STATS_TRUE)
    {
        return;
    }

    char szBaseColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
    if (szBaseColor[0] == '\0')
    {
        return;
    }

    char szAccentColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_TRUE)
    {
        int color[3];
        Mewstats_TransColor(strength / 290.0 * 100.0, 80.0, color);

        FormatEx(szAccentColor, sizeof(szAccentColor), "\x07%02X%02X%02X", color[0], color[1], color[2]);
    }
    else if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_FALSE)
    {
        strcopy(szAccentColor, sizeof(szAccentColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_ACCENT]);
    }
    if (szAccentColor[0] == '\0')
    {
        return;
    }

    char szStrength[32] = "";
    if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ZERO)
    {
        FormatEx(szStrength, sizeof(szStrength), "%.0f", Mewstats_TruncateFloat(strength, 0));
    }
    else if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ONE)
    {
        FormatEx(szStrength, sizeof(szStrength), "%.1f", Mewstats_TruncateFloat(strength, 1));
    }
    if (szStrength[0] == '\0')
    {
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%T", MEWSTATS_MESSAGE_SKY_JUMP, client, szBaseColor, szAccentColor, szStrength);
    if (szMessage[0] == '\0')
    {
        return;
    }

    Mewstats_SayText2(client, g_iChatSound[client] == MEWSTATS_COOKIE_VALUE_CHAT_SOUND_TRUE, szMessage);
}

static void Mewstats_ProcessMls(int client, int entity)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return;
    }
    if (!IsValidEntity(entity))
    {
        return;
    }

    float entityVelocity[3];
    GetEntPropVector(entity, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, entityVelocity);
    if (entityVelocity[2] <= 0.0)
    {
        return;
    }

    float clientPosition[3];
    GetEntPropVector(client, Prop_Data, MEWSTATS_PROP_M_VECORIGIN, clientPosition);

    float entityPosition[3];
    GetEntPropVector(entity, Prop_Data, MEWSTATS_PROP_M_VECORIGIN, entityPosition);

    float entityMaxs[3];
    GetEntPropVector(entity, Prop_Data, MEWSTATS_PROP_M_VECMAXS, entityMaxs);

    float diff = clientPosition[2] - entityPosition[2] - entityMaxs[2];
    if (diff < 0.0 || diff > 2.0)
    {
        return;
    }

    g_iFlashHitTick[client] = GetEntProp(client, Prop_Send, MEWSTATS_PROP_M_NTICKBASE);

    int thrower = GetEntPropEnt(entity, Prop_Data, MEWSTATS_PROP_M_HTHROWER);
    g_iMlsLastPartner[client] = thrower;

    ++g_iMlsFlashCount[client];

    float clientVelocity[3];
    GetEntPropVector(client, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, clientVelocity);

    clientVelocity[2] = 0.0;
    float clientSpeed = GetVectorLength(clientVelocity, false);

    Mewstats_InsertMlsSpeed(client, g_fMlsPreHitSpeed, g_iMlsFlashCount[client] - 1, clientSpeed);
}

static void Mewstats_PrintMlsStats(int client, int target)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return;
    }
    if (!Mewstats_IsClientInGame(target))
    {
        return;
    }
    if (g_iMlsStats[client] != MEWSTATS_COOKIE_VALUE_MLS_STATS_TRUE)
    {
        return;
    }
    if (g_iMlsFlashCount[target] <= 0)
    {
        return;
    }

#define _MEWSTATS_MESSAGE_SIZE 256
#define _MEWSTATS_ELEMENT_SIZE 64
#define _MEWSTATS_ELEMENT_COUNT 3

    int offset = g_iMlsFlashCount[target] - _MEWSTATS_MLS_STORE_LIMIT;
    if (offset < 0)
    {
        offset = 0;
    }

    int count = g_iMlsFlashCount[target];
    if (count > _MEWSTATS_MLS_STORE_LIMIT)
    {
        count = _MEWSTATS_MLS_STORE_LIMIT;
    }

    for (int i = 0; i < count; ++i)
    {
        int number = i + 1 + offset;

        char szHitNumber[_MEWSTATS_ELEMENT_SIZE] = "";
        FormatEx(szHitNumber, sizeof(szHitNumber), "%sx%s%i", g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_MLS_BASE], g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_MLS_ACCENT], number);

        char szHitSpeed[_MEWSTATS_ELEMENT_SIZE] = "";
        FormatEx(szHitSpeed, sizeof(szHitSpeed), "%s%.0f%s ->%s %.0f", g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_MLS_ACCENT], Mewstats_TruncateFloat(g_fMlsPreHitSpeed[target][i], 0), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_MLS_BASE], g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_MLS_ACCENT], Mewstats_TruncateFloat(g_fMlsHitSpeed[target][i], 0));

        char szHitGain[_MEWSTATS_ELEMENT_SIZE] = "";
        if (number > 1)
        {
            float gain;
            if (i == 0)
            {
                gain = g_fMlsPreHitSpeed[target][i] - g_fMlsFirstHitSpeed[target];
            }
            else
            {
                gain = g_fMlsPreHitSpeed[target][i] - g_fMlsHitSpeed[target][i - 1];
            }

            int igain = RoundToFloor(gain);
            FormatEx(szHitGain, sizeof(szHitGain), "%s%s%.0f", g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_MLS_ACCENT], igain >= 0 ? "+" : "", Mewstats_TruncateFloat(gain, 0));
        }

        char szMessageElements[_MEWSTATS_ELEMENT_COUNT][_MEWSTATS_ELEMENT_SIZE];

        int kount = 0;
        if (szHitNumber[0] != '\0' && kount < _MEWSTATS_ELEMENT_COUNT)
        {
            strcopy(szMessageElements[kount++], _MEWSTATS_ELEMENT_SIZE, szHitNumber);
        }
        if (szHitSpeed[0] != '\0' && kount < _MEWSTATS_ELEMENT_COUNT)
        {
            strcopy(szMessageElements[kount++], _MEWSTATS_ELEMENT_SIZE, szHitSpeed);
        }
        if (szHitGain[0] != '\0' && kount < _MEWSTATS_ELEMENT_COUNT)
        {
            strcopy(szMessageElements[kount++], _MEWSTATS_ELEMENT_SIZE, szHitGain);
        }

        char szMessage[_MEWSTATS_MESSAGE_SIZE] = "";
        for (int j = 0; j < kount; ++j)
        {
            if (j >= 1)
            {
                Format(szMessage, sizeof(szMessage), "%s%s%s", szMessage, g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_MLS_SEPARATOR], MEWSTATS_CHAT_SEPARATOR_LINE);
            }
            Format(szMessage, sizeof(szMessage), "%s%s", szMessage, szMessageElements[j]);
        }
        if (szMessage[0] == '\0')
        {
            return;
        }

        Mewstats_SayText2(client, g_iChatSound[client] == MEWSTATS_COOKIE_VALUE_CHAT_SOUND_TRUE && i == count - 1, szMessage);
    }

#undef _MEWSTATS_ELEMENT_COUNT
#undef _MEWSTATS_ELEMENT_SIZE
#undef _MEWSTATS_MESSAGE_SIZE
}

static void Mewstats_InsertMlsSpeed(int client, float storage[MAXPLAYERS + 1][_MEWSTATS_MLS_STORE_LIMIT], int index, float value)
{
    if (index >= _MEWSTATS_MLS_STORE_LIMIT)
    {
        Mewstats_ShiftMlsSpeed(client, storage);
        index = _MEWSTATS_MLS_STORE_LIMIT - 1;
    }

    storage[client][index] = value;
}

static void Mewstats_ShiftMlsSpeed(int client, float storage[MAXPLAYERS + 1][_MEWSTATS_MLS_STORE_LIMIT])
{
    for (int i = 1; i < _MEWSTATS_MLS_STORE_LIMIT; ++i)
    {
        storage[client][i - 1] = storage[client][i];
    }
}

public void OnEntityCreated(int entity, const char[] szClassname)
{
    if (!IsValidEntity(entity))
    {
        return;
    }
    if (!StrEqual(szClassname, MEWSTATS_CLASSNAME_PROJECTILE_FLASHBANG))
    {
        return;
    }

    SDKHook(entity, SDKHook_SpawnPost, Hook_SpawnPost);
}

static void Hook_SpawnPost(int entity)
{
    if (!IsValidEntity(entity))
    {
        return;
    }

    RequestFrame(Frame_FlashbangSpawn, EntIndexToEntRef(entity));
}

static void Frame_FlashbangSpawn(int ref)
{
    int entity = EntRefToEntIndex(ref);
    if (entity == INVALID_ENT_REFERENCE)
    {
        return;
    }
    if (!IsValidEntity(entity))
    {
        return;
    }

    int thrower = GetEntPropEnt(entity, Prop_Data, MEWSTATS_PROP_M_HTHROWER);
    if (!Mewstats_IsAlivePlayerInGame(thrower))
    {
        return;
    }

    int flags = GetEntProp(thrower, Prop_Data, MEWSTATS_PROP_M_FFLAGS);
    MoveType movetype = GetEntityMoveType(thrower);
    if (Mewstats_IsFlag(flags, FL_ONGROUND) || movetype != MOVETYPE_WALK)
    {
        g_iThrowJumpTick[thrower] = _MEWSTATS_TICK_UNKNOWN;
    }

    Mewstats_PrintThrowStats(thrower, thrower, entity);
    for (int client = 1; client <= MaxClients; ++client)
    {
        if (!Mewstats_IsPlayerInGame(client))
        {
            continue;
        }
        if (IsPlayerAlive(client))
        {
            continue;
        }

        int mode = GetEntProp(client, Prop_Send, MEWSTATS_PROP_M_IOBSERVERMODE);
        if (mode < 4 || mode > 6)
        {
            continue;
        }

        int target = GetEntPropEnt(client, Prop_Send, MEWSTATS_PROP_M_HOBSERVERTARGET);
        if (target != thrower)
        {
            continue;
        }

        Mewstats_PrintThrowStats(client, thrower, entity);
    }
}

static void Mewstats_PrintThrowStats(int client, int thrower, int entity)
{
    if (!Mewstats_IsClientInGame(client) || !Mewstats_IsClientInGame(thrower))
    {
        return;
    }
    if (!IsValidEntity(entity))
    {
        return;
    }

#define _MEWSTATS_MESSAGE_SIZE 256
#define _MEWSTATS_ELEMENT_SIZE 64
#define _MEWSTATS_ELEMENT_COUNT 5

    char szThrowSpeed[_MEWSTATS_ELEMENT_SIZE] = "";
    Mewstats_FormatThrowSpeed(client, thrower, szThrowSpeed, sizeof(szThrowSpeed));

    char szThrowAngle[_MEWSTATS_ELEMENT_SIZE] = "";
    Mewstats_FormatThrowAngle(client, thrower, szThrowAngle, sizeof(szThrowAngle));

    char szThrowTime[_MEWSTATS_ELEMENT_SIZE] = "";
    Mewstats_FormatThrowTime(client, thrower, szThrowTime, sizeof(szThrowTime));

    char szThrowDeviation[_MEWSTATS_ELEMENT_SIZE] = "";
    Mewstats_FormatThrowDeviation(client, thrower, entity, szThrowDeviation, sizeof(szThrowDeviation));

    char szThrowStatus[_MEWSTATS_ELEMENT_SIZE] = "";
    Mewstats_FormatThrowStatus(client, thrower, szThrowStatus, sizeof(szThrowStatus));

    char szMessageElements[_MEWSTATS_ELEMENT_COUNT][_MEWSTATS_ELEMENT_SIZE];

    int count = 0;
    if (szThrowSpeed[0] != '\0' && count < _MEWSTATS_ELEMENT_COUNT)
    {
        strcopy(szMessageElements[count++], _MEWSTATS_ELEMENT_SIZE, szThrowSpeed);
    }
    if (szThrowAngle[0] != '\0' && count < _MEWSTATS_ELEMENT_COUNT)
    {
        strcopy(szMessageElements[count++], _MEWSTATS_ELEMENT_SIZE, szThrowAngle);
    }
    if (szThrowTime[0] != '\0' && count < _MEWSTATS_ELEMENT_COUNT)
    {
        strcopy(szMessageElements[count++], _MEWSTATS_ELEMENT_SIZE, szThrowTime);
    }
    if (szThrowDeviation[0] != '\0' && count < _MEWSTATS_ELEMENT_SIZE)
    {
        strcopy(szMessageElements[count++], _MEWSTATS_ELEMENT_SIZE, szThrowDeviation);
    }
    if (szThrowStatus[0] != '\0' && count < _MEWSTATS_ELEMENT_COUNT)
    {
        strcopy(szMessageElements[count++], _MEWSTATS_ELEMENT_SIZE, szThrowStatus);
    }

    char szMessage[_MEWSTATS_MESSAGE_SIZE] = "";
    for (int i = 0; i < count; ++i)
    {
        if (i >= 1)
        {
            Format(szMessage, sizeof(szMessage), "%s%s%s", szMessage, g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_SEPARATOR], g_szChatSeparatorValues[g_iChatSeparator[client]]);
        }
        Format(szMessage, sizeof(szMessage), "%s%s", szMessage, szMessageElements[i]);
    }
    if (szMessage[0] == '\0')
    {
        return;
    }

    Mewstats_SayText2(client, g_iChatSound[client] == MEWSTATS_COOKIE_VALUE_CHAT_SOUND_TRUE, szMessage);

#undef _MEWSTATS_ELEMENT_COUNT
#undef _MEWSTATS_ELEMENT_SIZE
#undef _MEWSTATS_MESSAGE_SIZE
}

static void Mewstats_FormatThrowSpeed(int client, int thrower, char[] buff, int size)
{
    if (!Mewstats_IsClientInGame(client) || !Mewstats_IsClientInGame(thrower))
    {
        return;
    }
    if (g_iThrowSpeed[client] != MEWSTATS_COOKIE_VALUE_THROW_SPEED_TRUE)
    {
        return;
    }

    int flags = GetEntProp(thrower, Prop_Data, MEWSTATS_PROP_M_FFLAGS);
    bool ducking = Mewstats_IsFlag(flags, FL_DUCKING);

    char szPhrase[MEWSTATS_MESSAGE_KEY_SIZE] = "";
    if (g_iShortNames[client] == MEWSTATS_COOKIE_VALUE_SHORT_NAMES_TRUE)
    {
        if (ducking)
        {
            if (g_iCrouchName[client] == MEWSTATS_COOKIE_VALUE_CROUCH_NAME_DUCK)
            {
                strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_SHORT_DUCK_THROW_SPEED);
            }
            else if (g_iCrouchName[client] == MEWSTATS_COOKIE_VALUE_CROUCH_NAME_CROUCH)
            {
                strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_SHORT_CROUCH_THROW_SPEED);
            }
        }
        else
        {
            strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_SHORT_THROW_SPEED);
        }
    }
    else if (g_iShortNames[client] == MEWSTATS_COOKIE_VALUE_SHORT_NAMES_FALSE)
    {
        if (ducking)
        {
            if (g_iCrouchName[client] == MEWSTATS_COOKIE_VALUE_CROUCH_NAME_DUCK)
            {
                strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_DUCK_THROW_SPEED);
            }
            else if (g_iCrouchName[client] == MEWSTATS_COOKIE_VALUE_CROUCH_NAME_CROUCH)
            {
                strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_CROUCH_THROW_SPEED);
            }
        }
        else
        {
            strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_THROW_SPEED);
        }
    }
    if (szPhrase[0] == '\0')
    {
        return;
    }

    float velocity[3];
    GetEntPropVector(thrower, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, velocity);

    velocity[2] = 0.0;
    float speed = GetVectorLength(velocity, false);

    char szBaseColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
    if (szBaseColor[0] == '\0')
    {
        return;
    }

    char szAccentColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_TRUE)
    {
        int color[3];
        if (ducking)
        {
            Mewstats_TransColor(speed / 85.0 * 100.0, 90.0, color);
        }
        else
        {
            Mewstats_TransColor(speed / 250.0 * 100.0, 90.0, color);
        }

        FormatEx(szAccentColor, sizeof(szAccentColor), "\x07%02X%02X%02X", color[0], color[1], color[2]);
    }
    else if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_FALSE)
    {
        strcopy(szAccentColor, sizeof(szAccentColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_ACCENT]);
    }
    if (szAccentColor[0] == '\0')
    {
        return;
    }

    char szSpeed[32] = "";
    if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ZERO)
    {
        FormatEx(szSpeed, sizeof(szSpeed), "%.0f", Mewstats_TruncateFloat(speed, 0));
    }
    else if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ONE)
    {
        FormatEx(szSpeed, sizeof(szSpeed), "%.1f", Mewstats_TruncateFloat(speed, 1));
    }
    if (szSpeed[0] == '\0')
    {
        return;
    }

    FormatEx(buff, size, "%T", szPhrase, client, szBaseColor, szAccentColor, szSpeed);
}

static void Mewstats_FormatThrowAngle(int client, int thrower, char[] buff, int size)
{
    if (!Mewstats_IsClientInGame(client) || !Mewstats_IsClientInGame(thrower))
    {
        return;
    }
    if (g_iThrowAngle[client] != MEWSTATS_COOKIE_VALUE_THROW_ANGLE_TRUE)
    {
        return;
    }

    char szPhrase[MEWSTATS_MESSAGE_KEY_SIZE] = "";
    if (g_iShortNames[client] == MEWSTATS_COOKIE_VALUE_SHORT_NAMES_TRUE)
    {
        strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_SHORT_THROW_ANGLE);
    }
    else if (g_iShortNames[client] == MEWSTATS_COOKIE_VALUE_SHORT_NAMES_FALSE)
    {
        strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_THROW_ANGLE);
    }
    if (szPhrase[0] == '\0')
    {
        return;
    }

    float angles[3];
    GetClientEyeAngles(thrower, angles);

    float angle = -1.0 * angles[0];

    char szBaseColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
    if (szBaseColor[0] == '\0')
    {
        return;
    }

    char szAccentColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    strcopy(szAccentColor, sizeof(szAccentColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_ACCENT]);
    if (szAccentColor[0] == '\0')
    {
        return;
    }

    char szAngle[32] = "";
    if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ZERO)
    {
        FormatEx(szAngle, sizeof(szAngle), "%.0f", Mewstats_TruncateFloat(angle, 0));
    }
    else if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ONE)
    {
        FormatEx(szAngle, sizeof(szAngle), "%.1f", Mewstats_TruncateFloat(angle, 1));
    }
    if (szAngle[0] == '\0')
    {
        return;
    }

    FormatEx(buff, size, "%T", szPhrase, client, szBaseColor, szAccentColor, szAngle);
}

static void Mewstats_FormatThrowTime(int client, int thrower, char[] buff, int size)
{
    if (!Mewstats_IsClientInGame(client) || !Mewstats_IsClientInGame(thrower))
    {
        return;
    }
    if (g_iThrowTime[client] != MEWSTATS_COOKIE_VALUE_THROW_TIME_TRUE)
    {
        return;
    }

    char szPhrase[MEWSTATS_MESSAGE_KEY_SIZE] = "";
    if (g_iShortNames[client] == MEWSTATS_COOKIE_VALUE_SHORT_NAMES_TRUE)
    {
        strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_SHORT_THROW_TIME);
    }
    else if (g_iShortNames[client] == MEWSTATS_COOKIE_VALUE_SHORT_NAMES_FALSE)
    {
        strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_THROW_TIME);
    }
    if (szPhrase[0] == '\0')
    {
        return;
    }

    int tick = 0;
    if (g_iThrowJumpTick[thrower] != _MEWSTATS_TICK_UNKNOWN)
    {
        tick = GetEntProp(thrower, Prop_Send, MEWSTATS_PROP_M_NTICKBASE) - g_iThrowJumpTick[thrower] - 2;
        if (tick < 0)
        {
            tick = 0;
        }
    }
    float time = tick * GetTickInterval();

    char szBaseColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
    if (szBaseColor[0] == '\0')
    {
        return;
    }

    char szAccentColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_TRUE)
    {
        int color[3];
        Mewstats_TransColor(100.0 - time / 0.1 * 100.0, 50.0, color);

        FormatEx(szAccentColor, sizeof(szAccentColor), "\x07%02X%02X%02X", color[0], color[1], color[2]);
    }
    else if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_FALSE)
    {
        strcopy(szAccentColor, sizeof(szAccentColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_ACCENT]);
    }
    if (szAccentColor[0] == '\0')
    {
        return;
    }

    char szTime[32] = "";
    FormatEx(szTime, sizeof(szTime), "%.2f", Mewstats_TruncateFloat(time, 2));
    if (szTime[0] == '\0')
    {
        return;
    }

    FormatEx(buff, size, "%T", szPhrase, client, szBaseColor, szAccentColor, szTime);
}

static void Mewstats_FormatThrowDeviation(int client, int thrower, int entity, char[] buff, int size)
{
    if (GetFeatureStatus(FeatureType_Native, "Timer_GetPartner") != FeatureStatus_Available)
    {
        return;
    }
    if (!Mewstats_IsClientInGame(client) || !Mewstats_IsClientInGame(thrower))
    {
        return;
    }
    if (!IsValidEntity(entity))
    {
        return;
    }
    if (g_iThrowDeviation[client] != MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_TRUE)
    {
        return;
    }

    int partner = Timer_GetPartner(thrower);
    if (!Mewstats_IsAliveClientInGame(partner))
    {
        return;
    }

    char szPhrase[MEWSTATS_MESSAGE_KEY_SIZE] = "";
    if (g_iShortNames[client] == MEWSTATS_COOKIE_VALUE_SHORT_NAMES_TRUE)
    {
        strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_SHORT_THROW_DEVIATION);
    }
    else if (g_iShortNames[client] == MEWSTATS_COOKIE_VALUE_SHORT_NAMES_FALSE)
    {
        strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_THROW_DEVIATION);
    }
    if (szPhrase[0] == '\0')
    {
        return;
    }

    float flashbangVelocity[3];
    GetEntPropVector(entity, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, flashbangVelocity);
    flashbangVelocity[2] = 0.0;

    float partnerVelocity[3];
    GetEntPropVector(partner, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, partnerVelocity);
    partnerVelocity[2] = 0.0;

    float speed = GetVectorLength(partnerVelocity, false);
    if (speed <= 0.2)
    {
        float flashbangPosition[3];
        GetEntPropVector(entity, Prop_Data, MEWSTATS_PROP_M_VECORIGIN, flashbangPosition);

        float partnerPosition[3];
        GetClientAbsOrigin(partner, partnerPosition);

        partnerVelocity[0] = partnerPosition[0] - flashbangPosition[0];
        partnerVelocity[1] = partnerPosition[1] - flashbangPosition[1];
    }

    float angle = Mewstats_RelativeDeviation(flashbangVelocity, partnerVelocity);

    char szBaseColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
    if (szBaseColor[0] == '\0')
    {
        return;
    }

    char szAccentColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    strcopy(szAccentColor, sizeof(szAccentColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_ACCENT]);
    if (szAccentColor[0] == '\0')
    {
        return;
    }

    char szAngle[32] = "";
    if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ZERO)
    {
        FormatEx(szAngle, sizeof(szAngle), "%.0f", Mewstats_TruncateFloat(angle, 0));
    }
    else if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ONE)
    {
        FormatEx(szAngle, sizeof(szAngle), "%.1f", Mewstats_TruncateFloat(angle, 1));
    }
    if (szAngle[0] == '\0')
    {
        return;
    }

    FormatEx(buff, size, "%T", szPhrase, client, szBaseColor, szAccentColor, szAngle);
}

static void Mewstats_FormatThrowStatus(int client, int thrower, char[] buff, int size)
{
    if (!Mewstats_IsClientInGame(client) || !Mewstats_IsClientInGame(thrower))
    {
        return;
    }
    if (g_iThrowStatus[client] != MEWSTATS_COOKIE_VALUE_THROW_STATUS_TRUE)
    {
        return;
    }
    if (g_iThrowJumpTick[thrower] != _MEWSTATS_TICK_UNKNOWN)
    {
        return;
    }

    char szPhrase[MEWSTATS_MESSAGE_KEY_SIZE] = "";
    if (g_iShortNames[client] == MEWSTATS_COOKIE_VALUE_SHORT_NAMES_TRUE)
    {
        strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_SHORT_NOJUMP_STATUS);
    }
    else if (g_iShortNames[client] == MEWSTATS_COOKIE_VALUE_SHORT_NAMES_FALSE)
    {
        strcopy(szPhrase, sizeof(szPhrase), MEWSTATS_MESSAGE_NOJUMP_STATUS);
    }
    if (szPhrase[0] == '\0')
    {
        return;
    }

    char szBaseColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
    if (szBaseColor[0] == '\0')
    {
        return;
    }

    FormatEx(buff, size, "%T", szPhrase, client, szBaseColor);
}

static void Event_PlayerJump(Event event, const char[] name, bool bNoBroadcast)
{
    if (event == INVALID_HANDLE)
    {
        return;
    }

    int client = GetClientOfUserId(event.GetInt(MEWSTATS_EVENT_VAR_USERID));
    if (!Mewstats_IsClientInGame(client))
    {
        return;
    }

    g_iThrowJumpTick[client] = GetEntProp(client, Prop_Send, MEWSTATS_PROP_M_NTICKBASE);
}

static Action Command_Stats(int client, int argc)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    Menu_Stats(client, 0);
    return Plugin_Handled;
}

static void Menu_Stats(int client, int position)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return;
    }

    Menu menu = new Menu(MenuHandler_Stats);
    menu.SetTitle("Boost Stats\n ");

    char szItem[MEWSTATS_MENU_ITEM_SIZE];

    // Throw Speed
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_THROW_SPEED_FMT, g_szThrowSpeedModes[g_iThrowSpeed[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_THROW_SPEED, szItem);

    // Throw Angle
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_THROW_ANGLE_FMT, g_szThrowAngleModes[g_iThrowAngle[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_THROW_ANGLE, szItem);

    // Throw Time
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_THROW_TIME_FMT, g_szThrowTimeModes[g_iThrowTime[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_THROW_TIME, szItem);

    // Throw Deviation
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_THROW_DEVIATION_FMT, g_szThrowDeviationModes[g_iThrowDeviation[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_THROW_DEVIATION, szItem, GetFeatureStatus(FeatureType_Native, "Timer_GetPartner") == FeatureStatus_Available ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    // Throw Status
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_THROW_STATUS_FMT, g_szThrowStatusModes[g_iThrowStatus[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_THROW_STATUS, szItem);

    // Sky Stats
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_SKY_STATS_FMT, g_szSkyStatsModes[g_iSkyStats[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_SKY_STATS, szItem);

    // MLS Stats
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_MLS_STATS_FMT, g_szMlsStatsModes[g_iMlsStats[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_MLS_STATS, szItem);

    // // Nade Velocity
    // FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_NADE_VELOCITY_FMT, g_szNadeVelocityModes[g_iNadeVelocity[client]]);
    // menu.AddItem(MEWSTATS_MENU_SELECT_NADE_VELOCITY, szItem);

    // // Partner Stats
    // FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_PARTNER_STATS_FMT, g_szPartnerStatsModes[g_iPartnerStats[client]]);
    // menu.AddItem(MEWSTATS_MENU_SELECT_PARTNER_STATS, szItem);

    // Short Names
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_SHORT_NAMES_FMT, g_szShortNamesModes[g_iShortNames[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_SHORT_NAMES, szItem);

    // Crouch Name
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_CROUCH_NAME_FMT, g_szCrouchNameModes[g_iCrouchName[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_CROUCH_NAME, szItem);

    // Color Values
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_COLOR_VALUES_FMT, g_szColorValuesModes[g_iColorValues[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_COLOR_VALUES, szItem);

    // Value Precision
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_VALUE_PRECISION_FMT, g_szValuePrecisionModes[g_iValuePrecision[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_VALUE_PRECISION, szItem);

    // Chat Theme
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_CHAT_THEME_FMT, g_szChatThemeModes[g_iChatTheme[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_CHAT_THEME, szItem);

    // Chat Separator
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_CHAT_SEPARATOR_FMT, g_szChatSeparatorModes[g_iChatSeparator[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_CHAT_SEPARATOR, szItem);

    // Chat Sound
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_CHAT_SOUND_FMT, g_szChatSoundModes[g_iChatSound[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_CHAT_SOUND, szItem);

    menu.ExitBackButton = false;
    menu.ExitButton = true;

    menu.DisplayAt(client, position, MENU_TIME_FOREVER);
}

static void MenuHandler_Stats(Menu menu, MenuAction action, int client, int index)
{
    if (action == MenuAction_End)
    {
        delete menu;
        return;
    }
    if (action != MenuAction_Select)
    {
        return;
    }
    if (!Mewstats_IsClientInGame(client))
    {
        return;
    }

    char szInfo[MEWSTATS_MENU_SELECT_SIZE];
    if (!menu.GetItem(index, szInfo, sizeof(szInfo)))
    {
        return;
    }

    if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_THROW_SPEED))
    {
        MenuSelect_ThrowSpeed(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_THROW_ANGLE))
    {
        MenuSelect_ThrowAngle(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_THROW_TIME))
    {
        MenuSelect_ThrowTime(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_THROW_DEVIATION))
    {
        MenuSelect_ThrowDeviation(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_THROW_STATUS))
    {
        MenuSelect_ThrowStatus(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_SKY_STATS))
    {
        MenuSelect_SkyStats(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_MLS_STATS))
    {
        MenuSelect_MlsStats(client);
    }
    // else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_NADE_VELOCITY))
    // {
    //     MenuSelect_NadeVelocity(client);
    // }
    // else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_PARTNER_STATS))
    // {
    //     MenuSelect_PartnerStats(client);
    // }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_SHORT_NAMES))
    {
        MenuSelect_ShortNames(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_CROUCH_NAME))
    {
        MenuSelect_CrouchName(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_COLOR_VALUES))
    {
        MenuSelect_ColorValues(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_VALUE_PRECISION))
    {
        MenuSelect_ValuePrecision(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_CHAT_THEME))
    {
        MenuSelect_ChatTheme(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_CHAT_SEPARATOR))
    {
        MenuSelect_ChatSeparator(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_CHAT_SOUND))
    {
        MenuSelect_ChatSound(client);
    }

    Menu_Stats(client, GetMenuSelectionPosition());
}

static void MenuSelect_ThrowSpeed(int client)
{
    Mewstats_CycleCookie(client, g_ckThrowSpeed, g_iThrowSpeed, MEWSTATS_COOKIE_VALUE_THROW_SPEED_COUNT);
}

static void MenuSelect_ThrowAngle(int client)
{
    Mewstats_CycleCookie(client, g_ckThrowAngle, g_iThrowAngle, MEWSTATS_COOKIE_VALUE_THROW_ANGLE_COUNT);
}

static void MenuSelect_ThrowTime(int client)
{
    Mewstats_CycleCookie(client, g_ckThrowTime, g_iThrowTime, MEWSTATS_COOKIE_VALUE_THROW_TIME_COUNT);
}

static void MenuSelect_ThrowDeviation(int client)
{
    Mewstats_CycleCookie(client, g_ckThrowDeviation, g_iThrowDeviation, MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_COUNT);
}

static void MenuSelect_ThrowStatus(int client)
{
    Mewstats_CycleCookie(client, g_ckThrowStatus, g_iThrowStatus, MEWSTATS_COOKIE_VALUE_THROW_STATUS_COUNT);
}

static void MenuSelect_SkyStats(int client)
{
    Mewstats_CycleCookie(client, g_ckSkyStats, g_iSkyStats, MEWSTATS_COOKIE_VALUE_SKY_STATS_COUNT);
}

static void MenuSelect_MlsStats(int client)
{
    Mewstats_CycleCookie(client, g_ckMlsStats, g_iMlsStats, MEWSTATS_COOKIE_VALUE_MLS_STATS_COUNT);
}

// static void MenuSelect_NadeVelocity(int client)
// {
//     Mewstats_CycleCookie(client, g_ckNadeVelocity, g_iNadeVelocity, MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_COUNT);
// }

// static void MenuSelect_PartnerStats(int client)
// {
//     Mewstats_CycleCookie(client, g_ckPartnerStats, g_iPartnerStats, MEWSTATS_COOKIE_VALUE_PARTNER_STATS_COUNT);
// }

static void MenuSelect_ShortNames(int client)
{
    Mewstats_CycleCookie(client, g_ckShortNames, g_iShortNames, MEWSTATS_COOKIE_VALUE_SHORT_NAMES_COUNT);
}

static void MenuSelect_CrouchName(int client)
{
    Mewstats_CycleCookie(client, g_ckCrouchName, g_iCrouchName, MEWSTATS_COOKIE_VALUE_CROUCH_NAME_COUNT);
}

static void MenuSelect_ColorValues(int client)
{
    Mewstats_CycleCookie(client, g_ckColorValues, g_iColorValues, MEWSTATS_COOKIE_VALUE_COLOR_VALUES_COUNT);
}

static void MenuSelect_ValuePrecision(int client)
{
    Mewstats_CycleCookie(client, g_ckValuePreicision, g_iValuePrecision, MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_COUNT);
}

static void MenuSelect_ChatTheme(int client)
{
    Mewstats_CycleCookie(client, g_ckChatTheme, g_iChatTheme, MEWSTATS_COOKIE_VALUE_CHAT_THEME_COUNT);
}

static void MenuSelect_ChatSeparator(int client)
{
    Mewstats_CycleCookie(client, g_ckChatSeparator, g_iChatSeparator, MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_COUNT);
}

static void MenuSelect_ChatSound(int client)
{
    Mewstats_CycleCookie(client, g_ckChatSound, g_iChatSound, MEWSTATS_COOKIE_VALUE_CHAT_SOUND_COUNT);
}

static void Mewstats_CycleCookie(int client, Cookie cookie, int storage[MAXPLAYERS + 1], int limit)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return;
    }

    storage[client] = (storage[client] + 1) % limit;
    cookie.SetInt(client, storage[client]);
}

static Action Command_All(int client, int argc)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    int snapshot = Mewstats_GetSnapshot(client);
    if (snapshot > 0)
    {
        // Saving Snapshot
        g_iLastBitflags[client] = snapshot;
        g_ckLastBitflags.SetInt(client, g_iLastBitflags[client]);

        // Turning Things Off
        g_iThrowSpeed[client] = MEWSTATS_COOKIE_VALUE_THROW_SPEED_FALSE;
        g_ckThrowSpeed.SetInt(client, g_iThrowSpeed[client]);

        g_iThrowAngle[client] = MEWSTATS_COOKIE_VALUE_THROW_ANGLE_FALSE;
        g_ckThrowAngle.SetInt(client, g_iThrowAngle[client]);

        g_iThrowTime[client] = MEWSTATS_COOKIE_VALUE_THROW_TIME_FALSE;
        g_ckThrowTime.SetInt(client, g_iThrowTime[client]);

        g_iThrowDeviation[client] = MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_FALSE;
        g_ckThrowDeviation.SetInt(client, g_iThrowDeviation[client]);

        g_iThrowStatus[client] = MEWSTATS_COOKIE_VALUE_THROW_STATUS_FALSE;
        g_ckThrowStatus.SetInt(client, g_iThrowStatus[client]);

        g_iSkyStats[client] = MEWSTATS_COOKIE_VALUE_SKY_STATS_FALSE;
        g_ckSkyStats.SetInt(client, g_iSkyStats[client]);

        g_iMlsStats[client] = MEWSTATS_COOKIE_VALUE_MLS_STATS_FALSE;
        g_ckMlsStats.SetInt(client, g_iMlsStats[client]);

        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sYou have%s disabled%s all boost stats", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE);

        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }
    }
    else
    {
        // Getting Snapshot
        int bitflags = g_iLastBitflags[client];
        if (bitflags == MEWSTATS_COOKIE_VALUE_LAST_BITFLAGS_UNKNOWN)
        {
            bitflags = 0;
            bitflags |= 1 << MEWSTATS_COOKIE_VALUE_THROW_SPEED_BIT;
            bitflags |= 1 << MEWSTATS_COOKIE_VALUE_THROW_ANGLE_BIT;
            bitflags |= 1 << MEWSTATS_COOKIE_VALUE_THROW_TIME_BIT;
            bitflags |= 1 << MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_BIT;
            bitflags |= 1 << MEWSTATS_COOKIE_VALUE_THROW_STATUS_BIT;
            bitflags |= 1 << MEWSTATS_COOKIE_VALUE_SKY_STATS_BIT;
            bitflags |= 1 << MEWSTATS_COOKIE_VALUE_MLS_STATS_BIT;
        }

        // Turning Things On
        g_iThrowSpeed[client] = Mewstats_IsFlag(bitflags, 1 << MEWSTATS_COOKIE_VALUE_THROW_SPEED_BIT) ? MEWSTATS_COOKIE_VALUE_THROW_SPEED_TRUE : MEWSTATS_COOKIE_VALUE_THROW_SPEED_FALSE;
        g_ckThrowSpeed.SetInt(client, g_iThrowSpeed[client]);

        g_iThrowAngle[client] = Mewstats_IsFlag(bitflags, 1 << MEWSTATS_COOKIE_VALUE_THROW_ANGLE_BIT) ? MEWSTATS_COOKIE_VALUE_THROW_ANGLE_TRUE : MEWSTATS_COOKIE_VALUE_THROW_ANGLE_FALSE;
        g_ckThrowAngle.SetInt(client, g_iThrowAngle[client]);

        g_iThrowTime[client] = Mewstats_IsFlag(bitflags, 1 << MEWSTATS_COOKIE_VALUE_THROW_TIME_BIT) ? MEWSTATS_COOKIE_VALUE_THROW_TIME_TRUE : MEWSTATS_COOKIE_VALUE_THROW_TIME_FALSE;
        g_ckThrowTime.SetInt(client, g_iThrowTime[client]);

        g_iThrowDeviation[client] = Mewstats_IsFlag(bitflags, 1 << MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_BIT) ? MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_TRUE : MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_FALSE;
        g_ckThrowDeviation.SetInt(client, g_iThrowDeviation[client]);

        g_iThrowStatus[client] = Mewstats_IsFlag(bitflags, 1 << MEWSTATS_COOKIE_VALUE_THROW_STATUS_BIT) ? MEWSTATS_COOKIE_VALUE_THROW_STATUS_TRUE : MEWSTATS_COOKIE_VALUE_THROW_STATUS_FALSE;
        g_ckThrowStatus.SetInt(client, g_iThrowStatus[client]);

        g_iSkyStats[client] = Mewstats_IsFlag(bitflags, 1 << MEWSTATS_COOKIE_VALUE_SKY_STATS_BIT) ? MEWSTATS_COOKIE_VALUE_SKY_STATS_TRUE : MEWSTATS_COOKIE_VALUE_SKY_STATS_FALSE;
        g_ckSkyStats.SetInt(client, g_iSkyStats[client]);

        g_iMlsStats[client] = Mewstats_IsFlag(bitflags, 1 << MEWSTATS_COOKIE_VALUE_MLS_STATS_BIT) ? MEWSTATS_COOKIE_VALUE_MLS_STATS_TRUE : MEWSTATS_COOKIE_VALUE_MLS_STATS_FALSE;
        g_ckMlsStats.SetInt(client, g_iMlsStats[client]);

        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sYou have%s enabled%s all boost stats", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }
    }

    return Plugin_Handled;
}

static Action Command_Snapshot(int client, int argc)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    int snapshot = Mewstats_GetSnapshot(client);
    int bitflags = g_iLastBitflags[client];

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sYour current & stored snapshots [%s%i%s;%s %i%s]", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, snapshot, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, bitflags, MEWSTATS_CHAT_COLOR_WHITE);

    if (szMessage[0] != '\0')
    {
        Mewstats_SayText2(client, true, szMessage);
    }
    return Plugin_Handled;
}

static int Mewstats_GetSnapshot(int client)
{
    int bitflags = 0;
    if (g_iThrowSpeed[client] == MEWSTATS_COOKIE_VALUE_THROW_SPEED_TRUE)
    {
        bitflags |= 1 << MEWSTATS_COOKIE_VALUE_THROW_SPEED_BIT;
    }
    if (g_iThrowAngle[client] == MEWSTATS_COOKIE_VALUE_THROW_ANGLE_TRUE)
    {
        bitflags |= 1 << MEWSTATS_COOKIE_VALUE_THROW_ANGLE_BIT;
    }
    if (g_iThrowTime[client] == MEWSTATS_COOKIE_VALUE_THROW_TIME_TRUE)
    {
        bitflags |= 1 << MEWSTATS_COOKIE_VALUE_THROW_TIME_BIT;
    }
    if (g_iThrowDeviation[client] == MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_TRUE)
    {
        bitflags |= 1 << MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_BIT;
    }
    if (g_iThrowStatus[client] == MEWSTATS_COOKIE_VALUE_THROW_STATUS_TRUE)
    {
        bitflags |= 1 << MEWSTATS_COOKIE_VALUE_THROW_STATUS_BIT;
    }
    if (g_iSkyStats[client] == MEWSTATS_COOKIE_VALUE_SKY_STATS_TRUE)
    {
        bitflags |= 1 << MEWSTATS_COOKIE_VALUE_SKY_STATS_BIT;
    }
    if (g_iMlsStats[client] == MEWSTATS_COOKIE_VALUE_MLS_STATS_TRUE)
    {
        bitflags |= 1 << MEWSTATS_COOKIE_VALUE_MLS_STATS_BIT;
    }
    return bitflags;
}

static void Mewstats_InitStateVars(int client)
{
    g_iThrowSpeed[client] = g_ckThrowSpeed.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_SPEED_DEFAULT);
    g_iThrowAngle[client] = g_ckThrowAngle.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_ANGLE_DEFAULT);
    g_iThrowTime[client] = g_ckThrowTime.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_TIME_DEFAULT);
    g_iThrowDeviation[client] = g_ckThrowDeviation.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_DEFAULT);
    g_iThrowStatus[client] = g_ckThrowStatus.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_STATUS_DEFAULT);
    g_iSkyStats[client] = g_ckSkyStats.GetInt(client, MEWSTATS_COOKIE_VALUE_SKY_STATS_DEFAULT);
    g_iMlsStats[client] = g_ckMlsStats.GetInt(client, MEWSTATS_COOKIE_VALUE_MLS_STATS_DEFAULT);
    // g_iNadeVelocity[client] = g_ckNadeVelocity.GetInt(client, MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_DEFAULT);
    // g_iPartnerStats[client] = g_ckPartnerStats.GetInt(client, MEWSTATS_COOKIE_VALUE_PARTNER_STATS_DEFAULT);
    g_iShortNames[client] = g_ckShortNames.GetInt(client, MEWSTATS_COOKIE_VALUE_SHORT_NAMES_DEFAULT);
    g_iCrouchName[client] = g_ckCrouchName.GetInt(client, MEWSTATS_COOKIE_VALUE_CROUCH_NAME_DEFAULT);
    g_iColorValues[client] = g_ckColorValues.GetInt(client, MEWSTATS_COOKIE_VALUE_COLOR_VALUES_DEFAULT);
    g_iValuePrecision[client] = g_ckValuePreicision.GetInt(client, MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DEFAULT);
    g_iChatTheme[client] = g_ckChatTheme.GetInt(client, MEWSTATS_COOKIE_VALUE_CHAT_THEME_DEFAULT);
    g_iChatSeparator[client] = g_ckChatSeparator.GetInt(client, MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_DEFAULT);
    g_iChatSound[client] = g_ckChatSound.GetInt(client, MEWSTATS_COOKIE_VALUE_CHAT_SOUND_DEFAULT);
    g_iLastBitflags[client] = g_ckLastBitflags.GetInt(client, MEWSTATS_COOKIE_VALUE_LAST_BITFLAGS_DEFAULT);
}

static void Mewstats_CreateGlobals()
{
    // Throw Speed
    g_szThrowSpeedModes[MEWSTATS_COOKIE_VALUE_THROW_SPEED_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szThrowSpeedModes[MEWSTATS_COOKIE_VALUE_THROW_SPEED_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Throw Angle
    g_szThrowAngleModes[MEWSTATS_COOKIE_VALUE_THROW_ANGLE_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szThrowAngleModes[MEWSTATS_COOKIE_VALUE_THROW_ANGLE_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Throw Time
    g_szThrowTimeModes[MEWSTATS_COOKIE_VALUE_THROW_TIME_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szThrowTimeModes[MEWSTATS_COOKIE_VALUE_THROW_TIME_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Throw Deviation
    g_szThrowDeviationModes[MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szThrowDeviationModes[MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Throw Status
    g_szThrowStatusModes[MEWSTATS_COOKIE_VALUE_THROW_STATUS_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szThrowStatusModes[MEWSTATS_COOKIE_VALUE_THROW_STATUS_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Sky Stats
    g_szSkyStatsModes[MEWSTATS_COOKIE_VALUE_SKY_STATS_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szSkyStatsModes[MEWSTATS_COOKIE_VALUE_SKY_STATS_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // MLS Stats
    g_szMlsStatsModes[MEWSTATS_COOKIE_VALUE_MLS_STATS_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szMlsStatsModes[MEWSTATS_COOKIE_VALUE_MLS_STATS_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // // Nade Velocity
    // g_szNadeVelocityModes[MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    // g_szNadeVelocityModes[MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_XY] = MEWSTATS_MENU_ITEM_XY;
    // g_szNadeVelocityModes[MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_XYZ] = MEWSTATS_MENU_ITEM_XYZ;

    // // Partner Stats
    // g_szPartnerStatsModes[MEWSTATS_COOKIE_VALUE_PARTNER_STATS_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    // g_szPartnerStatsModes[MEWSTATS_COOKIE_VALUE_PARTNER_STATS_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Short Names
    g_szShortNamesModes[MEWSTATS_COOKIE_VALUE_SHORT_NAMES_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szShortNamesModes[MEWSTATS_COOKIE_VALUE_SHORT_NAMES_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Crouch Name
    g_szCrouchNameModes[MEWSTATS_COOKIE_VALUE_CROUCH_NAME_DUCK] = MEWSTATS_MENU_ITEM_DUCK;
    g_szCrouchNameModes[MEWSTATS_COOKIE_VALUE_CROUCH_NAME_CROUCH] = MEWSTATS_MENU_ITEM_CROUCH;

    // Color Values
    g_szColorValuesModes[MEWSTATS_COOKIE_VALUE_COLOR_VALUES_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szColorValuesModes[MEWSTATS_COOKIE_VALUE_COLOR_VALUES_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Value Precision
    g_szValuePrecisionModes[MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ZERO] = MEWSTATS_MENU_ITEM_DOT_ZERO;
    g_szValuePrecisionModes[MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ONE] = MEWSTATS_MENU_ITEM_DOT_ONE;

    // Chat Theme
    g_szChatThemeModes[MEWSTATS_COOKIE_VALUE_CHAT_THEME_STANDARD] = MEWSTATS_MENU_ITEM_STANDARD;
    g_szChatThemeModes[MEWSTATS_COOKIE_VALUE_CHAT_THEME_LILAC] = MEWSTATS_MENU_ITEM_LILAC;
    g_szChatThemeModes[MEWSTATS_COOKIE_VALUE_CHAT_THEME_ICE] = MEWSTATS_MENU_ITEM_ICE;
    g_szChatThemeModes[MEWSTATS_COOKIE_VALUE_CHAT_THEME_MINT] = MEWSTATS_MENU_ITEM_MINT;

    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_STANDARD][MEWSTATS_THEME_COLOR_INDEX_BASE] = MEWSTATS_THEME_STANDARD_COLOR_BASE;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_STANDARD][MEWSTATS_THEME_COLOR_INDEX_ACCENT] = MEWSTATS_THEME_STANDARD_COLOR_ACCENT;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_STANDARD][MEWSTATS_THEME_COLOR_INDEX_SEPARATOR] = MEWSTATS_THEME_STANDARD_COLOR_SEPARATOR;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_STANDARD][MEWSTATS_THEME_COLOR_INDEX_MLS_BASE] = MEWSTATS_THEME_STANDARD_COLOR_MLS_BASE;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_STANDARD][MEWSTATS_THEME_COLOR_INDEX_MLS_ACCENT] = MEWSTATS_THEME_STANDARD_COLOR_MLS_ACCENT;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_STANDARD][MEWSTATS_THEME_COLOR_INDEX_MLS_SEPARATOR] = MEWSTATS_THEME_STANDARD_COLOR_MLS_SEPARATOR;

    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_LILAC][MEWSTATS_THEME_COLOR_INDEX_BASE] = MEWSTATS_THEME_LILAC_COLOR_BASE;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_LILAC][MEWSTATS_THEME_COLOR_INDEX_ACCENT] = MEWSTATS_THEME_LILAC_COLOR_ACCENT;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_LILAC][MEWSTATS_THEME_COLOR_INDEX_SEPARATOR] = MEWSTATS_THEME_LILAC_COLOR_SEPARATOR;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_LILAC][MEWSTATS_THEME_COLOR_INDEX_MLS_BASE] = MEWSTATS_THEME_LILAC_COLOR_MLS_BASE;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_LILAC][MEWSTATS_THEME_COLOR_INDEX_MLS_ACCENT] = MEWSTATS_THEME_LILAC_COLOR_MLS_ACCENT;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_LILAC][MEWSTATS_THEME_COLOR_INDEX_MLS_SEPARATOR] = MEWSTATS_THEME_LILAC_COLOR_MLS_SEPARATOR;

    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_ICE][MEWSTATS_THEME_COLOR_INDEX_BASE] = MEWSTATS_THEME_ICE_COLOR_BASE;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_ICE][MEWSTATS_THEME_COLOR_INDEX_ACCENT] = MEWSTATS_THEME_ICE_COLOR_ACCENT;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_ICE][MEWSTATS_THEME_COLOR_INDEX_SEPARATOR] = MEWSTATS_THEME_ICE_COLOR_SEPARATOR;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_ICE][MEWSTATS_THEME_COLOR_INDEX_MLS_BASE] = MEWSTATS_THEME_ICE_COLOR_MLS_BASE;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_ICE][MEWSTATS_THEME_COLOR_INDEX_MLS_ACCENT] = MEWSTATS_THEME_ICE_COLOR_MLS_ACCENT;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_ICE][MEWSTATS_THEME_COLOR_INDEX_MLS_SEPARATOR] = MEWSTATS_THEME_ICE_COLOR_MLS_SEPARATOR;

    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_MINT][MEWSTATS_THEME_COLOR_INDEX_BASE] = MEWSTATS_THEME_MINT_COLOR_BASE;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_MINT][MEWSTATS_THEME_COLOR_INDEX_ACCENT] = MEWSTATS_THEME_MINT_COLOR_ACCENT;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_MINT][MEWSTATS_THEME_COLOR_INDEX_SEPARATOR] = MEWSTATS_THEME_MINT_COLOR_SEPARATOR;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_MINT][MEWSTATS_THEME_COLOR_INDEX_MLS_BASE] = MEWSTATS_THEME_MINT_COLOR_MLS_BASE;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_MINT][MEWSTATS_THEME_COLOR_INDEX_MLS_ACCENT] = MEWSTATS_THEME_MINT_COLOR_MLS_ACCENT;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_MINT][MEWSTATS_THEME_COLOR_INDEX_MLS_SEPARATOR] = MEWSTATS_THEME_MINT_COLOR_MLS_SEPARATOR;

    // Chat Separator
    g_szChatSeparatorModes[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_SPACE] = MEWSTATS_MENU_ITEM_SPACE;
    g_szChatSeparatorModes[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_LINE] = MEWSTATS_MENU_ITEM_LINE;

    g_szChatSeparatorValues[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_SPACE] = MEWSTATS_CHAT_SEPARATOR_SPACE;
    g_szChatSeparatorValues[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_LINE] = MEWSTATS_CHAT_SEPARATOR_LINE;

    // Chat Sound
    g_szChatSoundModes[MEWSTATS_COOKIE_VALUE_CHAT_SOUND_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szChatSoundModes[MEWSTATS_COOKIE_VALUE_CHAT_SOUND_TRUE] = MEWSTATS_MENU_ITEM_TRUE;
}

static void Mewstats_CreateCookies()
{
    g_ckThrowSpeed = RegClientCookie(MEWSTATS_COOKIE_NAME_THROW_SPEED, MEWSTATS_COOKIE_DESCRIPTION_THROW_SPEED, CookieAccess_Protected);
    g_ckThrowAngle = RegClientCookie(MEWSTATS_COOKIE_NAME_THROW_ANGLE, MEWSTATS_COOKIE_DESCRIPTION_THROW_ANGLE, CookieAccess_Protected);
    g_ckThrowTime = RegClientCookie(MEWSTATS_COOKIE_NAME_THROW_TIME, MEWSTATS_COOKIE_DESCRIPTION_THROW_TIME, CookieAccess_Protected);
    g_ckThrowDeviation = RegClientCookie(MEWSTATS_COOKIE_NAME_THROW_DEVIATION, MEWSTATS_COOKIE_DESCRIPTION_THROW_DEVIATION, CookieAccess_Protected);
    g_ckThrowStatus = RegClientCookie(MEWSTATS_COOKIE_NAME_THROW_STATUS, MEWSTATS_COOKIE_DESCRIPTION_THROW_STATUS, CookieAccess_Protected);
    g_ckSkyStats = RegClientCookie(MEWSTATS_COOKIE_NAME_SKY_STATS, MEWSTATS_COOKIE_DESCRIPTION_SKY_STATS, CookieAccess_Protected);
    g_ckMlsStats = RegClientCookie(MEWSTATS_COOKIE_NAME_MLS_STATS, MEWSTATS_COOKIE_DESCRIPTION_MLS_STATS, CookieAccess_Protected);
    // g_ckNadeVelocity = RegClientCookie(MEWSTATS_COOKIE_NAME_NADE_VELOCITY, MEWSTATS_COOKIE_DESCRIPTION_NADE_VELOCITY, CookieAccess_Protected);
    // g_ckPartnerStats = RegClientCookie(MEWSTATS_COOKIE_NAME_PARTNER_STATS, MEWSTATS_COOKIE_DESCRIPTION_PARTNER_STATS, CookieAccess_Protected);
    g_ckShortNames = RegClientCookie(MEWSTATS_COOKIE_NAME_SHORT_NAMES, MEWSTATS_COOKIE_DESCRIPTION_SHORT_NAMES, CookieAccess_Protected);
    g_ckCrouchName = RegClientCookie(MEWSTATS_COOKIE_NAME_CROUCH_NAME, MEWSTATS_COOKIE_DESCRIPTION_CROUCH_NAME, CookieAccess_Protected);
    g_ckColorValues = RegClientCookie(MEWSTATS_COOKIE_NAME_COLOR_VALUES, MEWSTATS_COOKIE_DESCRIPTION_COLOR_VALUES, CookieAccess_Protected);
    g_ckValuePreicision = RegClientCookie(MEWSTATS_COOKIE_NAME_VALUE_PRECISION, MEWSTATS_COOKIE_DESCRIPTION_VALUE_PRECISION, CookieAccess_Protected);
    g_ckChatTheme = RegClientCookie(MEWSTATS_COOKIE_NAME_CHAT_THEME, MEWSTATS_COOKIE_DESCRIPTION_CHAT_THEME, CookieAccess_Protected);
    g_ckChatSeparator = RegClientCookie(MEWSTATS_COOKIE_NAME_CHAT_SEPARATOR, MEWSTATS_COOKIE_DESCRIPTION_CHAT_SEPARATOR, CookieAccess_Protected);
    g_ckChatSound = RegClientCookie(MEWSTATS_COOKIE_NAME_CHAT_SOUND, MEWSTATS_COOKIE_DESCRIPTION_CHAT_SOUND, CookieAccess_Protected);
    g_ckLastBitflags = RegClientCookie(MEWSTATS_COOKIE_NAME_LAST_BITFLAGS, MEWSTATS_COOKIE_DESCRIPTION_LAST_BITFLAGS, CookieAccess_Protected);
}

static void Mewstats_CreateCommands()
{
    RegConsoleCmd("sm_bs", Command_Stats);
    RegConsoleCmd("sm_bsall", Command_All);
    RegConsoleCmd("sm_bssnap", Command_Snapshot);
}

static void Mewstats_HookEvents()
{
    HookEvent(MEWSTATS_EVENT_PLAYER_JUMP, Event_PlayerJump, EventHookMode_Post);
}
