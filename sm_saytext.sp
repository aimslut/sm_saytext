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
 * version: 2.0.0
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

// Plugin metadata
#define PLUGIN_NAME         "sm_saytext"
#define PLUGIN_VERSION      "2.0.0"
#define PLUGIN_AUTHOR       "aimslut"
#define PLUGIN_DESCRIPTION  "client-sided chat printing with color support"
#define PLUGIN_URL          ""

// Constants
#define MAX_MESSAGE_LENGTH  512
#define MAX_COLOR_CODE_LENGTH 8
#define MAX_COMMAND_ARGUMENT_LENGTH 32

public Plugin myinfo = {
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
};

// Plugin initialization - registers commands and logs startup
public void OnPluginStart() {
    RegConsoleCmd("sm_saytext", Command_SayText,
        "Display a client-sided message with color support (use sm_saytext help for more info)");

    PrintToServer("[%s] Plugin v%s loaded successfully by %s", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
}

/**
 * Command handler for sm_saytext
 *
 * @param client        Client index who executed the command
 * @param argumentCount Number of arguments passed to the command
 * @return              Plugin_Handled to prevent further processing
 */
public Action Command_SayText(int client, int argumentCount) {
    if (!IsValidClient(client)) {
        return Plugin_Handled;
    }

    if (argumentCount >= 1) {
        char commandArgument[32];
        GetCmdArg(1, commandArgument, sizeof(commandArgument));

        if (StrEqual(commandArgument, "help", false)) {
            DisplayUsageInfo(client, true);
            return Plugin_Handled;
        }
    }

    if (argumentCount < 1) {
        DisplayUsageInfo(client, false);
        return Plugin_Handled;
    }

    char messageText[MAX_MESSAGE_LENGTH];
    GetCmdArgString(messageText, sizeof(messageText));
    TrimString(messageText);

    if (!IsValidMessage(messageText)) {
        PrintToChat(client, "[SM] ^FF0000Error^FFFFFF: Message cannot be empty.");
        DisplayUsageInfo(client, false);
        return Plugin_Handled;
    }

    char formattedMessage[MAX_MESSAGE_LENGTH];
    ProcessColorCodes(messageText, formattedMessage, sizeof(formattedMessage));
    PrintToChat(client, "%s", formattedMessage);
    return Plugin_Handled;
}

// Display usage/help information and help to the client
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
 * Process color codes in the message (both standard and hex RGB)
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
            if (currentIndex + 7 <= inputLength && IsValidHexColor(inputMessage[currentIndex + 1])) {
                if (outputPosition + 7 < bufferMaxLength - 1) {
                    outputBuffer[outputPosition++] = '\x07';
                    for (int hexIndex = 0; hexIndex < 6; hexIndex++) {
                        outputBuffer[outputPosition++] = inputMessage[currentIndex + 1 + hexIndex];
                    }
                }
                currentIndex += 7;
                continue;
            }

            else if (nextChar >= '1' && nextChar <= '9'){
                if (outputPosition + 2 < bufferMaxLength - 1) {
                    outputBuffer[outputPosition++] = inputMessage[currentIndex];
                    outputBuffer[outputPosition++] = nextChar;
                }
                currentIndex++;
                continue;
            }
        }
        outputBuffer[outputPosition++] = inputMessage[currentIndex];
    }
    outputBuffer[outputPosition] = '\0';
}


// Check if a 6-character string is a valid hex color code
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

// Check if a character is a valid hexadecimal digit
bool IsValidHexDigit(char character) {
    return (character >= '0' && character <= '9') ||
           (character >= 'A' && character <= 'F') ||
           (character >= 'a' && character <= 'f');
}

bool IsValidClient(int client) {
    return (client >= 1 && client <= MaxClients && IsClientInGame(client));
}

bool IsValidMessage(const char[] message) {
    return (strlen(message) > 0);
}

public void OnPluginEnd(){
    PrintToServer("[%s] Plugin unloaded.", PLUGIN_NAME);
}