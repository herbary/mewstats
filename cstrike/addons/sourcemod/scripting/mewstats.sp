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

#include <base64>

#pragma newdecls required
#pragma semicolon 1

#define _MEWSTATS_PARTNER_UNKNOWN -1
#define _MEWSTATS_TICK_UNKNOWN -1
#define _MEWSTATS_THROW_TIME_TICKS 20
#define _MEWSTATS_DEVIATION_UNKNOWN 1337.0
#define _MEWSTATS_MLS_STORE_LIMIT 12

#define _MEWSTATS_SETTING_TAG 's'
#define _MEWSTATS_THEME_TAG 't'
#define _MEWSTATS_SETTING_RAW_LEN 23    // 1 byte of 's' tag + 3 bytes of settings + 1 byte of 't' tag + 18 bytes of colors
#define _MEWSTATS_THEME_RAW_LEN 19      // 1 byte of 't' tag + 18 bytes of colors

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
Cookie g_ckPartnerStats;
Cookie g_ckPartnerPrefix;
Cookie g_ckSkyStats;
Cookie g_ckSkyPrecision;
Cookie g_ckMlsStats;
Cookie g_ckShortNames;
Cookie g_ckCrouchName;
Cookie g_ckColorValues;
Cookie g_ckValuePreicision;
Cookie g_ckChatTheme;
Cookie g_ckChatSeparator;
Cookie g_ckChatSound;
Cookie g_ckMlsGain;
Cookie g_ckMlsDeviation;
Cookie g_ckCustomBaseColor;
Cookie g_ckCustomAccentColor;
Cookie g_ckCustomSeparatorColor;
Cookie g_ckCustomMlsBaseColor;
Cookie g_ckCustomMlsAccentColor;
Cookie g_ckCustomMlsSeparatorColor;
Cookie g_ckSettingsBackup;
Cookie g_ckStatsBackup;

int g_iThrowSpeed[MAXPLAYERS + 1];
int g_iThrowAngle[MAXPLAYERS + 1];
int g_iThrowTime[MAXPLAYERS + 1];
int g_iThrowDeviation[MAXPLAYERS + 1];
int g_iThrowStatus[MAXPLAYERS + 1];
int g_iPartnerStats[MAXPLAYERS + 1];
int g_iPartnerPrefix[MAXPLAYERS + 1];
int g_iSkyStats[MAXPLAYERS + 1];
int g_iSkyPrecision[MAXPLAYERS + 1];
int g_iMlsStats[MAXPLAYERS + 1];
int g_iShortNames[MAXPLAYERS + 1];
int g_iCrouchName[MAXPLAYERS + 1];
int g_iColorValues[MAXPLAYERS + 1];
int g_iValuePrecision[MAXPLAYERS + 1];
int g_iChatTheme[MAXPLAYERS + 1];
int g_iChatSeparator[MAXPLAYERS + 1];
int g_iChatSound[MAXPLAYERS + 1];
int g_iMlsGain[MAXPLAYERS + 1];
int g_iMlsDeviation[MAXPLAYERS + 1];
char g_szCustomBaseColor[MAXPLAYERS + 1][MEWSTATS_THEME_COLOR_SIZE];
char g_szCustomAccentColor[MAXPLAYERS + 1][MEWSTATS_THEME_COLOR_SIZE];
char g_szCustomSeparatorColor[MAXPLAYERS + 1][MEWSTATS_THEME_COLOR_SIZE];
char g_szCustomMlsBaseColor[MAXPLAYERS + 1][MEWSTATS_THEME_COLOR_SIZE];
char g_szCustomMlsAccentColor[MAXPLAYERS + 1][MEWSTATS_THEME_COLOR_SIZE];
char g_szCustomMlsSeparatorColor[MAXPLAYERS + 1][MEWSTATS_THEME_COLOR_SIZE];
char g_szSettingsBackup[MAXPLAYERS + 1][MEWSTATS_COOKIE_VALUE_SETTINGS_BACKUP_SIZE];
int g_iStatsBackup[MAXPLAYERS + 1];

