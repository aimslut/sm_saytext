# sm_saytext

## usage
### commands
- `sm_saytext <message>` - display a private message (only visible to you)
- `sm_saytext help` - show detailed help and color reference
### color codes
| color | standard code | hex code |
|-------|---------------|----------|
| red | `^1` | `^FF0000` |
| blue | `^2` | `^0000FF` |
| yellow | `^3` | `^FFFF00` |
| green | `^4` | `^00FF00` |
| cyan | `^5` | `^00FFFF` |
| magenta | `^6` | `^FF00FF` |
| grey | `^7` | `^808080` |
| orange | `^8` | `^FFA500` |
| light green | `^9` | `^90EE90` |

( any hex code can be used as long as it's RGB, not RGBA )

## examples
### basic usage
```
sm_saytext Hello World!
sm_saytext ^1Error: ^7Something went wrong!
```
### config example
```
// status messages
alias "text_turnbinds" "^FFFFFF[^00FF00cfg^FFFFFF] turnbinds."
alias "text_flashes" "^FFFFFF[^FF0000cfg^FFFFFF] flashes."

// turnbind example
alias "togglespin" "spin_on"
alias "spin_on" "bind mouse1 +left; bind mouse2 +right; -attack; -attack2; alias togglespin spin_off; text_turnbinds"
alias "spin_off" "bind mouse1 +attack; bind mouse2 +attack2; -left; -right; alias togglespin spin_on; text_flashes"
```

## requirements
- sourcemod 1.10 or higher
- game with sourcemod support ( css, tf2, etc. )

## Installation
1. download the latest release from the releases
2. place the `.smx` file in `sourcemod/plugins/`
3. restart the server or use `sm plugins load sm_saytext`