/**
 * sm_saytext.sp
 *
 * client-sided chat printing with color support
 * supports standard color codes (^1-^9) and hex RGB (^RRGGBB)
 *
 * commands:
 *   sm_saytext <message> - Display private message with color support
 *   sm_saytext help      - Show help and color reference
 *   sm_saytext           - Show usage information
 *
 * examples:
 *   sm_saytext Hello World!
 *   sm_saytext ^1Hello ^2World!
 *   sm_saytext ^FF0000Hello World!
 *
 * author: aimslut
 * version: 2.2.0
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

// plugin metadata
#define PLUGIN_NAME         "sm_saytext"
#define PLUGIN_VERSION      "2.2.0"
#define PLUGIN_AUTHOR       "aimslut"
#define PLUGIN_DESCRIPTION  "client-sided chat printing with color support"
#define PLUGIN_URL          "https://github.com/aimslut/sm_saytext"

// buffer sizes
#define MAX_MESSAGE_LENGTH  512
#define MAX_COMMAND_ARGUMENT_LENGTH 32

// color code constants
#define HEX_COLOR_LENGTH 6
#define STANDARD_COLOR_MIN '1'
#define STANDARD_COLOR_MAX '9'
#define STANDARD_COLOR_CODE_LENGTH 2

// error messages
#define MSG_MESSAGE_TOO_LONG "[SM] \x07FF0000Error\x07FFFFFF: Message too long (max %d characters)."
#define MSG_PROCESSING_FAILED "[SM] \x07FF0000Error\x07FFFFFF: Failed to process message."

// help constants
#define MSG_USAGE_HELP "[SM] === SM SayText Help ===\n[SM] Commands:\n[SM]   sm_saytext <message> - Display private message\n[SM]   sm_saytext help - Show this help\n[SM] Note: Messages are client-sided.\n[SM] Color Codes:\n[SM]   Standard: ^1red ^2blue ^3yellow ^4green ^5cyan\n[SM]   ^6magenta ^7grey ^8orange ^9light green\n[SM]   Hex RGB: ^FF0000red ^00FF00green ^0000FFblue\n[SM]   ^FFFF00yellow ^FF00FFmagenta ^00FFFFcyan"
#define MSG_USAGE_EXAMPLES "[SM] Usage: sm_saytext <message>\n[SM] Examples:\n[SM]   sm_saytext Hello World!\n[SM]   sm_saytext ^1Hello ^2World!\n[SM]   sm_saytext ^FF0000Hello World!\n[SM]   sm_saytext ^00FF00This is green!"

public Plugin myinfo = {
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
};

// plugin initialization
public void OnPluginStart() {
    CreateConVar("sm_saytext_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    RegConsoleCmd("sm_saytext", Command_SayText, "Display a client-sided message with color support (use sm_saytext help for more info)");
    PrintToServer("[%s] Plugin v%s loaded successfully by %s", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
}

// handles the sm_saytext command
public Action Command_SayText(int client, int argumentCount) {
    int actualClient = IsValidClient(client);
    if (actualClient == 0) {
        return Plugin_Handled;
    }

    // handle help command
    if (argumentCount >= 1) {
        char commandArgument[MAX_COMMAND_ARGUMENT_LENGTH];
        GetCmdArg(1, commandArgument, sizeof(commandArgument));

        if (StrEqual(commandArgument, "help", false)) {
            DisplayUsageInfo(actualClient, true);
            return Plugin_Handled;
        }
    }

    // get the full message text, including spaces, remove unnecessary whitespace, and strip quotes
    char messageText[MAX_MESSAGE_LENGTH];
    GetCmdArgString(messageText, sizeof(messageText));
    TrimString(messageText);
    StripQuotes(messageText);

    // handle empty messages
    if (strlen(messageText) == 0) {
        DisplayUsageInfo(actualClient, false);
        return Plugin_Handled;
    }

    // check for message length limits
    if (strlen(messageText) >= MAX_MESSAGE_LENGTH - 1) {
        PrintToChat(actualClient, MSG_MESSAGE_TOO_LONG, MAX_MESSAGE_LENGTH - 1);
        return Plugin_Handled;
    }

    char formattedMessage[MAX_MESSAGE_LENGTH];
    ProcessColorCodes(messageText, formattedMessage, sizeof(formattedMessage));

    // ensure the formatted message is valid before printing
    if (strlen(formattedMessage) == 0) {
        PrintToChat(actualClient, MSG_PROCESSING_FAILED);
        return Plugin_Handled;
    }

    PrintToChat(actualClient, "%s", formattedMessage);
    return Plugin_Handled;
}

// display usage/help information and help to the client
void DisplayUsageInfo(int client, bool showFullHelp = false) {
    if (showFullHelp) {
        PrintToConsole(client, MSG_USAGE_HELP);
    } else {
        PrintToConsole(client, MSG_USAGE_EXAMPLES);
    }
}

// processes color codes in the message (both standard ^1-^9 and hex rgb ^RRGGBB)
void ProcessColorCodes(const char[] inputMessage, char[] outputBuffer, int bufferMaxLength) {
    int inputLength = strlen(inputMessage);
    if (inputLength == 0 || bufferMaxLength <= 1) {
        outputBuffer[0] = '\0';
        return;
    }

    int outputPosition = 0;

    for (int currentIndex = 0; currentIndex < inputLength && outputPosition < bufferMaxLength - 1; currentIndex++) {
        if (inputMessage[currentIndex] == '^' && currentIndex + 1 < inputLength) {
            char nextChar = inputMessage[currentIndex + 1];

            // check for standard color codes (^1-^9) first
            if (nextChar >= STANDARD_COLOR_MIN && nextChar <= STANDARD_COLOR_MAX) {
                if (outputPosition + STANDARD_COLOR_CODE_LENGTH >= bufferMaxLength - 1) {
                    break; // not enough space for color code
                }
                outputBuffer[outputPosition++] = inputMessage[currentIndex];
                outputBuffer[outputPosition++] = nextChar;
                currentIndex++; // skip the color digit
                continue;
            }

            // check for hex color codes (^RRGGBB) - longer pattern
            if (currentIndex + HEX_COLOR_LENGTH + 1 <= inputLength && IsValidHexColor(inputMessage[currentIndex + 1])) {
                if (outputPosition + HEX_COLOR_LENGTH + 1 >= bufferMaxLength - 1) {
                    break; // not enough space for hex color
                }

                // copy hex color directly without intermediate buffer
                outputBuffer[outputPosition++] = '\x07';
                for (int hexIndex = 0; hexIndex < HEX_COLOR_LENGTH; hexIndex++) {
                    outputBuffer[outputPosition++] = inputMessage[currentIndex + 1 + hexIndex];
                }
                currentIndex += HEX_COLOR_LENGTH; // skip the hex digits
                continue;
            }
        }

        // copy regular characters
        outputBuffer[outputPosition++] = inputMessage[currentIndex];
    }

    outputBuffer[outputPosition] = '\0';
}

// validates that HEX_COLOR_LENGTH consecutive characters are valid hexadecimal digits
bool IsValidHexColor(const char[] hexColor) {
    // check if we have HEX_COLOR_LENGTH valid hex digits in a row
    for (int i = 0; i < HEX_COLOR_LENGTH; i++) {
        char c = hexColor[i];
        if (!((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f'))) {
            return false;
        }
    }
    return true;
}

// validates client and returns client index or first valid alternative
int IsValidClient(int client) {
    // if specific client requested, validate it first
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client)) {
        return client;
    }

    // if client is 0 or invalid, find first available client
    if (client == 0) {
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && !IsFakeClient(i)) {
                return i;
            }
        }
    }

    return 0;
}

public void OnPluginEnd() {
    PrintToServer("[%s] Plugin unloaded.", PLUGIN_NAME);
}