char g_szThrowSpeedModes[MEWSTATS_COOKIE_VALUE_THROW_SPEED_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowAngleModes[MEWSTATS_COOKIE_VALUE_THROW_ANGLE_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowTimeModes[MEWSTATS_COOKIE_VALUE_THROW_TIME_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowDeviationModes[MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowStatusModes[MEWSTATS_COOKIE_VALUE_THROW_STATUS_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szPartnerStatsModes[MEWSTATS_COOKIE_VALUE_PARTNER_STATS_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szPartnerPrefixModes[MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szPartnerPrefixValues[MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_COUNT][MEWSTATS_CHAT_PREFIX_SIZE];
char g_szSkyStatsModes[MEWSTATS_COOKIE_VALUE_SKY_STATS_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szSkyPrecisionModes[MEWSTATS_COOKIE_VALUE_SKY_PRECISION_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szMlsStatsModes[MEWSTATS_COOKIE_VALUE_MLS_STATS_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szMlsGainModes[MEWSTATS_COOKIE_VALUE_MLS_GAIN_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szMlsDeviationModes[MEWSTATS_COOKIE_VALUE_MLS_DEVIATION_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szShortNamesModes[MEWSTATS_COOKIE_VALUE_SHORT_NAMES_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szCrouchNameModes[MEWSTATS_COOKIE_VALUE_CROUCH_NAME_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szColorValuesModes[MEWSTATS_COOKIE_VALUE_COLOR_VALUES_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szValuePrecisionModes[MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szChatThemeModes[MEWSTATS_COOKIE_VALUE_CHAT_THEME_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_COUNT][MEWSTATS_THEME_COLOR_COUNT][MEWSTATS_THEME_COLOR_SIZE];
char g_szChatSeparatorModes[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szChatSeparatorValues[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_COUNT][MEWSTATS_CHAT_SEPARATOR_SIZE];
char g_szChatSoundModes[MEWSTATS_COOKIE_VALUE_CHAT_SOUND_COUNT][MEWSTATS_MENU_ITEM_SIZE];

enum struct ThrowInfo
{
    int m_iTicks;
    float m_fTime;
    float m_fSpeed;
    float m_fAngle;
    float m_fDeviation;
    bool m_bDucked;
    bool m_bJumped;
}

ThrowInfo g_ThrowInfo[MAXPLAYERS + 1];

int g_iSkyJumpTick[MAXPLAYERS + 1];
int g_iFlashHitTick[MAXPLAYERS + 1];
int g_iMlsFlashCount[MAXPLAYERS + 1];
int g_iMlsLastPartner[MAXPLAYERS + 1];
float g_fMlsPreHitSpeed[MAXPLAYERS + 1][_MEWSTATS_MLS_STORE_LIMIT];
float g_fMlsHitSpeed[MAXPLAYERS + 1][_MEWSTATS_MLS_STORE_LIMIT];
float g_fMlsFirstHitSpeed[MAXPLAYERS + 1];
float g_fMlsHitDeviation[MAXPLAYERS + 1][_MEWSTATS_MLS_STORE_LIMIT];

#define _MEWSTATS_AWAIT_BASE_COLOR 1
#define _MEWSTATS_AWAIT_ACCENT_COLOR 2
#define _MEWSTATS_AWAIT_SEPARATOR_COLOR 3
#define _MEWSTATS_AWAIT_MLS_BASE_COLOR 4
#define _MEWSTATS_AWAIT_MLS_ACCENT_COLOR 5
#define _MEWSTATS_AWAIT_MLS_SEPARATOR_COLOR 6
#define _MEWSTATS_AWAIT_IMPORT_SETTINGS 7
#define _MEWSTATS_AWAIT_IMPORT_THEME 8
#define _MEWSTATS_AWAIT_MIN_COLOR _MEWSTATS_AWAIT_BASE_COLOR
#define _MEWSTATS_AWAIT_MAX_COLOR _MEWSTATS_AWAIT_MLS_SEPARATOR_COLOR
#define _MEWSTATS_AWAIT_MIN _MEWSTATS_AWAIT_BASE_COLOR
#define _MEWSTATS_AWAIT_MAX _MEWSTATS_AWAIT_IMPORT_THEME
#define _MEWSTATS_AWAIT_SIZE 256

int g_iAwaitInput[MAXPLAYERS + 1];
int g_iConfigMenuPosition[MAXPLAYERS + 1];

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
    Mewstats_HookCommands();

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
    g_ThrowInfo[client].m_iTicks = _MEWSTATS_TICK_UNKNOWN;
    g_ThrowInfo[client].m_fSpeed = 0.0;
    g_ThrowInfo[client].m_fAngle = 0.0;
    g_ThrowInfo[client].m_fDeviation = _MEWSTATS_DEVIATION_UNKNOWN;
    g_ThrowInfo[client].m_bDucked = false;
    g_ThrowInfo[client].m_bJumped = false;

    g_iSkyJumpTick[client] = _MEWSTATS_TICK_UNKNOWN;
    g_iFlashHitTick[client] = _MEWSTATS_TICK_UNKNOWN;
    g_iMlsFlashCount[client] = 0;
    g_iMlsLastPartner[client] = -1;
    g_iAwaitInput[client] = 0;
    g_iConfigMenuPosition[client] = 0;

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

    int flags = GetEntProp(client, Prop_Data, MEWSTATS_PROP_M_FFLAGS);
    MoveType movetype = GetEntityMoveType(client);
    if (Mewstats_IsFlag(flags, FL_ONGROUND) || movetype != MOVETYPE_WALK)
    {
        g_ThrowInfo[client].m_iTicks = _MEWSTATS_TICK_UNKNOWN;
    }
    if (g_ThrowInfo[client].m_iTicks != _MEWSTATS_TICK_UNKNOWN)
    {
        ++g_ThrowInfo[client].m_iTicks;
    }

    // OnPlayerRunCmd runs before StartTouch
    //  meaning at tick == 2 we had a time of 1 tick
    //  between current moment and the moment were
    //  sky or flash hit happened, so we're safe to release MLS
    if (g_iSkyJumpTick[client] != _MEWSTATS_TICK_UNKNOWN)
    {
        ++g_iSkyJumpTick[client];
        if (g_iSkyJumpTick[client] >= 2)
        {
            g_iSkyJumpTick[client] = _MEWSTATS_TICK_UNKNOWN;
        }
    }
    if (g_iFlashHitTick[client] != _MEWSTATS_TICK_UNKNOWN)
    {
        ++g_iFlashHitTick[client];
        if (g_iFlashHitTick[client] >= 2)
        {
            g_iFlashHitTick[client] = _MEWSTATS_TICK_UNKNOWN;

            float velocity[3];
            GetEntPropVector(client, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, velocity);

            velocity[2] = 0.0;
            float speed = GetVectorLength(velocity, false) + 0.0001;

            int index = g_iMlsFlashCount[client] - 1;
            if (index >= _MEWSTATS_MLS_STORE_LIMIT)
            {
                g_fMlsFirstHitSpeed[client] = g_fMlsHitSpeed[client][0];
            }
            Mewstats_InsertMlsFloat(client, g_fMlsHitSpeed, g_iMlsFlashCount[client] - 1, speed);
        }
    }

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

    g_iSkyJumpTick[client] = 0;

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
    if (g_iChatTheme[client] != MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
    }
    else
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szCustomBaseColor[client]);
    }
    if (szBaseColor[0] == '\0')
    {
        return;
    }

    char szAccentColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_TRUE)
    {
        int color[3];
        Mewstats_TransColor(strength / 289.0 * 100.0, 73.0, color);

        FormatEx(szAccentColor, sizeof(szAccentColor), "\x07%02X%02X%02X", color[0], color[1], color[2]);
    }
    else if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_FALSE)
    {
        if (g_iChatTheme[client] != MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
        {
            strcopy(szAccentColor, sizeof(szAccentColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_ACCENT]);
        }
        else
        {
            strcopy(szAccentColor, sizeof(szAccentColor), g_szCustomAccentColor[client]);
        }
    }
    if (szAccentColor[0] == '\0')
    {
        return;
    }

    char szStrength[32] = "";
    if (g_iSkyPrecision[client] == MEWSTATS_COOKIE_VALUE_SKY_PRECISION_MATCH)
    {
        if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ZERO)
        {
            FormatEx(szStrength, sizeof(szStrength), "%i", RoundToZero(strength));
        }
        else if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ONE)
        {
            FormatEx(szStrength, sizeof(szStrength), "%.1f", Mewstats_TruncateFloat(strength, 1));
        }
    }
    else if (g_iSkyPrecision[client] == MEWSTATS_COOKIE_VALUE_SKY_PRECISION_DOT_ZERO)
    {
        FormatEx(szStrength, sizeof(szStrength), "%i", RoundToZero(strength));
    }
    else if (g_iSkyPrecision[client] == MEWSTATS_COOKIE_VALUE_SKY_PRECISION_DOT_ONE)
    {
        FormatEx(szStrength, sizeof(szStrength), "%.1f", Mewstats_TruncateFloat(strength, 1));
    }
    else if (g_iSkyPrecision[client] == MEWSTATS_COOKIE_VALUE_SKY_PRECISION_DOT_TWO)
    {
        FormatEx(szStrength, sizeof(szStrength), "%.2f", Mewstats_TruncateFloat(strength, 2));
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

    g_iFlashHitTick[client] = 0;

    int thrower = GetEntPropEnt(entity, Prop_Data, MEWSTATS_PROP_M_HTHROWER);
    g_iMlsLastPartner[client] = thrower;

    ++g_iMlsFlashCount[client];

    float clientVelocity[3];
    GetEntPropVector(client, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, clientVelocity);

    clientVelocity[2] = 0.0;
    float clientSpeed = GetVectorLength(clientVelocity, false) + 0.0001;

    Mewstats_InsertMlsFloat(client, g_fMlsPreHitSpeed, g_iMlsFlashCount[client] - 1, clientSpeed);

    float clientDirection[3];
    if (clientSpeed > 0.2)
    {
        clientDirection[0] = clientVelocity[0];
        clientDirection[1] = clientVelocity[1];
    }
    else
    {
        clientDirection[0] = clientPosition[0] - entityPosition[0];
        clientDirection[1] = clientPosition[1] - entityPosition[1];
    }
    clientDirection[2] = 0.0;

    entityVelocity[2] = 0.0;
    float angle = Mewstats_RelativeDeviation(entityVelocity, clientDirection);

    Mewstats_InsertMlsFloat(client, g_fMlsHitDeviation, g_iMlsFlashCount[client] - 1, angle);
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

    char szBaseColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    char szAccentColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    char szSeparatorColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iChatTheme[client] != MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_MLS_BASE]);
        strcopy(szAccentColor, sizeof(szAccentColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_MLS_ACCENT]);
        strcopy(szSeparatorColor, sizeof(szSeparatorColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_MLS_SEPARATOR]);
    }
    else
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szCustomMlsBaseColor[client]);
        strcopy(szAccentColor, sizeof(szAccentColor), g_szCustomAccentColor[client]);
        strcopy(szSeparatorColor, sizeof(szSeparatorColor), g_szCustomSeparatorColor[client]);
    }
    if (szBaseColor[0] == '\0' || szAccentColor[0] == '\0' || szSeparatorColor[0] == '\0')
    {
        return;
    }

#define _MEWSTATS_MESSAGE_SIZE 256
#define _MEWSTATS_ELEMENT_SIZE 64
#define _MEWSTATS_ELEMENT_COUNT 4

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
        FormatEx(szHitNumber, sizeof(szHitNumber), "%sx%s%i", szBaseColor, szAccentColor, number);

        char szHitSpeed[_MEWSTATS_ELEMENT_SIZE] = "";
        FormatEx(szHitSpeed, sizeof(szHitSpeed), "%s%i%s ->%s %i", szAccentColor, RoundToZero(g_fMlsPreHitSpeed[target][i]), szBaseColor, szAccentColor, RoundToZero(g_fMlsHitSpeed[target][i]));

        char szHitGain[_MEWSTATS_ELEMENT_SIZE] = "";
        if (g_iMlsGain[client] == MEWSTATS_COOKIE_VALUE_MLS_GAIN_TRUE)
        {
            if (number > 1)
            {
                int gain;
                if (i == 0)
                {
                    gain = RoundToZero(g_fMlsPreHitSpeed[target][i]) - RoundToZero(g_fMlsFirstHitSpeed[target]);
                }
                else
                {
                    gain = RoundToZero(g_fMlsPreHitSpeed[target][i]) - RoundToZero(g_fMlsHitSpeed[target][i - 1]);
                }

                FormatEx(szHitGain, sizeof(szHitGain), "%s%s%i", szAccentColor, gain >= 0 ? "+" : "", gain);
            }
        }

        char szHitDeviation[_MEWSTATS_ELEMENT_SIZE] = "";
        if (g_iMlsDeviation[client] == MEWSTATS_COOKIE_VALUE_MLS_DEVIATION_TRUE)
        {
            FormatEx(szHitDeviation, sizeof(szHitDeviation), "%s%i°", szAccentColor, RoundToZero(g_fMlsHitDeviation[target][i]));
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
        if (szHitDeviation[0] != '\0' && kount < _MEWSTATS_ELEMENT_COUNT)
        {
            strcopy(szMessageElements[kount++], _MEWSTATS_ELEMENT_SIZE, szHitDeviation);
        }

        char szMessage[_MEWSTATS_MESSAGE_SIZE] = "";
        for (int j = 0; j < kount; ++j)
        {
            if (j >= 1)
            {
                Format(szMessage, sizeof(szMessage), "%s%s%s", szMessage, szSeparatorColor, MEWSTATS_CHAT_SEPARATOR_LINE);
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

static void Mewstats_InsertMlsFloat(int client, float storage[MAXPLAYERS + 1][_MEWSTATS_MLS_STORE_LIMIT], int index, float value)
{
    if (index >= _MEWSTATS_MLS_STORE_LIMIT)
    {
        Mewstats_ShiftMlsFloat(client, storage);
        index = _MEWSTATS_MLS_STORE_LIMIT - 1;
    }

    storage[client][index] = value;
}

static void Mewstats_ShiftMlsFloat(int client, float storage[MAXPLAYERS + 1][_MEWSTATS_MLS_STORE_LIMIT])
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
        g_ThrowInfo[thrower].m_iTicks = _MEWSTATS_TICK_UNKNOWN;
    }
    g_ThrowInfo[thrower].m_bDucked = Mewstats_IsFlag(flags, FL_DUCKING);

    float velocity[3];
    GetEntPropVector(thrower, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, velocity);

    velocity[2] = 0.0;
    g_ThrowInfo[thrower].m_fSpeed = GetVectorLength(velocity, false) + 0.0001;

    float angles[3];
    GetClientEyeAngles(thrower, angles);

    g_ThrowInfo[thrower].m_fAngle = -angles[0];

    float time = 0.0;
    if (g_ThrowInfo[thrower].m_iTicks != _MEWSTATS_TICK_UNKNOWN)
    {
        time = (g_ThrowInfo[thrower].m_iTicks - 1) * GetTickInterval();
        if (time < 0.0)
        {
            time = 0.0;
        }
        else
        {
            time += 0.0001;
        }
    }
    g_ThrowInfo[thrower].m_fTime = time;

    int partner = Mewstats_GetPartner(thrower);
    if (partner != _MEWSTATS_PARTNER_UNKNOWN)
    {
        float flashbangVelocity[3];
        GetEntPropVector(entity, Prop_Data, MEWSTATS_PROP_M_VECABSVELOCITY, flashbangVelocity);
        flashbangVelocity[2] = 0.0;

        float flashbangPosition[3];
        GetEntPropVector(entity, Prop_Data, MEWSTATS_PROP_M_VECORIGIN, flashbangPosition);

        float partnerPosition[3];
        GetEntPropVector(partner, Prop_Data, MEWSTATS_PROP_M_VECORIGIN, partnerPosition);

        float partnerDirection[3];
        partnerDirection[0] = partnerPosition[0] - flashbangPosition[0];
        partnerDirection[1] = partnerPosition[1] - flashbangPosition[1];
        partnerDirection[2] = 0.0;

        g_ThrowInfo[thrower].m_fDeviation = Mewstats_RelativeDeviation(flashbangVelocity, partnerDirection);
    }
    else
    {
        g_ThrowInfo[thrower].m_fDeviation = _MEWSTATS_DEVIATION_UNKNOWN;
    }

    Mewstats_PrintThrowStatsEx(thrower);
}

static void Mewstats_PrintThrowStatsEx(int thrower)
{
    if (!Mewstats_IsClientInGame(thrower))
    {
        return;
    }

    Mewstats_PrintThrowStats(false, thrower, thrower);
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

        Mewstats_PrintThrowStats(false, client, thrower);
    }

    int partner = Mewstats_GetPartner(thrower);
    if (partner != _MEWSTATS_PARTNER_UNKNOWN)
    {
        if (g_iPartnerStats[partner] == MEWSTATS_COOKIE_VALUE_PARTNER_STATS_TRUE)
        {
            Mewstats_PrintThrowStats(true, partner, thrower);
        }

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
            if (target != partner)
            {
                continue;
            }

            if (g_iPartnerStats[client] == MEWSTATS_COOKIE_VALUE_PARTNER_STATS_TRUE)
            {
                Mewstats_PrintThrowStats(true, client, thrower);
            }
        }
    }
}

static void Mewstats_PrintThrowStats(bool bPartner, int client, int thrower)
{
    if (!Mewstats_IsClientInGame(client) || !Mewstats_IsClientInGame(thrower))
    {
        return;
    }

    char szSeparatorColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iChatTheme[client] != MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
    {
        strcopy(szSeparatorColor, sizeof(szSeparatorColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_SEPARATOR]);
    }
    else
    {
        strcopy(szSeparatorColor, sizeof(szSeparatorColor), g_szCustomSeparatorColor[client]);
    }
    if (szSeparatorColor[0] == '\0')
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
    Mewstats_FormatThrowDeviation(client, thrower, szThrowDeviation, sizeof(szThrowDeviation));

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
            Format(szMessage, sizeof(szMessage), "%s%s%s", szMessage, szSeparatorColor, g_szChatSeparatorValues[g_iChatSeparator[client]]);
        }
        Format(szMessage, sizeof(szMessage), "%s%s", szMessage, szMessageElements[i]);
    }
    if (szMessage[0] != '\0' && bPartner)
    {
        if (g_iPartnerPrefix[client] != MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_NONE)
        {
            Format(szMessage, sizeof(szMessage), "%s%s %s", szSeparatorColor, g_szPartnerPrefixValues[g_iPartnerPrefix[client]], szMessage);
        }
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

    char szPhrase[MEWSTATS_MESSAGE_KEY_SIZE] = "";
    if (g_iShortNames[client] == MEWSTATS_COOKIE_VALUE_SHORT_NAMES_TRUE)
    {
        if (g_ThrowInfo[thrower].m_bDucked)
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
        if (g_ThrowInfo[thrower].m_bDucked)
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

    char szBaseColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iChatTheme[client] != MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
    }
    else
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szCustomBaseColor[client]);
    }
    if (szBaseColor[0] == '\0')
    {
        return;
    }

    char szAccentColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_TRUE)
    {
        int color[3];
        if (g_ThrowInfo[thrower].m_bDucked)
        {
            Mewstats_TransColor(g_ThrowInfo[thrower].m_fSpeed / 85.0 * 100.0, 70.0, color);
        }
        else
        {
            Mewstats_TransColor(g_ThrowInfo[thrower].m_fSpeed / 250.0 * 100.0, 90.0, color);
        }

        FormatEx(szAccentColor, sizeof(szAccentColor), "\x07%02X%02X%02X", color[0], color[1], color[2]);
    }
    else if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_FALSE)
    {
        if (g_iChatTheme[client] != MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
        {
            strcopy(szAccentColor, sizeof(szAccentColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_ACCENT]);
        }
        else
        {
            strcopy(szAccentColor, sizeof(szAccentColor), g_szCustomAccentColor[client]);
        }
    }
    if (szAccentColor[0] == '\0')
    {
        return;
    }

    char szSpeed[32] = "";
    if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ZERO)
    {
        FormatEx(szSpeed, sizeof(szSpeed), "%i", RoundToZero(g_ThrowInfo[thrower].m_fSpeed));
    }
    else if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ONE)
    {
        FormatEx(szSpeed, sizeof(szSpeed), "%.1f", Mewstats_TruncateFloat(g_ThrowInfo[thrower].m_fSpeed, 1));
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

    char szBaseColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    char szAccentColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iChatTheme[client] != MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
        strcopy(szAccentColor, sizeof(szAccentColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_ACCENT]);
    }
    else
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szCustomBaseColor[client]);
        strcopy(szAccentColor, sizeof(szAccentColor), g_szCustomAccentColor[client]);
    }
    if (szBaseColor[0] == '\0' || szAccentColor[0] == '\0')
    {
        return;
    }

    char szAngle[32] = "";
    if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ZERO)
    {
        FormatEx(szAngle, sizeof(szAngle), "%i", RoundToZero(g_ThrowInfo[thrower].m_fAngle));
    }
    else if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ONE)
    {
        FormatEx(szAngle, sizeof(szAngle), "%.1f", Mewstats_TruncateFloat(g_ThrowInfo[thrower].m_fAngle, 1));
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
    if (g_iThrowTime[client] != MEWSTATS_COOKIE_VALUE_THROW_TIME_INSTANT)
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

    char szBaseColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iChatTheme[client] != MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
    }
    else
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szCustomBaseColor[client]);
    }
    if (szBaseColor[0] == '\0')
    {
        return;
    }

    char szAccentColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_TRUE)
    {
        int color[3];
        Mewstats_TransColor(100.0 - g_ThrowInfo[thrower].m_fTime / 0.06 * 100.0, 42.0, color);

        FormatEx(szAccentColor, sizeof(szAccentColor), "\x07%02X%02X%02X", color[0], color[1], color[2]);
    }
    else if (g_iColorValues[client] == MEWSTATS_COOKIE_VALUE_COLOR_VALUES_FALSE)
    {
        if (g_iChatTheme[client] != MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
        {
            strcopy(szAccentColor, sizeof(szAccentColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_ACCENT]);
        }
        else
        {
            strcopy(szAccentColor, sizeof(szAccentColor), g_szCustomAccentColor[client]);
        }
    }
    if (szAccentColor[0] == '\0')
    {
        return;
    }

    char szTime[32] = "";
    FormatEx(szTime, sizeof(szTime), "%.2f", Mewstats_TruncateFloat(g_ThrowInfo[thrower].m_fTime, 2));
    if (szTime[0] == '\0')
    {
        return;
    }

    FormatEx(buff, size, "%T", szPhrase, client, szBaseColor, szAccentColor, szTime);
}

