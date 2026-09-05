#if defined _mewstats_chat_included_
#endinput
#endif
#define _mewstats_chat_included_

#include <string>
#include <usermessages>

#include <mewstats/util>

#define MEWSTATS_CHAT_COLOR_HEX "\x7"
#define MEWSTATS_CHAT_COLOR_WHITE MEWSTATS_CHAT_COLOR_HEX ... "FFFFFF"
#define MEWSTATS_CHAT_COLOR_PINK MEWSTATS_CHAT_COLOR_HEX ... "FFC0CB"
#define MEWSTATS_CHAT_COLOR_GRAY MEWSTATS_CHAT_COLOR_HEX ... "C9C0BB"
#define MEWSTATS_CHAT_COLOR_VIOLET MEWSTATS_CHAT_COLOR_HEX ... "EE82EE"
#define MEWSTATS_CHAT_COLOR_THISTLE MEWSTATS_CHAT_COLOR_HEX ... "D8BFD8"
#define MEWSTATS_CHAT_COLOR_BRIGHT_THISTLE MEWSTATS_CHAT_COLOR_HEX ... "ECC5F7"
#define MEWSTATS_CHAT_COLOR_ICE MEWSTATS_CHAT_COLOR_HEX ... "C1CCE6"
#define MEWSTATS_CHAT_COLOR_PALE_ICE MEWSTATS_CHAT_COLOR_HEX ... "E3F2FD"

#define MEWSTATS_CHAT_SEPARATOR_SIZE 16
#define MEWSTATS_CHAT_SEPARATOR_SPACE " "
#define MEWSTATS_CHAT_SEPARATOR_LINE " | "

stock bool Mewstats_SayText2(int client, bool bSound, const char[] szFormat, any ...)
{
    if (!Mewstats_IsClientInGame(client))
    {
        return false;
    }

    char szMessage[256];
    VFormat(szMessage, sizeof(szMessage), szFormat, 3);

    Handle hSayText2 = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
    if (hSayText2 == INVALID_HANDLE)
    {
        return false;
    }

    BfWrite bfMsg = UserMessageToBfWrite(hSayText2);
    bfMsg.WriteByte(client);
    bfMsg.WriteByte(bSound ? 1 : 0);
    bfMsg.WriteString(szMessage);

    EndMessage();
    return true;
}
