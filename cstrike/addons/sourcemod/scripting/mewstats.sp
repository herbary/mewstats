#include <sourcemod>
#include <clientprefs>
#include <string>
#include <sdktools>
#include <sdkhooks>

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

#define _MEWSTATS_JUMP_TICK_UNKNOWN -1

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
Cookie g_ckNadeVelocity;
Cookie g_ckPartnerStats;
Cookie g_ckShortNames;
Cookie g_ckCrouchName;
Cookie g_ckColorValues;
Cookie g_ckValuePreicision;
Cookie g_ckChatTheme;
Cookie g_ckChatSeparator;

int g_iThrowSpeed[MAXPLAYERS + 1];
int g_iThrowAngle[MAXPLAYERS + 1];
int g_iThrowTime[MAXPLAYERS + 1];
int g_iThrowDeviation[MAXPLAYERS + 1];
int g_iThrowStatus[MAXPLAYERS + 1];
int g_iNadeVelocity[MAXPLAYERS + 1];
int g_iPartnerStats[MAXPLAYERS + 1];
int g_iShortNames[MAXPLAYERS + 1];
int g_iCrouchName[MAXPLAYERS + 1];
int g_iColorValues[MAXPLAYERS + 1];
int g_iValuePrecision[MAXPLAYERS + 1];
int g_iChatTheme[MAXPLAYERS + 1];
int g_iChatSeparator[MAXPLAYERS + 1];