static void Mewstats_FormatThrowDeviation(int client, int thrower, char[] buff, int size)
{
    if (!Mewstats_IsClientInGame(client) || !Mewstats_IsClientInGame(thrower))
    {
        return;
    }
    if (g_iThrowDeviation[client] != MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_TRUE)
    {
        return;
    }
    if (g_ThrowInfo[thrower].m_fDeviation == _MEWSTATS_DEVIATION_UNKNOWN)
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

    char szBaseColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    char szAccentColor[MEWSTATS_THEME_COLOR_SIZE] = "";
    if (g_iChatTheme[client] != MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
        strcopy(szAccentColor, sizeof(szAccentColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_ACCENT]);
    }
    else
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szCustomBaseColor[client]);
        strcopy(szAccentColor, sizeof(szAccentColor), g_szCustomAccentColor[client]);
    }
    if (szBaseColor[0] == '\0' || szAccentColor[0] == '\0')
    {
        return;
    }

    char szAngle[32] = "";
    if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ZERO)
    {
        FormatEx(szAngle, sizeof(szAngle), "%i", RoundToZero(g_ThrowInfo[thrower].m_fDeviation));
    }
    else if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ONE)
    {
        FormatEx(szAngle, sizeof(szAngle), "%.1f", Mewstats_TruncateFloat(g_ThrowInfo[thrower].m_fDeviation, 1));
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
    if (g_ThrowInfo[thrower].m_iTicks != _MEWSTATS_TICK_UNKNOWN)
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
    if (g_iChatTheme[client] != MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szChatThemeColors[g_iChatTheme[client]][MEWSTATS_THEME_COLOR_INDEX_BASE]);
    }
    else
    {
        strcopy(szBaseColor, sizeof(szBaseColor), g_szCustomBaseColor[client]);
    }
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

    g_ThrowInfo[client].m_iTicks = 0;
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

    // Partner Stats
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_PARTNER_STATS_FMT, g_szPartnerStatsModes[g_iPartnerStats[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_PARTNER_STATS, szItem, GetFeatureStatus(FeatureType_Native, "Timer_GetPartner") == FeatureStatus_Available ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    // Partner Prefix
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_PARTNER_PREFIX_FMT, g_szPartnerPrefixModes[g_iPartnerPrefix[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_PARTNER_PREFIX, szItem, GetFeatureStatus(FeatureType_Native, "Timer_GetPartner") == FeatureStatus_Available ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    // Sky Stats
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_SKY_STATS_FMT, g_szSkyStatsModes[g_iSkyStats[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_SKY_STATS, szItem);

    // Sky Precision
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_SKY_PRECISION_FMT, g_szSkyPrecisionModes[g_iSkyPrecision[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_SKY_PRECISION, szItem);

    // MLS Stats
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_MLS_STATS_FMT, g_szMlsStatsModes[g_iMlsStats[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_MLS_STATS, szItem);

    // MLS Gain
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_MLS_GAIN_FMT, g_szMlsGainModes[g_iMlsGain[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_MLS_GAIN, szItem);

    // MLS Deviation
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_MLS_DEVIATION_FMT, g_szMlsDeviationModes[g_iMlsDeviation[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_MLS_DEVIATION, szItem);

    for (int i = 0; i < 2; ++i)
    {
        menu.AddItem("", "", ITEMDRAW_SPACER);
    }

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
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_PARTNER_STATS))
    {
        MenuSelect_PartnerStats(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_PARTNER_PREFIX))
    {
        MenuSelect_PartnerPrefix(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_SKY_STATS))
    {
        MenuSelect_SkyStats(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_SKY_PRECISION))
    {
        MenuSelect_SkyPrecision(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_MLS_STATS))
    {
        MenuSelect_MlsStats(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_MLS_GAIN))
    {
        MenuSelect_MlsGain(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_MLS_DEVIATION))
    {
        MenuSelect_MlsDeviation(client);
    }
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

static void MenuSelect_PartnerStats(int client)
{
    Mewstats_CycleCookie(client, g_ckPartnerStats, g_iPartnerStats, MEWSTATS_COOKIE_VALUE_PARTNER_STATS_COUNT);
}

static void MenuSelect_PartnerPrefix(int client)
{
    Mewstats_CycleCookie(client, g_ckPartnerPrefix, g_iPartnerPrefix, MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_COUNT);
}

static void MenuSelect_SkyStats(int client)
{
    Mewstats_CycleCookie(client, g_ckSkyStats, g_iSkyStats, MEWSTATS_COOKIE_VALUE_SKY_STATS_COUNT);
}

static void MenuSelect_SkyPrecision(int client)
{
    Mewstats_CycleCookie(client, g_ckSkyPrecision, g_iSkyPrecision, MEWSTATS_COOKIE_VALUE_SKY_PRECISION_COUNT);
}

static void MenuSelect_MlsStats(int client)
{
    Mewstats_CycleCookie(client, g_ckMlsStats, g_iMlsStats, MEWSTATS_COOKIE_VALUE_MLS_STATS_COUNT);
}

static void MenuSelect_MlsGain(int client)
{
    Mewstats_CycleCookie(client, g_ckMlsGain, g_iMlsGain, MEWSTATS_COOKIE_VALUE_MLS_GAIN_COUNT);
}

static void MenuSelect_MlsDeviation(int client)
{
    Mewstats_CycleCookie(client, g_ckMlsDeviation, g_iMlsDeviation, MEWSTATS_COOKIE_VALUE_MLS_DEVIATION_COUNT);
}

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
    int count = MEWSTATS_COOKIE_VALUE_CHAT_THEME_COUNT;
    if (!Mewstats_IsCustomThemeComplete(client))
    {
        count = MEWSTATS_THEME_COUNT;
    }

    Mewstats_CycleCookie(client, g_ckChatTheme, g_iChatTheme, count);
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

#define _MEWSTATS_THROW_SPEED_SHIFT 0
#define _MEWSTATS_THROW_ANGLE_SHIFT 1
#define _MEWSTATS_THROW_TIME_SHIFT 2
#define _MEWSTATS_THROW_DEVIATION_SHIFT 4
#define _MEWSTATS_THROW_STATUS_SHIFT 5
#define _MEWSTATS_SKY_STATS_SHIFT 6
#define _MEWSTATS_MLS_STATS_SHIFT 7

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
        g_iStatsBackup[client] = snapshot;
        g_ckStatsBackup.SetInt(client, g_iStatsBackup[client]);

        // Turning Things Off
        g_iThrowSpeed[client] = MEWSTATS_COOKIE_VALUE_THROW_SPEED_FALSE;
        g_iThrowAngle[client] = MEWSTATS_COOKIE_VALUE_THROW_ANGLE_FALSE;
        g_iThrowTime[client] = MEWSTATS_COOKIE_VALUE_THROW_TIME_FALSE;
        g_iThrowDeviation[client] = MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_FALSE;
        g_iThrowStatus[client] = MEWSTATS_COOKIE_VALUE_THROW_STATUS_FALSE;
        g_iSkyStats[client] = MEWSTATS_COOKIE_VALUE_SKY_STATS_FALSE;
        g_iMlsStats[client] = MEWSTATS_COOKIE_VALUE_MLS_STATS_FALSE;

        g_ckThrowSpeed.SetInt(client, g_iThrowSpeed[client]);
        g_ckThrowAngle.SetInt(client, g_iThrowAngle[client]);
        g_ckThrowTime.SetInt(client, g_iThrowTime[client]);
        g_ckThrowDeviation.SetInt(client, g_iThrowDeviation[client]);
        g_ckThrowStatus.SetInt(client, g_iThrowStatus[client]);
        g_ckSkyStats.SetInt(client, g_iSkyStats[client]);
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
        int data = g_iStatsBackup[client];
        if (data == MEWSTATS_COOKIE_VALUE_STATS_BACKUP_UNKNOWN)
        {
            data = 0;
            data |= (MEWSTATS_COOKIE_VALUE_THROW_SPEED_TRUE & MEWSTATS_COOKIE_VALUE_THROW_SPEED_MASK) << _MEWSTATS_THROW_SPEED_SHIFT;
            data |= (MEWSTATS_COOKIE_VALUE_THROW_ANGLE_TRUE & MEWSTATS_COOKIE_VALUE_THROW_ANGLE_MASK) << _MEWSTATS_THROW_ANGLE_SHIFT;
            data |= (MEWSTATS_COOKIE_VALUE_THROW_TIME_INSTANT & MEWSTATS_COOKIE_VALUE_THROW_TIME_MASK) << _MEWSTATS_THROW_TIME_SHIFT;
            data |= (MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_TRUE & MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_MASK) << _MEWSTATS_THROW_DEVIATION_SHIFT;
            data |= (MEWSTATS_COOKIE_VALUE_THROW_STATUS_TRUE & MEWSTATS_COOKIE_VALUE_THROW_STATUS_MASK) << _MEWSTATS_THROW_STATUS_SHIFT;
            data |= (MEWSTATS_COOKIE_VALUE_SKY_STATS_TRUE & MEWSTATS_COOKIE_VALUE_SKY_STATS_MASK) << _MEWSTATS_SKY_STATS_SHIFT;
            data |= (MEWSTATS_COOKIE_VALUE_MLS_STATS_TRUE & MEWSTATS_COOKIE_VALUE_MLS_STATS_MASK) << _MEWSTATS_MLS_STATS_SHIFT;
        }

        // Turning Things On
        g_iThrowSpeed[client] = (data >> _MEWSTATS_THROW_SPEED_SHIFT) & MEWSTATS_COOKIE_VALUE_THROW_SPEED_MASK;
        g_iThrowAngle[client] = (data >> _MEWSTATS_THROW_ANGLE_SHIFT) & MEWSTATS_COOKIE_VALUE_THROW_ANGLE_MASK;
        g_iThrowTime[client] = (data >> _MEWSTATS_THROW_TIME_SHIFT) & MEWSTATS_COOKIE_VALUE_THROW_TIME_MASK;
        g_iThrowDeviation[client] = (data >> _MEWSTATS_THROW_DEVIATION_SHIFT) & MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_MASK;
        g_iThrowStatus[client] = (data >> _MEWSTATS_THROW_STATUS_SHIFT) & MEWSTATS_COOKIE_VALUE_THROW_STATUS_MASK;
        g_iSkyStats[client] = (data >> _MEWSTATS_SKY_STATS_SHIFT) & MEWSTATS_COOKIE_VALUE_SKY_STATS_MASK;
        g_iMlsStats[client] = (data >> _MEWSTATS_MLS_STATS_SHIFT) & MEWSTATS_COOKIE_VALUE_MLS_STATS_MASK;

        g_ckThrowSpeed.SetInt(client, g_iThrowSpeed[client]);
        g_ckThrowAngle.SetInt(client, g_iThrowAngle[client]);
        g_ckThrowTime.SetInt(client, g_iThrowTime[client]);
        g_ckThrowDeviation.SetInt(client, g_iThrowDeviation[client]);
        g_ckThrowStatus.SetInt(client, g_iThrowStatus[client]);
        g_ckSkyStats.SetInt(client, g_iSkyStats[client]);
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
    int backup = g_iStatsBackup[client];

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sYour current & stored snapshots [%s%i%s;%s %i%s]", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, snapshot, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, backup, MEWSTATS_CHAT_COLOR_WHITE);
    if (szMessage[0] != '\0')
    {
        Mewstats_SayText2(client, true, szMessage);
    }

    return Plugin_Handled;
}

static int Mewstats_GetSnapshot(int client)
{
    int data = 0;
    data |= (g_iThrowSpeed[client] & MEWSTATS_COOKIE_VALUE_THROW_SPEED_MASK) << _MEWSTATS_THROW_SPEED_SHIFT;
    data |= (g_iThrowAngle[client] & MEWSTATS_COOKIE_VALUE_THROW_ANGLE_MASK) << _MEWSTATS_THROW_ANGLE_SHIFT;
    data |= (g_iThrowTime[client] & MEWSTATS_COOKIE_VALUE_THROW_TIME_MASK) << _MEWSTATS_THROW_TIME_SHIFT;
    data |= (g_iThrowDeviation[client] & MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_MASK) << _MEWSTATS_THROW_DEVIATION_SHIFT;
    data |= (g_iThrowStatus[client] & MEWSTATS_COOKIE_VALUE_THROW_STATUS_MASK) << _MEWSTATS_THROW_STATUS_SHIFT;
    data |= (g_iSkyStats[client] & MEWSTATS_COOKIE_VALUE_SKY_STATS_MASK) << _MEWSTATS_SKY_STATS_SHIFT;
    data |= (g_iMlsStats[client] & MEWSTATS_COOKIE_VALUE_MLS_STATS_MASK) << _MEWSTATS_MLS_STATS_SHIFT;
    return data;
}

#undef _MEWSTATS_THROW_SPEED_SHIFT
#undef _MEWSTATS_THROW_ANGLE_SHIFT
#undef _MEWSTATS_THROW_TIME_SHIFT
#undef _MEWSTATS_THROW_DEVIATION_SHIFT
#undef _MEWSTATS_THROW_STATUS_SHIFT
#undef _MEWSTATS_SKY_STATS_SHIFT
#undef _MEWSTATS_MLS_STATS_SHIFT

static Action Command_Import(int client, int argc)
{
    if (!Mewstats_IsClientInGame(client) || argc < 1)
    {
        return Plugin_Handled;
    }

    char szText[256] = "";
    GetCmdArg(1, szText, sizeof(szText));

    TrimString(szText);
    StripQuotes(szText);

    if (!Mewstats_ImportSettings(client, szText))
    {
        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sYour settings%s code%s is%s invalid", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_DARK_RED);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }

        return Plugin_Handled;
    }

    bool flag = true;
    if (argc > 1)
    {
        char arg[64] = "";
        GetCmdArg(2, arg, sizeof(arg));

        TrimString(arg);
        StripQuotes(arg);

        int j = 1;
        int c = StringToIntEx(arg, j);

        flag = !(c > 0 && j == 0);
    }

    if (flag)
    {
        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sYour settings updated from%s %s", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, szText);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }
    }
    return Plugin_Handled;
}

static Action Command_Export(int client, int argc)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    char code[MEWSTATS_COOKIE_VALUE_SETTINGS_BACKUP_SIZE] = "";
    Mewstats_ExportSettings(client, code, sizeof(code));

    if (code[0] == '\0')
    {
        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sWe could not generate your settings%s code%s; something went wrong", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }
        return Plugin_Handled;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%s%s", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, code);
    if (szMessage[0] != '\0')
    {
        Mewstats_SayText2(client, true, szMessage);
    }

    return Plugin_Handled;
}

static Action Command_Config(int client, int argc)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    Menu_Config(client, 0);
    return Plugin_Handled;
}

static void Menu_Config(int client, int position)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return;
    }

    Menu menu = new Menu(MenuHandler_Config);
    menu.SetTitle("Boost Stats\n ");

    char szItem[MEWSTATS_MENU_ITEM_SIZE];

    if (g_iAwaitInput[client] != _MEWSTATS_AWAIT_IMPORT_SETTINGS)
    {
        strcopy(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_IMPORT_SETTINGS);
    }
    else
    {
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_AWAIT_IMPORT_SETTINGS_FMT, MEWSTATS_MENU_ITEM_AWAITING);
    }
    menu.AddItem(MEWSTATS_MENU_SELECT_IMPORT_SETTINGS, szItem);
    menu.AddItem(MEWSTATS_MENU_SELECT_EXPORT_SETTINGS, MEWSTATS_MENU_ITEM_EXPORT_SETTINGS);
    if (g_iAwaitInput[client] != _MEWSTATS_AWAIT_IMPORT_THEME)
    {
        strcopy(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_IMPORT_THEME);
    }
    else
    {
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_AWAIT_IMPORT_THEME_FMT, MEWSTATS_MENU_ITEM_AWAITING);
    }
    menu.AddItem(MEWSTATS_MENU_SELECT_IMPORT_THEME, szItem);
    menu.AddItem(MEWSTATS_MENU_SELECT_EXPORT_THEME, MEWSTATS_MENU_ITEM_EXPORT_THEME);
    menu.AddItem(MEWSTATS_MENU_SELECT_SAVE_SETTINGS, MEWSTATS_MENU_ITEM_SAVE_SETTINGS);
    menu.AddItem(MEWSTATS_MENU_SELECT_BACKUP_SETTINGS, MEWSTATS_MENU_ITEM_BACKUP_SETTINGS);
    menu.AddItem(MEWSTATS_MENU_SELECT_CANCEL_CHAT_INPUT, MEWSTATS_MENU_ITEM_CANCEL_CHAT_INPUT);

    char szColor[MEWSTATS_MENU_ITEM_SIZE];

    if (g_iAwaitInput[client] != _MEWSTATS_AWAIT_BASE_COLOR)
    {
        Mewstats_ThemeColorMenuItem(szColor, sizeof(szColor), g_szCustomBaseColor[client], MEWSTATS_THEME_COLOR_SIZE);
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_BASE_COLOR_FMT, szColor);
    }
    else
    {
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_BASE_COLOR_FMT, MEWSTATS_MENU_ITEM_AWAITING);
    }
    menu.AddItem(MEWSTATS_MENU_SELECT_BASE_COLOR, szItem);

    if (g_iAwaitInput[client] != _MEWSTATS_AWAIT_ACCENT_COLOR)
    {
        Mewstats_ThemeColorMenuItem(szColor, sizeof(szColor), g_szCustomAccentColor[client], MEWSTATS_THEME_COLOR_SIZE);
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_ACCENT_COLOR_FMT, szColor);
    }
    else
    {
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_ACCENT_COLOR_FMT, MEWSTATS_MENU_ITEM_AWAITING);
    }
    menu.AddItem(MEWSTATS_MENU_SELECT_ACCENT_COLOR, szItem);

    if (g_iAwaitInput[client] != _MEWSTATS_AWAIT_SEPARATOR_COLOR)
    {
        Mewstats_ThemeColorMenuItem(szColor, sizeof(szColor), g_szCustomSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE);
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_SEPARATOR_COLOR_FMT, szColor);
    }
    else
    {
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_SEPARATOR_COLOR_FMT, MEWSTATS_MENU_ITEM_AWAITING);
    }
    menu.AddItem(MEWSTATS_MENU_SELECT_SEPARATOR_COLOR, szItem);

    if (g_iAwaitInput[client] != _MEWSTATS_AWAIT_MLS_BASE_COLOR)
    {
        Mewstats_ThemeColorMenuItem(szColor, sizeof(szColor), g_szCustomMlsBaseColor[client], MEWSTATS_THEME_COLOR_SIZE);
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_MLS_BASE_COLOR_FMT, szColor);
    }
    else
    {
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_MLS_BASE_COLOR_FMT, MEWSTATS_MENU_ITEM_AWAITING);
    }
    menu.AddItem(MEWSTATS_MENU_SELECT_MLS_BASE_COLOR, szItem);

    if (g_iAwaitInput[client] != _MEWSTATS_AWAIT_MLS_ACCENT_COLOR)
    {
        Mewstats_ThemeColorMenuItem(szColor, sizeof(szColor), g_szCustomMlsAccentColor[client], MEWSTATS_THEME_COLOR_SIZE);
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_MLS_ACCENT_COLOR_FMT, szColor);
    }
    else
    {
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_MLS_ACCENT_COLOR_FMT, MEWSTATS_MENU_ITEM_AWAITING);
    }
    menu.AddItem(MEWSTATS_MENU_SELECT_MLS_ACCENT_COLOR, szItem);

    if (g_iAwaitInput[client] != _MEWSTATS_AWAIT_MLS_SEPARATOR_COLOR)
    {
        Mewstats_ThemeColorMenuItem(szColor, sizeof(szColor), g_szCustomMlsSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE);
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_MLS_SEPARATOR_COLOR_FMT, szColor);
    }
    else
    {
        FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_MLS_SEPARATOR_COLOR_FMT, MEWSTATS_MENU_ITEM_AWAITING);
    }
    menu.AddItem(MEWSTATS_MENU_SELECT_MLS_SEPARATOR_COLOR, szItem);

    menu.AddItem(MEWSTATS_MENU_SELECT_CANCEL_CHAT_INPUT, MEWSTATS_MENU_ITEM_CANCEL_CHAT_INPUT);

    menu.ExitBackButton = false;
    menu.ExitButton = true;

    menu.DisplayAt(client, position, MENU_TIME_FOREVER);
}

