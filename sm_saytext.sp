/**
 * sm_saytext.sp
 *
 * client-sided chat printing with color support
 * supports standard color codes (^1-^9) and hex RGB (^RRGGBB)
 *
 * commands:
 *   sm_saytext <message> - Display private message with color support
 *   sm_saytext help      - Show help and color reference
 *
 * examples:
 *   sm_saytext Hello World!
 *   sm_saytext ^1Hello ^2World!
 *   sm_saytext ^FF0000Hello World!
 *
 * author: aimslut
 * version: 2.1.0
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

// plugin metadata
#define PLUGIN_NAME         "sm_saytext"
#define PLUGIN_VERSION      "2.1.0"
#define PLUGIN_AUTHOR       "aimslut"
#define PLUGIN_DESCRIPTION  "client-sided chat printing with color support"
#define PLUGIN_URL          "https://github.com/aimslut/sm_saytext"

// constants
#define MAX_MESSAGE_LENGTH  512
#define MAX_COMMAND_ARGUMENT_LENGTH 32

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

    RegConsoleCmd("sm_saytext", Command_SayText,
        "Display a client-sided message with color support (use sm_saytext help for more info)");

    PrintToServer("[%s] Plugin v%s loaded successfully by %s", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
}

/**
 * command handler for sm_saytext
 *
 * @param client        Client index who executed the command
 * @param argumentCount Number of arguments passed to the command
 * @return              Plugin_Handled to prevent further processing
 */
public Action Command_SayText(int client, int argumentCount) {
    if (!IsValidClient(client)) {
        return Plugin_Handled;
    }

    // get the actual player client for chat/console output
    int actualClient = GetActualClient(client);

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
        PrintToChat(actualClient, "[SM] \x07FF0000Error\x07FFFFFF: Message too long (max %d characters).", MAX_MESSAGE_LENGTH - 1);
        return Plugin_Handled;
    }

    char formattedMessage[MAX_MESSAGE_LENGTH];
    ProcessColorCodes(messageText, formattedMessage, sizeof(formattedMessage));

    // ensure the formatted message is valid before printing
    if (strlen(formattedMessage) == 0) {
        PrintToChat(actualClient, "[SM] \x07FF0000Error\x07FFFFFF: Failed to process message.");
        return Plugin_Handled;
    }

    PrintToChat(actualClient, "%s", formattedMessage);
    return Plugin_Handled;
}

// display usage/help information and help to the client
void DisplayUsageInfo(int client, bool showFullHelp = false) {
    if (showFullHelp) {
        PrintToConsole(client, "[SM] === SM SayText Help ===");
        PrintToConsole(client, "[SM] Commands:");
        PrintToConsole(client, "[SM]   sm_saytext <message> - Display private message");
        PrintToConsole(client, "[SM]   sm_saytext help - Show this help");
        PrintToConsole(client, "[SM] Note: Messages are private (only visible to you)");
    }

    PrintToConsole(client, "[SM] Usage: sm_saytext <message>");
    PrintToConsole(client, "[SM] Examples:");
    PrintToConsole(client, "[SM]   sm_saytext Hello World!");
    PrintToConsole(client, "[SM]   sm_saytext ^1Hello ^2World!");
    PrintToConsole(client, "[SM]   sm_saytext ^FF0000Hello World!");
    PrintToConsole(client, "[SM]   sm_saytext ^00FF00This is green!");

    if (showFullHelp) {
        PrintToConsole(client, "[SM] Color Codes:");
        PrintToConsole(client, "[SM]   Standard: ^1red ^2blue ^3yellow ^4green ^5cyan");
        PrintToConsole(client, "[SM]   ^6magenta ^7grey ^8orange ^9light green");
        PrintToConsole(client, "[SM]   Hex RGB: ^FF0000red ^00FF00green ^0000FFblue");
        PrintToConsole(client, "[SM]   ^FFFF00yellow ^FF00FFmagenta ^00FFFFcyan");
    }
}

/**
 * process color codes in the message (both standard and hex RGB)
 *
 * @param inputMessage      Input message with color codes
 * @param outputBuffer      Output buffer for processed message
 * @param bufferMaxLength   Maximum length of output buffer
 */
void ProcessColorCodes(const char[] inputMessage, char[] outputBuffer, int bufferMaxLength) {
    int inputLength = strlen(inputMessage);
    int outputPosition = 0;

    for (int currentIndex = 0; currentIndex < inputLength && outputPosition < bufferMaxLength - 1; currentIndex++) {
        if (inputMessage[currentIndex] == '^' && currentIndex + 1 < inputLength) {
            char nextChar = inputMessage[currentIndex + 1];

            // check for hex color codes (^RRGGBB)
            if (currentIndex + 7 <= inputLength) {
                char hexDigits[7];
                for (int i = 0; i < 6; i++) {
                    hexDigits[i] = inputMessage[currentIndex + 1 + i];
                }
                hexDigits[6] = '\0';

                if (IsValidHexColor(hexDigits)) {
                    if (outputPosition + 7 < bufferMaxLength - 1) {
                        outputBuffer[outputPosition++] = '\x07';
                        for (int hexIndex = 0; hexIndex < 6; hexIndex++) {
                            outputBuffer[outputPosition++] = inputMessage[currentIndex + 1 + hexIndex];
                        }
                        currentIndex += 6; // advance past ^RRGGBB, but the loop will increment by 1 more
                        continue;
                    }
                }
            }

            // check for standard color codes (^1-^9)
            else if (nextChar >= '1' && nextChar <= '9'){
                if (outputPosition + 2 < bufferMaxLength - 1) {
                    outputBuffer[outputPosition++] = inputMessage[currentIndex];
                    outputBuffer[outputPosition++] = nextChar;
                }
                currentIndex++;
                continue;
            }
        }

        // copy regular characters
        if (outputPosition < bufferMaxLength - 1) {
            outputBuffer[outputPosition++] = inputMessage[currentIndex];
        }
    }

    // nnull terminate the output buffer
    outputBuffer[outputPosition] = '\0';
}

// check if a 6-character string is a valid hex color code
bool IsValidHexColor(const char[] hexColor) {
    if (strlen(hexColor) != 6) {
        return false;
    }

    for (int charIndex = 0; charIndex < 6; charIndex++) {
        if (!IsValidHexDigit(hexColor[charIndex])) {
            return false;
        }
    }
    return true;
}

// check if a character is a valid hexadecimal digit (0-9, A-F, a-f)
bool IsValidHexDigit(char character) {
    return (character >= '0' && character <= '9') ||
           (character >= 'A' && character <= 'F') ||
           (character >= 'a' && character <= 'f');
}

bool IsValidClient(int client) {
    // handle normal clients (client > 0)
    if (client > 0 && client <= MaxClients) {
        return IsClientInGame(client) && !IsFakeClient(client);
    }

    // handle listen server host (client == 0)
    if (client == 0) {
        // on listen servers, find the first real player (the host)
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && !IsFakeClient(i)) {
                return true;
            }
        }
    }

    return false;
}

// get the actual client index for chat/console output
int GetActualClient(int client) {
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client)) {
        return client;
    }

    if (client == 0) {
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && !IsFakeClient(i)) {
                return i;
            }
        }
    }

    return 0; // fallback
}

public void OnPluginEnd() {
    PrintToServer("[%s] Plugin unloaded.", PLUGIN_NAME);
}