char g_szThrowSpeedModes[MEWSTATS_COOKIE_VALUE_THROW_SPEED_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowAngleModes[MEWSTATS_COOKIE_VALUE_THROW_ANGLE_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowTimeModes[MEWSTATS_COOKIE_VALUE_THROW_TIME_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowDeviationModes[MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szThrowStatusModes[MEWSTATS_COOKIE_VALUE_THROW_STATUS_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szNadeVelocityModes[MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szPartnerStatsModes[MEWSTATS_COOKIE_VALUE_PARTNER_STATS_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szShortNamesModes[MEWSTATS_COOKIE_VALUE_SHORT_NAMES_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szCrouchNameModes[MEWSTATS_COOKIE_VALUE_CROUCH_NAME_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szColorValuesModes[MEWSTATS_COOKIE_VALUE_COLOR_VALUES_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szValuePrecisionModes[MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szChatThemeModes[MEWSTATS_COOKIE_VALUE_CHAT_THEME_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_COUNT][MEWSTATS_THEME_COLOR_COUNT][MEWSTATS_THEME_COLOR_SIZE];
char g_szChatSeparatorModes[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_COUNT][MEWSTATS_MENU_ITEM_SIZE];
char g_szChatSeparatorValues[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_COUNT][MEWSTATS_CHAT_SEPARATOR_SIZE];

int g_iThrowJumpTick[MAXPLAYERS + 1];

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
    g_iThrowJumpTick[client] = _MEWSTATS_JUMP_TICK_UNKNOWN;

    Mewstats_InitStateVars(client);
}

public void OnClientCookiesCached(int client)
{
    Mewstats_InitStateVars(client);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (!Mewstats_IsAlivePlayerInGame(client))
    {
        return;
    }

    int flags = GetEntProp(client, Prop_Data, MEWSTATS_PROP_M_FFLAGS);
    if (Mewstats_IsFlag(flags, FL_ONGROUND))
    {
        g_iThrowJumpTick[client] = _MEWSTATS_JUMP_TICK_UNKNOWN;
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
    if (!IsValidEntity(entity))
    {
        return;
    }

    int thrower = GetEntPropEnt(entity, Prop_Data, MEWSTATS_PROP_M_HTHROWER);
    Mewstats_PrintThrowStats(thrower, thrower);
}

static void Mewstats_PrintThrowStats(int client, int thrower)
{
#define _MEWSTATS_MESSAGE_SIZE 256
#define _MEWSTATS_ELEMENT_SIZE 64
#define _MEWSTATS_ELEMENT_COUNT 6

    char szThrowSpeed[_MEWSTATS_ELEMENT_SIZE] = "";
    Mewstats_FormatThrowSpeed(client, thrower, szThrowSpeed, sizeof(szThrowSpeed));

    char szThrowAngle[_MEWSTATS_ELEMENT_SIZE] = "";
    Mewstats_FormatThrowAngle(client, thrower, szThrowAngle, sizeof(szThrowAngle));

    char szThrowTime[_MEWSTATS_ELEMENT_SIZE] = "";
    Mewstats_FormatThrowTime(client, thrower, szThrowTime, sizeof(szThrowTime));

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

    Mewstats_SayText2(client, true, szMessage);

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
        FormatEx(szSpeed, sizeof(szSpeed), "%.0f", speed);
    }
    else if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ONE)
    {
        FormatEx(szSpeed, sizeof(szSpeed), "%.1f", speed);
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
        FormatEx(szAngle, sizeof(szAngle), "%.0f", angle);
    }
    else if (g_iValuePrecision[client] == MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DOT_ONE)
    {
        FormatEx(szAngle, sizeof(szAngle), "%.1f", angle);
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
    if (g_iThrowJumpTick[thrower] != _MEWSTATS_JUMP_TICK_UNKNOWN)
    {
        tick = GetEntProp(thrower, Prop_Send, MEWSTATS_PROP_M_NTICKBASE) - g_iThrowJumpTick[thrower] - 1;
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
    FormatEx(szTime, sizeof(szTime), "%.2f", time);
    if (szTime[0] == '\0')
    {
        return;
    }

    FormatEx(buff, size, "%T", szPhrase, client, szBaseColor, szAccentColor, szTime);
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
    menu.AddItem(MEWSTATS_MENU_SELECT_THROW_DEVIATION, szItem);

    // Throw Status
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_THROW_STATUS_FMT, g_szThrowStatusModes[g_iThrowStatus[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_THROW_STATUS, szItem);

    // Nade Velocity
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_NADE_VELOCITY_FMT, g_szNadeVelocityModes[g_iNadeVelocity[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_NADE_VELOCITY, szItem);

    // Partner Stats
    FormatEx(szItem, sizeof(szItem), MEWSTATS_MENU_ITEM_PARTNER_STATS_FMT, g_szPartnerStatsModes[g_iPartnerStats[client]]);
    menu.AddItem(MEWSTATS_MENU_SELECT_PARTNER_STATS, szItem);

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
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_NADE_VELOCITY))
    {
        MenuSelect_NadeVelocity(client);
    }
    else if (StrEqual(szInfo, MEWSTATS_MENU_SELECT_PARTNER_STATS))
    {
        MenuSelect_PartnerStats(client);
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

static void MenuSelect_NadeVelocity(int client)
{
    Mewstats_CycleCookie(client, g_ckNadeVelocity, g_iNadeVelocity, MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_COUNT);
}

static void MenuSelect_PartnerStats(int client)
{
    Mewstats_CycleCookie(client, g_ckPartnerStats, g_iPartnerStats, MEWSTATS_COOKIE_VALUE_PARTNER_STATS_COUNT);
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
    Mewstats_CycleCookie(client, g_ckChatTheme, g_iChatTheme, MEWSTATS_COOKIE_VALUE_CHAT_THEME_COUNT);
}

static void MenuSelect_ChatSeparator(int client)
{
    Mewstats_CycleCookie(client, g_ckChatSeparator, g_iChatSeparator, MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_COUNT);
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

static void Mewstats_InitStateVars(int client)
{
    g_iThrowSpeed[client] = g_ckThrowSpeed.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_SPEED_DEFAULT);
    g_iThrowAngle[client] = g_ckThrowAngle.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_ANGLE_DEFAULT);
    g_iThrowTime[client] = g_ckThrowTime.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_TIME_DEFAULT);
    g_iThrowDeviation[client] = g_ckThrowDeviation.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_DEVIATION_DEFAULT);
    g_iThrowStatus[client] = g_ckThrowStatus.GetInt(client, MEWSTATS_COOKIE_VALUE_THROW_STATUS_DEFAULT);
    g_iNadeVelocity[client] = g_ckNadeVelocity.GetInt(client, MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_DEFAULT);
    g_iPartnerStats[client] = g_ckPartnerStats.GetInt(client, MEWSTATS_COOKIE_VALUE_PARTNER_STATS_DEFAULT);
    g_iShortNames[client] = g_ckShortNames.GetInt(client, MEWSTATS_COOKIE_VALUE_SHORT_NAMES_DEFAULT);
    g_iCrouchName[client] = g_ckCrouchName.GetInt(client, MEWSTATS_COOKIE_VALUE_CROUCH_NAME_DEFAULT);
    g_iColorValues[client] = g_ckColorValues.GetInt(client, MEWSTATS_COOKIE_VALUE_COLOR_VALUES_DEFAULT);
    g_iValuePrecision[client] = g_ckValuePreicision.GetInt(client, MEWSTATS_COOKIE_VALUE_VALUE_PRECISION_DEFAULT);
    g_iChatTheme[client] = g_ckChatTheme.GetInt(client, MEWSTATS_COOKIE_VALUE_CHAT_THEME_DEFAULT);
    g_iChatSeparator[client] = g_ckChatSeparator.GetInt(client, MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_DEFAULT);
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

    // Nade Velocity
    g_szNadeVelocityModes[MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szNadeVelocityModes[MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_XY] = MEWSTATS_MENU_ITEM_XY;
    g_szNadeVelocityModes[MEWSTATS_COOKIE_VALUE_NADE_VELOCITY_XYZ] = MEWSTATS_MENU_ITEM_XYZ;

    // Partner Stats
    g_szPartnerStatsModes[MEWSTATS_COOKIE_VALUE_PARTNER_STATS_FALSE] = MEWSTATS_MENU_ITEM_FALSE;
    g_szPartnerStatsModes[MEWSTATS_COOKIE_VALUE_PARTNER_STATS_TRUE] = MEWSTATS_MENU_ITEM_TRUE;

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
    g_szChatThemeModes[MEWSTATS_COOKIE_VALUE_CHAT_THEME_PURPLE] = MEWSTATS_MENU_ITEM_PURPLE;

    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_STANDARD][MEWSTATS_THEME_COLOR_INDEX_BASE] = MEWSTATS_THEME_STANDARD_COLOR_BASE;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_STANDARD][MEWSTATS_THEME_COLOR_INDEX_ACCENT] = MEWSTATS_THEME_STANDARD_COLOR_ACCENT;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_STANDARD][MEWSTATS_THEME_COLOR_INDEX_SEPARATOR] = MEWSTATS_THEME_STANDARD_COLOR_SEPARATOR;

    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_PURPLE][MEWSTATS_THEME_COLOR_INDEX_BASE] = MEWSTATS_THEME_PURPLE_COLOR_BASE;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_PURPLE][MEWSTATS_THEME_COLOR_INDEX_ACCENT] = MEWSTATS_THEME_PURPLE_COLOR_ACCENT;
    g_szChatThemeColors[MEWSTATS_COOKIE_VALUE_CHAT_THEME_PURPLE][MEWSTATS_THEME_COLOR_INDEX_SEPARATOR] = MEWSTATS_THEME_PURPLE_COLOR_SEPARATOR;

    // Chat Separator
    g_szChatSeparatorModes[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_SPACE] = MEWSTATS_MENU_ITEM_SPACE;
    g_szChatSeparatorModes[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_LINE] = MEWSTATS_MENU_ITEM_LINE;

    g_szChatSeparatorValues[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_SPACE] = MEWSTATS_CHAT_SEPARATOR_SPACE;
    g_szChatSeparatorValues[MEWSTATS_COOKIE_VALUE_CHAT_SEPARATOR_LINE] = MEWSTATS_CHAT_SEPARATOR_LINE;
}

static void Mewstats_CreateCookies()
{
    g_ckThrowSpeed = RegClientCookie(MEWSTATS_COOKIE_NAME_THROW_SPEED, MEWSTATS_COOKIE_DESCRIPTION_THROW_SPEED, CookieAccess_Protected);
    g_ckThrowAngle = RegClientCookie(MEWSTATS_COOKIE_NAME_THROW_ANGLE, MEWSTATS_COOKIE_DESCRIPTION_THROW_ANGLE, CookieAccess_Protected);
    g_ckThrowTime = RegClientCookie(MEWSTATS_COOKIE_NAME_THROW_TIME, MEWSTATS_COOKIE_DESCRIPTION_THROW_TIME, CookieAccess_Protected);
    g_ckThrowDeviation = RegClientCookie(MEWSTATS_COOKIE_NAME_THROW_DEVIATION, MEWSTATS_COOKIE_DESCRIPTION_THROW_DEVIATION, CookieAccess_Protected);
    g_ckThrowStatus = RegClientCookie(MEWSTATS_COOKIE_NAME_THROW_STATUS, MEWSTATS_COOKIE_DESCRIPTION_THROW_STATUS, CookieAccess_Protected);
    g_ckNadeVelocity = RegClientCookie(MEWSTATS_COOKIE_NAME_NADE_VELOCITY, MEWSTATS_COOKIE_DESCRIPTION_NADE_VELOCITY, CookieAccess_Protected);
    g_ckPartnerStats = RegClientCookie(MEWSTATS_COOKIE_NAME_PARTNER_STATS, MEWSTATS_COOKIE_DESCRIPTION_PARTNER_STATS, CookieAccess_Protected);
    g_ckShortNames = RegClientCookie(MEWSTATS_COOKIE_NAME_SHORT_NAMES, MEWSTATS_COOKIE_DESCRIPTION_SHORT_NAMES, CookieAccess_Protected);
    g_ckCrouchName = RegClientCookie(MEWSTATS_COOKIE_NAME_CROUCH_NAME, MEWSTATS_COOKIE_DESCRIPTION_CROUCH_NAME, CookieAccess_Protected);
    g_ckColorValues = RegClientCookie(MEWSTATS_COOKIE_NAME_COLOR_VALUES, MEWSTATS_COOKIE_DESCRIPTION_COLOR_VALUES, CookieAccess_Protected);
    g_ckValuePreicision = RegClientCookie(MEWSTATS_COOKIE_NAME_VALUE_PRECISION, MEWSTATS_COOKIE_DESCRIPTION_VALUE_PRECISION, CookieAccess_Protected);
    g_ckChatTheme = RegClientCookie(MEWSTATS_COOKIE_NAME_CHAT_THEME, MEWSTATS_COOKIE_DESCRIPTION_CHAT_THEME, CookieAccess_Protected);
    g_ckChatSeparator = RegClientCookie(MEWSTATS_COOKIE_NAME_CHAT_SEPARATOR, MEWSTATS_COOKIE_DESCRIPTION_CHAT_SEPARATOR, CookieAccess_Protected);
}

static void Mewstats_CreateCommands()
{
    RegConsoleCmd("sm_bs", Command_Stats);
}

static void Mewstats_HookEvents()
{
    HookEvent(MEWSTATS_EVENT_PLAYER_JUMP, Event_PlayerJump, EventHookMode_Post);
}