static void MenuHandler_Config(Menu menu, MenuAction action, int client, int index)
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

    if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_IMPORT_SETTINGS))
    {
        MenuSelect_ImportSettings(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_EXPORT_SETTINGS))
    {
        MenuSelect_ExportSettings(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_IMPORT_THEME))
    {
        MenuSelect_ImportTheme(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_EXPORT_THEME))
    {
        MenuSelect_ExportTheme(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_SAVE_SETTINGS))
    {
        MenuSelect_SaveSettings(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_BACKUP_SETTINGS))
    {
        MenuSelect_BackupSettings(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_BASE_COLOR))
    {
        MenuSelect_BaseColor(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_ACCENT_COLOR))
    {
        MenuSelect_AccentColor(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_SEPARATOR_COLOR))
    {
        MenuSelect_SeparatorColor(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_MLS_BASE_COLOR))
    {
        MenuSelect_MlsBaseColor(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_MLS_ACCENT_COLOR))
    {
        MenuSelect_MlsAccentColor(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_MLS_SEPARATOR_COLOR))
    {
        MenuSelect_MlsSeparatorColor(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_CANCEL_CHAT_INPUT))
    {
        MenuSelect_CancelChatInput(client);
    }

    g_iConfigMenuPosition[client] = GetMenuSelectionPosition();
    Menu_Config(client, g_iConfigMenuPosition[client]);
}

static void MenuSelect_ImportSettings(int client)
{
    if (g_iAwaitInput[client] == _MEWSTATS_AWAIT_IMPORT_SETTINGS)
    {
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sType a settings%s code%s in the chat to import; or%s cancel", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER);
    if (szMessage[0] == '\0')
    {
        return;
    }

    Mewstats_SayText2(client, true, szMessage);
    g_iAwaitInput[client] = _MEWSTATS_AWAIT_IMPORT_SETTINGS;
}

static void MenuSelect_ExportSettings(int client)
{
    char code[MEWSTATS_COOKIE_VALUE_SETTINGS_BACKUP_SIZE] = "";
    Mewstats_ExportSettings(client, code, sizeof(code));

    if (code[0] == '\0')
    {
        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sWe could not generate your settings%s code%s; something went wrong", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%s%s", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, code);
    if (szMessage[0] != '\0')
    {
        Mewstats_SayText2(client, true, szMessage);
    }
}

static void MenuSelect_ImportTheme(int client)
{
    if (g_iAwaitInput[client] == _MEWSTATS_AWAIT_IMPORT_THEME)
    {
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sType a theme%s code%s in the chat to import; or%s cancel", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER);
    if (szMessage[0] == '\0')
    {
        return;
    }

    Mewstats_SayText2(client, true, szMessage);
    g_iAwaitInput[client] = _MEWSTATS_AWAIT_IMPORT_THEME;
}

static void MenuSelect_ExportTheme(int client)
{
    char code[MEWSTATS_COOKIE_VALUE_SETTINGS_BACKUP_SIZE] = "";
    Mewstats_ExportTheme(client, code, sizeof(code));

    if (code[0] == '\0')
    {
        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sWe could not generate your theme%s code%s; your theme may be incomplete", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%s%s", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, code);
    if (szMessage[0] != '\0')
    {
        Mewstats_SayText2(client, true, szMessage);
    }
}

static void MenuSelect_SaveSettings(int client)
{
    char code[MEWSTATS_COOKIE_VALUE_SETTINGS_BACKUP_SIZE] = "";
    Mewstats_ExportSettings(client, code, sizeof(code));

    if (code[0] == '\0')
    {
        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sWe could not save your settings; something went wrong", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }
        return;
    }

    g_ckSettingsBackup.Set(client, code);

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sYour settings saved under%s %s", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, code);
    if (szMessage[0] != '\0')
    {
        Mewstats_SayText2(client, true, szMessage);
    }
}

static void MenuSelect_BackupSettings(int client)
{
    char code[MEWSTATS_COOKIE_VALUE_SETTINGS_BACKUP_SIZE] = "";
    g_ckSettingsBackup.Get(client, code, sizeof(code));

    if (code[0] == '\0')
    {
        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sYou have not saved your settings yet", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }
        return;
    }

    if (!Mewstats_ImportSettings(client, code))
    {
        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sWe could not restore your settings; your backup may be corrupted", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sYour settings restored from%s %s", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, code);
    if (szMessage[0] != '\0')
    {
        Mewstats_SayText2(client, true, szMessage);
    }
}

static void MenuSelect_BaseColor(int client)
{
    if (g_iAwaitInput[client] == _MEWSTATS_AWAIT_BASE_COLOR)
    {
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sType a custom theme%s base color%s #RRGGBB in the chat; or%s cancel", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER);
    if (szMessage[0] == '\0')
    {
        return;
    }

    Mewstats_SayText2(client, true, szMessage);
    g_iAwaitInput[client] = _MEWSTATS_AWAIT_BASE_COLOR;
}

static void MenuSelect_AccentColor(int client)
{
    if (g_iAwaitInput[client] == _MEWSTATS_AWAIT_ACCENT_COLOR)
    {
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sType a custom theme%s accent color%s #RRGGBB in the chat; or%s cancel", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER);
    if (szMessage[0] == '\0')
    {
        return;
    }

    Mewstats_SayText2(client, true, szMessage);
    g_iAwaitInput[client] = _MEWSTATS_AWAIT_ACCENT_COLOR;
}

static void MenuSelect_SeparatorColor(int client)
{
    if (g_iAwaitInput[client] == _MEWSTATS_AWAIT_SEPARATOR_COLOR)
    {
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sType a custom theme%s separator color%s #RRGGBB in the chat; or%s cancel", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER);
    if (szMessage[0] == '\0')
    {
        return;
    }

    Mewstats_SayText2(client, true, szMessage);
    g_iAwaitInput[client] = _MEWSTATS_AWAIT_SEPARATOR_COLOR;
}

static void MenuSelect_MlsBaseColor(int client)
{
    if (g_iAwaitInput[client] == _MEWSTATS_AWAIT_MLS_BASE_COLOR)
    {
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sType a custom theme%s MLS base color%s #RRGGBB in the chat; or%s cancel", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER);
    if (szMessage[0] == '\0')
    {
        return;
    }

    Mewstats_SayText2(client, true, szMessage);
    g_iAwaitInput[client] = _MEWSTATS_AWAIT_MLS_BASE_COLOR;
}

static void MenuSelect_MlsAccentColor(int client)
{
    if (g_iAwaitInput[client] == _MEWSTATS_AWAIT_MLS_ACCENT_COLOR)
    {
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sType a custom theme%s MLS accent color%s #RRGGBB in the chat; or%s cancel", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER);
    if (szMessage[0] == '\0')
    {
        return;
    }

    Mewstats_SayText2(client, true, szMessage);
    g_iAwaitInput[client] = _MEWSTATS_AWAIT_MLS_ACCENT_COLOR;
}

static void MenuSelect_MlsSeparatorColor(int client)
{
    if (g_iAwaitInput[client] == _MEWSTATS_AWAIT_MLS_SEPARATOR_COLOR)
    {
        return;
    }

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sType a custom theme%s MLS separator color%s #RRGGBB in the chat; or%s cancel", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER);
    if (szMessage[0] == '\0')
    {
        return;
    }

    Mewstats_SayText2(client, true, szMessage);
    g_iAwaitInput[client] = _MEWSTATS_AWAIT_MLS_SEPARATOR_COLOR;
}

static void MenuSelect_CancelChatInput(int client)
{
    if (g_iAwaitInput[client] < _MEWSTATS_AWAIT_MIN || g_iAwaitInput[client] > _MEWSTATS_AWAIT_MAX)
    {
        return;
    }

    g_iAwaitInput[client] = 0;

    char szMessage[256] = "";
    FormatEx(szMessage, sizeof(szMessage), "%s%sYou have%s canceled%s the chat input", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE);
    if (szMessage[0] != '\0')
    {
        Mewstats_SayText2(client, true, szMessage);
    }
}

static Action Listener_AwaitInput(int client, const char[] command, int argc)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return Plugin_Continue;
    }
    if (g_iAwaitInput[client] < _MEWSTATS_AWAIT_MIN || g_iAwaitInput[client] > _MEWSTATS_AWAIT_MAX)
    {
        return Plugin_Continue;
    }

    char szText[_MEWSTATS_AWAIT_SIZE] = "";
    GetCmdArgString(szText, sizeof(szText));

    TrimString(szText);
    StripQuotes(szText);

    if (szText[0] == '/' || szText[0] == '!')
    {
        return Plugin_Continue;
    }

    if (StrContains(szText, "cancel", false) != -1)
    {
        g_iAwaitInput[client] = 0;

        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sYou have%s canceled%s the chat input", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }

        Menu_Config(client, g_iConfigMenuPosition[client]);
        return Plugin_Handled;
    }

    g_iAwaitInput[client] = Mewstats_RouteAwait(client, g_iAwaitInput[client], szText, sizeof(szText));
    Menu_Config(client, g_iConfigMenuPosition[client]);

    return Plugin_Handled;
}

static int Mewstats_RouteAwait(int client, int await, char[] text, int size)
{
    if (await >= _MEWSTATS_AWAIT_MIN_COLOR && await <= _MEWSTATS_AWAIT_MAX_COLOR)
    {
        char szColor[MEWSTATS_THEME_COLOR_SIZE];
        if (!Mewstats_ParseThemeColor(szColor, sizeof(szColor), text, size))
        {
            char szMessage[256] = "";
            FormatEx(szMessage, sizeof(szMessage), "%s%sYour color input is%s invalid%s; try again or type%s cancel", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_DARK_RED, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER);
            if (szMessage[0] != '\0')
            {
                Mewstats_SayText2(client, true, szMessage);
            }

            return await;
        }

        char szItem[MEWSTATS_MENU_ITEM_SIZE];
        Mewstats_ThemeColorMenuItem(szItem, sizeof(szItem), szColor, sizeof(szColor));

        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sYou have choosen %s%s%s as your color", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, szColor, szItem, MEWSTATS_CHAT_COLOR_WHITE);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }

        if (await == _MEWSTATS_AWAIT_BASE_COLOR)
        {
            strcopy(g_szCustomBaseColor[client], MEWSTATS_THEME_COLOR_SIZE, szColor);
            g_ckCustomBaseColor.Set(client, g_szCustomBaseColor[client]);
        }
        else if (await == _MEWSTATS_AWAIT_ACCENT_COLOR)
        {
            strcopy(g_szCustomAccentColor[client], MEWSTATS_THEME_COLOR_SIZE, szColor);
            g_ckCustomAccentColor.Set(client, g_szCustomAccentColor[client]);
        }
        else if (await == _MEWSTATS_AWAIT_SEPARATOR_COLOR)
        {
            strcopy(g_szCustomSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE, szColor);
            g_ckCustomSeparatorColor.Set(client, g_szCustomSeparatorColor[client]);
        }
        else if (await == _MEWSTATS_AWAIT_MLS_BASE_COLOR)
        {
            strcopy(g_szCustomMlsBaseColor[client], MEWSTATS_THEME_COLOR_SIZE, szColor);
            g_ckCustomMlsBaseColor.Set(client, g_szCustomMlsBaseColor[client]);
        }
        else if (await == _MEWSTATS_AWAIT_MLS_ACCENT_COLOR)
        {
            strcopy(g_szCustomMlsAccentColor[client], MEWSTATS_THEME_COLOR_SIZE, szColor);
            g_ckCustomMlsAccentColor.Set(client, g_szCustomMlsAccentColor[client]);
        }
        else if (await == _MEWSTATS_AWAIT_MLS_SEPARATOR_COLOR)
        {
            strcopy(g_szCustomMlsSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE, szColor);
            g_ckCustomMlsSeparatorColor.Set(client, g_szCustomMlsSeparatorColor[client]);
        }
    }

    if (await == _MEWSTATS_AWAIT_IMPORT_SETTINGS)
    {
        if (!Mewstats_ImportSettings(client, text))
        {
            char szMessage[256] = "";
            FormatEx(szMessage, sizeof(szMessage), "%s%sYour settings%s code%s is%s invalid%s; try again or type%s cancel", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_DARK_RED, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER);
            if (szMessage[0] != '\0')
            {
                Mewstats_SayText2(client, true, szMessage);
            }

            return await;
        }

        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sYour settings updated from%s %s", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, text);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }
    }
    else if (await == _MEWSTATS_AWAIT_IMPORT_THEME)
    {
        if (!Mewstats_ImportTheme(client, text))
        {
            char szMessage[256] = "";
            FormatEx(szMessage, sizeof(szMessage), "%s%sYour theme%s code%s is%s invalid%s; try again or type%s cancel", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_DARK_RED, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER);
            if (szMessage[0] != '\0')
            {
                Mewstats_SayText2(client, true, szMessage);
            }

            return await;
        }

        char szMessage[256] = "";
        FormatEx(szMessage, sizeof(szMessage), "%s%sYour custom theme updated from%s %s", MEWSTATS_CHAT_PREFIX, MEWSTATS_CHAT_COLOR_WHITE, MEWSTATS_CHAT_COLOR_COPPER, text);
        if (szMessage[0] != '\0')
        {
            Mewstats_SayText2(client, true, szMessage);
        }
    }

    return 0;
}

static void Mewstats_InitStateVars(int client)
{
    g_iThrowSpeed[client] = g_ckThrowSpeed.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_SPEED_DEFAULT);
    g_iThrowAngle[client] = g_ckThrowAngle.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_ANGLE_DEFAULT);
    g_iThrowTime[client] = g_ckThrowTime.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_TIME_DEFAULT);
    g_iThrowDeviation[client] = g_ckThrowDeviation.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_DEFAULT);
    g_iThrowStatus[client] = g_ckThrowStatus.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_STATUS_DEFAULT);
    g_iPartnerStats[client] = g_ckPartnerStats.GetInt(client, MEWSTATS_COOKIE_VALUE_PARTNER_STATS_DEFAULT);
    g_iPartnerPrefix[client] = g_ckPartnerPrefix.GetInt(client, MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_DEFAULT);
    g_iSkyStats[client] = g_ckSkyStats.GetInt(client, MEWSTATS_COOKIE_VALUE_SKY_STATS_DEFAULT);
    g_iSkyPrecision[client] = g_ckSkyPrecision.GetInt(client, MEWSTATS_COOKIE_VALUE_SKY_PRECISION_DEFAULT);
    g_iMlsStats[client] = g_ckMlsStats.GetInt(client, MEWSTATS_COOKIE_VALUE_MLS_STATS_DEFAULT);
    g_iShortNames[client] = g_ckShortNames.GetInt(client, MEWSTATS_COOKIE_VALUE_SHORT_NAMES_DEFAULT);
    g_iCrouchName[client] = g_ckCrouchName.GetInt(client, MEWSTATS_COOKIE_VALUE_CROUCH_NAME_DEFAULT);
    g_iColorValues[client] = g_ckColorValues.GetInt(client, MEWSTATS_COOKIE_VALUE_COLOR_VALUES_DEFAULT);
    g_iValuePrecision[client] = g_ckValuePreicision.GetInt(client, MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DEFAULT);
    g_iChatTheme[client] = g_ckChatTheme.GetInt(client, MEWSTATS_COOKIE_VALUE_CHAT_THEME_DEFAULT);
    g_iChatSeparator[client] = g_ckChatSeparator.GetInt(client, MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_DEFAULT);
    g_iChatSound[client] = g_ckChatSound.GetInt(client, MEWSTATS_COOKIE_VALUE_CHAT_SOUND_DEFAULT);
    g_iMlsGain[client] = g_ckMlsGain.GetInt(client, MEWSTATS_COOKIE_VALUE_MLS_GAIN_DEFAULT);
    g_iMlsDeviation[client] = g_ckMlsDeviation.GetInt(client, MEWSTATS_COOKIE_VALUE_MLS_DEVIATION_DEFAULT);

    g_ckCustomBaseColor.Get(client, g_szCustomBaseColor[client], MEWSTATS_THEME_COLOR_SIZE);
    g_ckCustomAccentColor.Get(client, g_szCustomAccentColor[client], MEWSTATS_THEME_COLOR_SIZE);
    g_ckCustomSeparatorColor.Get(client, g_szCustomSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE);
    g_ckCustomMlsBaseColor.Get(client, g_szCustomMlsBaseColor[client], MEWSTATS_THEME_COLOR_SIZE);
    g_ckCustomMlsAccentColor.Get(client, g_szCustomMlsAccentColor[client], MEWSTATS_THEME_COLOR_SIZE);
    g_ckCustomMlsSeparatorColor.Get(client, g_szCustomMlsSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE);

    bool flag = false;
    if (!Mewstats_IsThemeColorValid(g_szCustomBaseColor[client], MEWSTATS_THEME_COLOR_SIZE))
    {
        g_szCustomBaseColor[client][0] = '\0';
        flag = true;
    }
    if (!Mewstats_IsThemeColorValid(g_szCustomAccentColor[client], MEWSTATS_THEME_COLOR_SIZE))
    {
        g_szCustomAccentColor[client][0] = '\0';
        flag = true;
    }
    if (!Mewstats_IsThemeColorValid(g_szCustomSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE))
    {
        g_szCustomSeparatorColor[client][0] = '\0';
        flag = true;
    }
    if (!Mewstats_IsThemeColorValid(g_szCustomMlsBaseColor[client], MEWSTATS_THEME_COLOR_SIZE))
    {
        g_szCustomMlsBaseColor[client][0] = '\0';
        flag = true;
    }
    if (!Mewstats_IsThemeColorValid(g_szCustomMlsAccentColor[client], MEWSTATS_THEME_COLOR_SIZE))
    {
        g_szCustomMlsAccentColor[client][0] = '\0';
        flag = true;
    }
    if (!Mewstats_IsThemeColorValid(g_szCustomMlsSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE))
    {
        g_szCustomMlsSeparatorColor[client][0] = '\0';
        flag = true;
    }

    if (flag && g_iChatTheme[client] == MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM)
    {
        g_iChatTheme[client] = MEWSTATS_COOKIE_VALUE_CHAT_THEME_DEFAULT;
    }

    g_ckSettingsBackup.Get(client, g_szSettingsBackup[client], MEWSTATS_COOKIE_VALUE_SETTINGS_BACKUP_SIZE);
    g_iStatsBackup[client] = g_ckStatsBackup.GetInt(client, MEWSTATS_COOKIE_VALUE_STATS_BACKUP_DEFAULT);
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
    g_szThrowTimeModes[MEWSTATS_COOKIE_VALUE_THROW_TIME_INSTANT] = MEWSTATS_MENU_ITEM_INSTANT;
    g_szThrowTimeModes[MEWSTATS_COOKIE_VALUE_THROW_TIME_DELAYED] = MEWSTATS_MENU_ITEM_DELAYED;

    // Throw Deviation
    g_szThrowDeviationModes[MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szThrowDeviationModes[MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Throw Status
    g_szThrowStatusModes[MEWSTATS_COOKIE_VALUE_THROW_STATUS_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szThrowStatusModes[MEWSTATS_COOKIE_VALUE_THROW_STATUS_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Partner Stats
    g_szPartnerStatsModes[MEWSTATS_COOKIE_VALUE_PARTNER_STATS_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szPartnerStatsModes[MEWSTATS_COOKIE_VALUE_PARTNER_STATS_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Partner Prefix
    g_szPartnerPrefixModes[MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_NONE] = MEWSTATS_MENU_ITEM_NONE;
    g_szPartnerPrefixModes[MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_BRACKET] = MEWSTATS_MENU_ITEM_BRACKET;
    g_szPartnerPrefixModes[MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_AT] = MEWSTATS_MENU_ITEM_AT;
    g_szPartnerPrefixModes[MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_ASTERISK] = MEWSTATS_MENU_ITEM_ASTERISK;

    g_szPartnerPrefixValues[MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_NONE] = "";
    g_szPartnerPrefixValues[MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_BRACKET] = ">";
    g_szPartnerPrefixValues[MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_AT] = "@";
    g_szPartnerPrefixValues[MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_ASTERISK] = "*";

    // Sky Stats
    g_szSkyStatsModes[MEWSTATS_COOKIE_VALUE_SKY_STATS_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szSkyStatsModes[MEWSTATS_COOKIE_VALUE_SKY_STATS_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // Sky Precision
    g_szSkyPrecisionModes[MEWSTATS_COOKIE_VALUE_SKY_PRECISION_MATCH] = MEWSTATS_MENU_ITEM_MATCH;
    g_szSkyPrecisionModes[MEWSTATS_COOKIE_VALUE_SKY_PRECISION_DOT_ZERO] = MEWSTATS_MENU_ITEM_DOT_ZERO;
    g_szSkyPrecisionModes[MEWSTATS_COOKIE_VALUE_SKY_PRECISION_DOT_ONE] = MEWSTATS_MENU_ITEM_DOT_ONE;
    g_szSkyPrecisionModes[MEWSTATS_COOKIE_VALUE_SKY_PRECISION_DOT_TWO] = MEWSTATS_MENU_ITEM_DOT_TWO;

    // MLS Stats
    g_szMlsStatsModes[MEWSTATS_COOKIE_VALUE_MLS_STATS_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szMlsStatsModes[MEWSTATS_COOKIE_VALUE_MLS_STATS_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // MLS Gain
    g_szMlsGainModes[MEWSTATS_COOKIE_VALUE_MLS_STATS_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szMlsGainModes[MEWSTATS_COOKIE_VALUE_MLS_STATS_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

    // MLS Deviation
    g_szMlsDeviationModes[MEWSTATS_COOKIE_VALUE_MLS_DEVIATION_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szMlsDeviationModes[MEWSTATS_COOKIE_VALUE_MLS_DEVIATION_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

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
    g_szChatThemeModes[MEWSTATS_COOKIE_VALUE_CHAT_THEME_CUSTOM] = MEWSTATS_MENU_ITEM_CUSTOM;

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
    g_ckPartnerStats = RegClientCookie(MEWSTATS_COOKIE_NAME_PARTNER_STATS, MEWSTATS_COOKIE_DESCRIPTION_PARTNER_STATS, CookieAccess_Protected);
    g_ckPartnerPrefix = RegClientCookie(MEWSTATS_COOKIE_NAME_PARTNER_PREFIX, MEWSTATS_COOKIE_DESCRIPTION_PARTNER_PREFIX, CookieAccess_Protected);
    g_ckSkyStats = RegClientCookie(MEWSTATS_COOKIE_NAME_SKY_STATS, MEWSTATS_COOKIE_DESCRIPTION_SKY_STATS, CookieAccess_Protected);
    g_ckSkyPrecision = RegClientCookie(MEWSTATS_COOKIE_NAME_SKY_PRECISION, MEWSTATS_COOKIE_DESCRIPTION_SKY_PRECISION, CookieAccess_Protected);
    g_ckMlsStats = RegClientCookie(MEWSTATS_COOKIE_NAME_MLS_STATS, MEWSTATS_COOKIE_DESCRIPTION_MLS_STATS, CookieAccess_Protected);
    g_ckShortNames = RegClientCookie(MEWSTATS_COOKIE_NAME_SHORT_NAMES, MEWSTATS_COOKIE_DESCRIPTION_SHORT_NAMES, CookieAccess_Protected);
    g_ckCrouchName = RegClientCookie(MEWSTATS_COOKIE_NAME_CROUCH_NAME, MEWSTATS_COOKIE_DESCRIPTION_CROUCH_NAME, CookieAccess_Protected);
    g_ckColorValues = RegClientCookie(MEWSTATS_COOKIE_NAME_COLOR_VALUES, MEWSTATS_COOKIE_DESCRIPTION_COLOR_VALUES, CookieAccess_Protected);
    g_ckValuePreicision = RegClientCookie(MEWSTATS_COOKIE_NAME_VALUE_PRECISION, MEWSTATS_COOKIE_DESCRIPTION_VALUE_PRECISION, CookieAccess_Protected);
    g_ckChatTheme = RegClientCookie(MEWSTATS_COOKIE_NAME_CHAT_THEME, MEWSTATS_COOKIE_DESCRIPTION_CHAT_THEME, CookieAccess_Protected);
    g_ckChatSeparator = RegClientCookie(MEWSTATS_COOKIE_NAME_CHAT_SEPARATOR, MEWSTATS_COOKIE_DESCRIPTION_CHAT_SEPARATOR, CookieAccess_Protected);
    g_ckChatSound = RegClientCookie(MEWSTATS_COOKIE_NAME_CHAT_SOUND, MEWSTATS_COOKIE_DESCRIPTION_CHAT_SOUND, CookieAccess_Protected);
    g_ckMlsGain = RegClientCookie(MEWSTATS_COOKIE_NAME_MLS_GAIN, MEWSTATS_COOKIE_DESCRIPTION_MLS_GAIN, CookieAccess_Protected);
    g_ckMlsDeviation = RegClientCookie(MEWSTATS_COOKIE_NAME_MLS_DEVIATION, MEWSTATS_COOKIE_DESCRIPTION_MLS_DEVIATION, CookieAccess_Protected);
    g_ckCustomBaseColor = RegClientCookie(MEWSTATS_COOKIE_NAME_CUSTOM_BASE_COLOR, MEWSTATS_COOKIE_DESCRIPTION_CUSTOM_BASE_COLOR, CookieAccess_Protected);
    g_ckCustomAccentColor = RegClientCookie(MEWSTATS_COOKIE_NAME_CUSTOM_ACCENT_COLOR, MEWSTATS_COOKIE_DESCRIPTION_CUSTOM_ACCENT_COLOR, CookieAccess_Protected);
    g_ckCustomSeparatorColor = RegClientCookie(MEWSTATS_COOKIE_NAME_CUSTOM_SEPARATOR_COLOR, MEWSTATS_COOKIE_DESCRIPTION_CUSTOM_SEPARATOR_COLOR, CookieAccess_Protected);
    g_ckCustomMlsBaseColor = RegClientCookie(MEWSTATS_COOKIE_NAME_CUSTOM_MLS_BASE_COLOR, MEWSTATS_COOKIE_DESCRIPTION_CUSTOM_MLS_BASE_COLOR, CookieAccess_Protected);
    g_ckCustomMlsAccentColor = RegClientCookie(MEWSTATS_COOKIE_NAME_CUSTOM_MLS_ACCENT_COLOR, MEWSTATS_COOKIE_DESCRIPTION_CUSTOM_MLS_ACCENT_COLOR, CookieAccess_Protected);
    g_ckCustomMlsSeparatorColor = RegClientCookie(MEWSTATS_COOKIE_NAME_CUSTOM_MLS_SEPARATOR_COLOR, MEWSTATS_COOKIE_DESCRIPTION_CUSTOM_MLS_SEPARATOR_COLOR, CookieAccess_Protected);
    g_ckSettingsBackup = RegClientCookie(MEWSTATS_COOKIE_NAME_SETTINGS_BACKUP, MEWSTATS_COOKIE_DESCRIPTION_SETTINGS_BACKUP, CookieAccess_Protected);
    g_ckStatsBackup = RegClientCookie(MEWSTATS_COOKIE_NAME_STATS_BACKUP, MEWSTATS_COOKIE_DESCRIPTION_STATS_BACKUP, CookieAccess_Protected);
}

static void Mewstats_CreateCommands()
{
    RegConsoleCmd("sm_bs", Command_Stats);
    RegConsoleCmd("sm_bsall", Command_All);
    RegConsoleCmd("sm_bssnap", Command_Snapshot);
    RegConsoleCmd("sm_bsimport", Command_Import);
    RegConsoleCmd("sm_bsexport", Command_Export);
    RegConsoleCmd("sm_bspref", Command_Config);
    RegConsoleCmd("sm_bspreferences", Command_Config);
    RegConsoleCmd("sm_bscfg", Command_Config);
    RegConsoleCmd("sm_bsconfig", Command_Config);
}

static void Mewstats_HookEvents()
{
    HookEvent(MEWSTATS_EVENT_PLAYER_JUMP, Event_PlayerJump, EventHookMode_Post);
}

static void Mewstats_HookCommands()
{
    AddCommandListener(Listener_AwaitInput, "say");
    AddCommandListener(Listener_AwaitInput, "say_team");
}

static bool Mewstats_ImportSettings(int client, char[] code)
{
    char raw[_MEWSTATS_SETTING_RAW_LEN + 1] = "";

    int len = DecodeBase64(raw, sizeof(raw), code);
    if (len == _MEWSTATS_SETTING_RAW_LEN || len == _MEWSTATS_SETTING_RAW_LEN - _MEWSTATS_THEME_RAW_LEN)
    {
        Mewstats_XorBytes(raw, sizeof(raw));
        return Mewstats_ImportSettingsRaw(client, raw, sizeof(raw));
    }
    if (len == _MEWSTATS_THEME_RAW_LEN)
    {
        Mewstats_XorBytes(raw, sizeof(raw));
        return Mewstats_ImportThemeRaw(client, raw, sizeof(raw));
    }

    return false;
}

static bool Mewstats_ImportSettingsRaw(int client, char[] buff, int size)
{
    if (buff[0] != _MEWSTATS_SETTING_TAG || size < _MEWSTATS_SETTING_RAW_LEN + 1)
    {
        return false;
    }
    if (!Mewstats_IsClientInGame(client))
    {
        return false;
    }

    int data = 0;
    int i = 1;

    data |= view_as<int>(buff[i++]) & 0xFF;
    data |= (view_as<int>(buff[i++]) & 0xFF) << 8;
    data |= (view_as<int>(buff[i++]) & 0xFF) << 16;

    // -- #1
    g_iThrowSpeed[client] = (data >> MEWSTATS_COOKIE_VALUE_THROW_SPEED_SHIFT) & MEWSTATS_COOKIE_VALUE_THROW_SPEED_MASK;
    g_iThrowAngle[client] = (data >> MEWSTATS_COOKIE_VALUE_THROW_ANGLE_SHIFT) & MEWSTATS_COOKIE_VALUE_THROW_ANGLE_MASK;
    g_iThrowTime[client] = (data >> MEWSTATS_COOKIE_VALUE_THROW_TIME_SHIFT) & MEWSTATS_COOKIE_VALUE_THROW_TIME_MASK;
    g_iThrowDeviation[client] = (data >> MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_SHIFT) & MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_MASK;
    g_iThrowStatus[client] = (data >> MEWSTATS_COOKIE_VALUE_THROW_STATUS_SHIFT) & MEWSTATS_COOKIE_VALUE_THROW_STATUS_MASK;
    g_iPartnerStats[client] = (data >> MEWSTATS_COOKIE_VALUE_PARTNER_STATS_SHIFT) & MEWSTATS_COOKIE_VALUE_PARTNER_STATS_MASK;
    g_iSkyStats[client] = (data >> MEWSTATS_COOKIE_VALUE_SKY_STATS_SHIFT) & MEWSTATS_COOKIE_VALUE_SKY_STATS_MASK;
    // -- #2
    g_iMlsStats[client] = (data >> MEWSTATS_COOKIE_VALUE_MLS_STATS_SHIFT) & MEWSTATS_COOKIE_VALUE_MLS_STATS_MASK;
    g_iShortNames[client] = (data >> MEWSTATS_COOKIE_VALUE_SHORT_NAMES_SHIFT) & MEWSTATS_COOKIE_VALUE_SHORT_NAMES_MASK;
    g_iCrouchName[client] = (data >> MEWSTATS_COOKIE_VALUE_CROUCH_NAME_SHIFT) & MEWSTATS_COOKIE_VALUE_CROUCH_NAME_MASK;
    g_iColorValues[client] = (data >> MEWSTATS_COOKIE_VALUE_COLOR_VALUES_SHIFT) & MEWSTATS_COOKIE_VALUE_COLOR_VALUES_MASK;
    g_iValuePrecision[client] = (data >> MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_SHIFT) & MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_MASK;
    g_iChatTheme[client] = (data >> MEWSTATS_COOKIE_VALUE_CHAT_THEME_SHIFT) & MEWSTATS_COOKIE_VALUE_CHAT_THEME_MASK;
    // -- #3
    g_iChatSeparator[client] = (data >> MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_SHIFT) & MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_MASK;
    g_iChatSound[client] = (data >> MEWSTATS_COOKIE_VALUE_CHAT_SOUND_SHIFT) & MEWSTATS_COOKIE_VALUE_CHAT_SOUND_MASK;
    g_iMlsGain[client] = (data >> MEWSTATS_COOKIE_VALUE_MLS_GAIN_SHIFT) & MEWSTATS_COOKIE_VALUE_MLS_GAIN_MASK;
    g_iMlsDeviation[client] = (data >> MEWSTATS_COOKIE_VALUE_MLS_DEVIATION_SHIFT) & MEWSTATS_COOKIE_VALUE_MLS_DEVIATION_MASK;
    g_iPartnerPrefix[client] = (data >> MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_SHIFT) & MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_MASK;
    g_iSkyPrecision[client] = (data >> MEWSTATS_COOKIE_VALUE_SKY_PRECISION_SHIFT) & MEWSTATS_COOKIE_VALUE_SKY_PRECISION_MASK;

    g_ckThrowSpeed.SetInt(client, g_iThrowSpeed[client]);
    g_ckThrowAngle.SetInt(client, g_iThrowAngle[client]);
    g_ckThrowTime.SetInt(client, g_iThrowTime[client]);
    g_ckThrowDeviation.SetInt(client, g_iThrowDeviation[client]);
    g_ckThrowStatus.SetInt(client, g_iThrowStatus[client]);
    g_ckPartnerStats.SetInt(client, g_iPartnerStats[client]);
    g_ckSkyStats.SetInt(client, g_iSkyStats[client]);
    g_ckMlsStats.SetInt(client, g_iMlsStats[client]);
    g_ckShortNames.SetInt(client, g_iShortNames[client]);
    g_ckCrouchName.SetInt(client, g_iCrouchName[client]);
    g_ckColorValues.SetInt(client, g_iColorValues[client]);
    g_ckValuePreicision.SetInt(client, g_iValuePrecision[client]);
    g_ckChatTheme.SetInt(client, g_iChatTheme[client]);
    g_ckChatSeparator.SetInt(client, g_iChatSeparator[client]);
    g_ckChatSound.SetInt(client, g_iChatSound[client]);
    g_ckMlsGain.SetInt(client, g_iMlsGain[client]);
    g_ckMlsDeviation.SetInt(client, g_iMlsDeviation[client]);
    g_ckPartnerPrefix.SetInt(client, g_iPartnerPrefix[client]);
    g_ckSkyPrecision.SetInt(client, g_iSkyPrecision[client]);

    Mewstats_ImportThemeRaw(client, buff[i], size - i);
    return true;
}

static bool Mewstats_ExportSettings(int client, char[] buff, int size)
{
    char raw[_MEWSTATS_SETTING_RAW_LEN + 1] = "";
    int rsize = Mewstats_ExportSettingsRaw(client, raw, sizeof(raw));
    if (raw[0] == '\0')
    {
        buff[0] = '\0';
        return false;
    }

    Mewstats_XorBytes(raw, rsize);
    int csize = EncodeBase64(buff, size, raw, rsize);

    buff[csize] = '\0';
    return true;
}

static int Mewstats_ExportSettingsRaw(int client, char[] buff, int size)
{
    if (size < _MEWSTATS_SETTING_RAW_LEN + 1)
    {
        buff[0] = '\0';
        return 0;
    }
    if (!Mewstats_IsClientInGame(client))
    {
        buff[0] = '\0';
        return 0;
    }

    int i = 0;
    buff[i++] = _MEWSTATS_SETTING_TAG;

    int data = 0;
    // -- #1
    data |= (g_iThrowSpeed[client] & MEWSTATS_COOKIE_VALUE_THROW_SPEED_MASK) << MEWSTATS_COOKIE_VALUE_THROW_SPEED_SHIFT;                // 1 bit    [#01]
    data |= (g_iThrowAngle[client] & MEWSTATS_COOKIE_VALUE_THROW_ANGLE_MASK) << MEWSTATS_COOKIE_VALUE_THROW_ANGLE_SHIFT;                // 1 bit    [#02]
    data |= (g_iThrowTime[client] & MEWSTATS_COOKIE_VALUE_THROW_TIME_MASK) << MEWSTATS_COOKIE_VALUE_THROW_TIME_SHIFT;                   // 2 bits   [#04]
    data |= (g_iThrowDeviation[client] & MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_MASK) << MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_SHIFT;    // 1 bit    [#05]
    data |= (g_iThrowStatus[client] & MEWSTATS_COOKIE_VALUE_THROW_STATUS_MASK) << MEWSTATS_COOKIE_VALUE_THROW_STATUS_SHIFT;             // 1 bit    [#06]
    data |= (g_iPartnerStats[client] & MEWSTATS_COOKIE_VALUE_PARTNER_STATS_MASK) << MEWSTATS_COOKIE_VALUE_PARTNER_STATS_SHIFT;          // 1 bit    [#07]
    data |= (g_iSkyStats[client] & MEWSTATS_COOKIE_VALUE_SKY_STATS_MASK) << MEWSTATS_COOKIE_VALUE_SKY_STATS_SHIFT;                      // 1 bit    [#08]
    // -- #2
    data |= (g_iMlsStats[client] & MEWSTATS_COOKIE_VALUE_MLS_STATS_MASK) << MEWSTATS_COOKIE_VALUE_MLS_STATS_SHIFT;                      // 1 bit    [#09]
    data |= (g_iShortNames[client] & MEWSTATS_COOKIE_VALUE_SHORT_NAMES_MASK) << MEWSTATS_COOKIE_VALUE_SHORT_NAMES_SHIFT;                // 1 bit    [#10]
    data |= (g_iCrouchName[client] & MEWSTATS_COOKIE_VALUE_CROUCH_NAME_MASK) << MEWSTATS_COOKIE_VALUE_CROUCH_NAME_SHIFT;                // 1 bit    [#11]
    data |= (g_iColorValues[client] & MEWSTATS_COOKIE_VALUE_COLOR_VALUES_MASK) << MEWSTATS_COOKIE_VALUE_COLOR_VALUES_SHIFT;             // 1 bit    [#12]
    data |= (g_iValuePrecision[client] & MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_MASK) << MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_SHIFT;    // 1 bit    [#13]
    data |= (g_iChatTheme[client] & MEWSTATS_COOKIE_VALUE_CHAT_THEME_MASK) << MEWSTATS_COOKIE_VALUE_CHAT_THEME_SHIFT;                   // 3 bits   [#16]
    // -- #3
    data |= (g_iChatSeparator[client] & MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_MASK) << MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_SHIFT;       // 1 bit    [#17]
    data |= (g_iChatSound[client] & MEWSTATS_COOKIE_VALUE_CHAT_SOUND_MASK) << MEWSTATS_COOKIE_VALUE_CHAT_SOUND_SHIFT;                   // 1 bit    [#18]
    data |= (g_iMlsGain[client] & MEWSTATS_COOKIE_VALUE_MLS_GAIN_MASK) << MEWSTATS_COOKIE_VALUE_MLS_GAIN_SHIFT;                         // 1 bit    [#19]
    data |= (g_iMlsDeviation[client] & MEWSTATS_COOKIE_VALUE_MLS_DEVIATION_MASK) << MEWSTATS_COOKIE_VALUE_MLS_DEVIATION_SHIFT;          // 1 bit    [#20]
    data |= (g_iPartnerPrefix[client] & MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_MASK) << MEWSTATS_COOKIE_VALUE_PARTNER_PREFIX_SHIFT;       // 2 bits   [#22]
    data |= (g_iSkyPrecision[client] & MEWSTATS_COOKIE_VALUE_SKY_PRECISION_MASK) << MEWSTATS_COOKIE_VALUE_SKY_PRECISION_SHIFT;          // 2 bits   [#24]

    buff[i++] = view_as<char>(data & 0xFF);
    buff[i++] = view_as<char>((data >> 8) & 0xFF);
    buff[i++] = view_as<char>((data >> 16) & 0xFF);

    return i + Mewstats_ExportThemeRaw(client, buff[i], size - i);
}

static bool Mewstats_ImportTheme(int client, char[] code)
{
    char raw[_MEWSTATS_SETTING_RAW_LEN + 1] = "";

    int len = DecodeBase64(raw, sizeof(raw), code);
    if (len == _MEWSTATS_SETTING_RAW_LEN)
    {
        Mewstats_XorBytes(raw, sizeof(raw));

        int start = _MEWSTATS_SETTING_RAW_LEN - _MEWSTATS_THEME_RAW_LEN;
        if (start >= sizeof(raw))
        {
            return false;
        }

        return Mewstats_ImportThemeRaw(client, raw[start], sizeof(raw) - start);
    }
    if (len == _MEWSTATS_THEME_RAW_LEN)
    {
        Mewstats_XorBytes(raw, sizeof(raw));
        return Mewstats_ImportThemeRaw(client, raw, sizeof(raw));
    }

    return false;
}

static bool Mewstats_ImportThemeRaw(int client, char[] buff, int size)
{
    if (buff[0] != _MEWSTATS_THEME_TAG || size < _MEWSTATS_THEME_RAW_LEN + 1)
    {
        return false;
    }
    if (!Mewstats_IsClientInGame(client))
    {
        return false;
    }

    int b = 0;
    int g = 0;
    int r = 0;
    int color = 0;
    int i = 1;

    b = view_as<int>(buff[i++]) & 0xFF;
    g = view_as<int>(buff[i++]) & 0xFF;
    r = view_as<int>(buff[i++]) & 0xFF;
    color = b | (g << 8) | (r << 16);
    FormatEx(g_szCustomBaseColor[client], MEWSTATS_THEME_COLOR_SIZE, "\x07%06X", color);

    b = view_as<int>(buff[i++]) & 0xFF;
    g = view_as<int>(buff[i++]) & 0xFF;
    r = view_as<int>(buff[i++]) & 0xFF;
    color = b | (g << 8) | (r << 16);
    FormatEx(g_szCustomAccentColor[client], MEWSTATS_THEME_COLOR_SIZE, "\x07%06X", color);

    b = view_as<int>(buff[i++]) & 0xFF;
    g = view_as<int>(buff[i++]) & 0xFF;
    r = view_as<int>(buff[i++]) & 0xFF;
    color = b | (g << 8) | (r << 16);
    FormatEx(g_szCustomSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE, "\x07%06X", color);

    b = view_as<int>(buff[i++]) & 0xFF;
    g = view_as<int>(buff[i++]) & 0xFF;
    r = view_as<int>(buff[i++]) & 0xFF;
    color = b | (g << 8) | (r << 16);
    FormatEx(g_szCustomMlsBaseColor[client], MEWSTATS_THEME_COLOR_SIZE, "\x07%06X", color);

    b = view_as<int>(buff[i++]) & 0xFF;
    g = view_as<int>(buff[i++]) & 0xFF;
    r = view_as<int>(buff[i++]) & 0xFF;
    color = b | (g << 8) | (r << 16);
    FormatEx(g_szCustomMlsAccentColor[client], MEWSTATS_THEME_COLOR_SIZE, "\x07%06X", color);

    b = view_as<int>(buff[i++]) & 0xFF;
    g = view_as<int>(buff[i++]) & 0xFF;
    r = view_as<int>(buff[i++]) & 0xFF;
    color = b | (g << 8) | (r << 16);
    FormatEx(g_szCustomMlsSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE, "\x07%06X", color);

    g_ckCustomBaseColor.Set(client, g_szCustomBaseColor[client]);
    g_ckCustomAccentColor.Set(client, g_szCustomAccentColor[client]);
    g_ckCustomSeparatorColor.Set(client, g_szCustomSeparatorColor[client]);
    g_ckCustomMlsBaseColor.Set(client, g_szCustomMlsBaseColor[client]);
    g_ckCustomMlsAccentColor.Set(client, g_szCustomMlsAccentColor[client]);
    g_ckCustomMlsSeparatorColor.Set(client, g_szCustomMlsSeparatorColor[client]);

    return true;
}

static bool Mewstats_ExportTheme(int client, char[] buff, int size)
{
    char raw[_MEWSTATS_THEME_RAW_LEN + 1] = "";
    int rsize = Mewstats_ExportThemeRaw(client, raw, sizeof(raw));
    if (raw[0] == '\0')
    {
        buff[0] = '\0';
        return false;
    }

    Mewstats_XorBytes(raw, rsize);
    int csize = EncodeBase64(buff, size, raw, rsize);

    buff[csize] = '\0';
    return true;
}

static int Mewstats_ExportThemeRaw(int client, char[] buff, int size)
{
    if (size < _MEWSTATS_THEME_RAW_LEN + 1)
    {
        buff[0] = '\0';
        return 0;
    }
    if (!Mewstats_IsClientInGame(client))
    {
        buff[0] = '\0';
        return 0;
    }
    if (!Mewstats_IsCustomThemeComplete(client))
    {
        buff[0] = '\0';
        return 0;
    }

    int i = 0;
    int j = 0;
    int c = 0;

    buff[i++] = _MEWSTATS_THEME_TAG;

    c = StringToIntEx(g_szCustomBaseColor[client][1], j, 16);
    if (c != 6)
    {
        buff[0] = '\0';
        return 0;
    }
    buff[i++] = view_as<char>(j & 0xFF);
    buff[i++] = view_as<char>((j >> 8) & 0xFF);
    buff[i++] = view_as<char>((j >> 16) & 0xFF);

    c = StringToIntEx(g_szCustomAccentColor[client][1], j, 16);
    if (c != 6)
    {
        buff[0] = '\0';
        return 0;
    }
    buff[i++] = view_as<char>(j & 0xFF);
    buff[i++] = view_as<char>((j >> 8) & 0xFF);
    buff[i++] = view_as<char>((j >> 16) & 0xFF);

    c = StringToIntEx(g_szCustomSeparatorColor[client][1], j, 16);
    if (c != 6)
    {
        buff[0] = '\0';
        return 0;
    }
    buff[i++] = view_as<char>(j & 0xFF);
    buff[i++] = view_as<char>((j >> 8) & 0xFF);
    buff[i++] = view_as<char>((j >> 16) & 0xFF);

    c = StringToIntEx(g_szCustomMlsBaseColor[client][1], j, 16);
    if (c != 6)
    {
        buff[0] = '\0';
        return 0;
    }
    buff[i++] = view_as<char>(j & 0xFF);
    buff[i++] = view_as<char>((j >> 8) & 0xFF);
    buff[i++] = view_as<char>((j >> 16) & 0xFF);

    c = StringToIntEx(g_szCustomMlsAccentColor[client][1], j, 16);
    if (c != 6)
    {
        buff[0] = '\0';
        return 0;
    }
    buff[i++] = view_as<char>(j & 0xFF);
    buff[i++] = view_as<char>((j >> 8) & 0xFF);
    buff[i++] = view_as<char>((j >> 16) & 0xFF);

    c = StringToIntEx(g_szCustomMlsSeparatorColor[client][1], j, 16);
    if (c != 6)
    {
        buff[0] = '\0';
        return 0;
    }
    buff[i++] = view_as<char>(j & 0xFF);
    buff[i++] = view_as<char>((j >> 8) & 0xFF);
    buff[i++] = view_as<char>((j >> 16) & 0xFF);

    buff[i] = '\0';
    return i;
}

static bool Mewstats_IsCustomThemeComplete(int client)
{
    return Mewstats_IsThemeColorValid(g_szCustomBaseColor[client], MEWSTATS_THEME_COLOR_SIZE)
        && Mewstats_IsThemeColorValid(g_szCustomAccentColor[client], MEWSTATS_THEME_COLOR_SIZE)
        && Mewstats_IsThemeColorValid(g_szCustomSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE)
        && Mewstats_IsThemeColorValid(g_szCustomMlsBaseColor[client], MEWSTATS_THEME_COLOR_SIZE)
        && Mewstats_IsThemeColorValid(g_szCustomMlsAccentColor[client], MEWSTATS_THEME_COLOR_SIZE)
        && Mewstats_IsThemeColorValid(g_szCustomMlsSeparatorColor[client], MEWSTATS_THEME_COLOR_SIZE);
}

static bool Mewstats_IsThemeColorValid(char[] buff, int size)
{
    if (buff[0] != '\x07')
    {
        return false;
    }

    for (int i = 1; i < 7; ++i)
    {
        if (i >= size || buff[i] == '\0')
        {
            return false;
        }

        char c = buff[i];
        if ((c < '0' || c > '9') && (c < 'a' || c > 'f') && (c < 'A' || c > 'F'))
        {
            return false;
        }
    }

    return true;
}

static void Mewstats_ThemeColorMenuItem(char[] buff, int size, char[] color, int csize)
{
    if (!Mewstats_IsThemeColorValid(color, csize))
    {
        strcopy(buff, size, MEWSTATS_MENU_ITEM_NONE);
        return;
    }

    buff[0] = '#';
    int i = 1;
    for (; i < 7 && i < size; ++i)
    {
        buff[i] = CharToUpper(color[i]);
    }
    buff[i] = '\0';
}

static bool Mewstats_ParseThemeColor(char[] buff, int size, char[] text, int tsize)
{
    int start = 0;
    for (; start < tsize; ++start)
    {
        char c = text[start];
        if (c == '\0' || c >= '0' && c <= '9' || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F')
        {
            break;
        }
    }

    if (tsize - start - 1 < 6)
    {
        return false;
    }

    buff[0] = '\x07';
    int i = 1;
    for (; i < 7 && i < size && start + i - 1 < tsize; ++i)
    {
        char c = text[start + i - 1];
        if ((c < '0' || c > '9') && (c < 'a' || c > 'f') && (c < 'A' || c > 'F'))
        {
            buff[0] = '\0';
            return false;
        }

        buff[i] = CharToUpper(c);
   }
   buff[i] = '\0';

   return true;
}

static int Mewstats_GetPartner(int client)
{
    if (GetFeatureStatus(FeatureType_Native, "Timer_GetPartner") != FeatureStatus_Available)
    {
        return _MEWSTATS_PARTNER_UNKNOWN;
    }

    int partner = Timer_GetPartner(client);
    if (!Mewstats_IsAliveClientInGame(partner))
    {
        return _MEWSTATS_PARTNER_UNKNOWN;
    }

    return partner;
}
