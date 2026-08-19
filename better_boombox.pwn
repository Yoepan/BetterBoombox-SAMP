#define FILTERSCRIPT
#include <open.mp>

#define MAX_BOOMBOXES MAX_PLAYERS
#define MAX_PLAYLIST_SONGS 5

enum E_BOOMBOX {
    bool:bbExists,
    bbOwnerID,
    bbOwnerName[MAX_PLAYER_NAME],
    bbObjectID,
    Text3D:bbLabel,
    Float:bbX, Float:bbY, Float:bbZ,
    bbInterior, bbVW,
    bbRadius,
    bbURL[256],
    bool:bbPlaying
}

enum E_PLAYLIST {
    bool:plUsed,
    plTitle[64],
    plURL[256]
}

new Boombox[MAX_BOOMBOXES][E_BOOMBOX];
new PlayerListeningTo[MAX_PLAYERS];
new API_BASE_URL[128]; // Menyimpan IP VPS API

new PlayerPlaylist[MAX_PLAYERS][MAX_PLAYLIST_SONGS][E_PLAYLIST];
new SelectedPlaylistSlot[MAX_PLAYERS];

// Pakai ID Dialog tinggi biar gak bentrok sama dialog Gamemode pembeli
#define DIALOG_BBB_MAIN     28400
#define DIALOG_BBB_URL      28401
#define DIALOG_BBB_RADIUS   28402
#define DIALOG_BBB_PL_LIST  28403
#define DIALOG_BBB_PL_ACT   28404
#define DIALOG_BBB_PL_ADD1  28405
#define DIALOG_BBB_PL_ADD2  28406

forward BBB_Update();

public OnFilterScriptInit()
{
    print("\n--------------------------------------");
    print(" [FS] BetterBoombox v1.1 Loaded");
    print("      + Playlist System");
    print("      + Max 10 Min Limits");
    print("--------------------------------------\n");

    GetConsoleVarAsString("bbb_api_url", API_BASE_URL, sizeof(API_BASE_URL));
    
    // BERSIHKAN NEWLINE/SPASI AGAR URL TIDAK CORRUPT
    for(new i = 0; i < strlen(API_BASE_URL); i++) {
        if(API_BASE_URL[i] == '\r' || API_BASE_URL[i] == '\n' || API_BASE_URL[i] == ' ') {
            API_BASE_URL[i] = '\0';
            break;
        }
    }

    // Mengatasi Bug SA-MP/Open.mp dimana '//' dianggap komentar
    if(strcmp(API_BASE_URL, "http:", true, 5) == 0 || strcmp(API_BASE_URL, "https:", true, 6) == 0) {
        print("[BetterBoombox] WARNING: Jangan gunakan 'http://' di server.cfg (Karena '//' dibaca sebagai komentar).");
        API_BASE_URL[0] = '\0'; // Kosongkan untuk memicu default fallback
    }

    if(strlen(API_BASE_URL) < 5) {
        format(API_BASE_URL, sizeof(API_BASE_URL), "127.0.0.1:3000");
        print("[BetterBoombox] WARNING: 'bbb_api_url' tidak ditemukan di server.cfg!");
        print("[BetterBoombox] Menggunakan default: 127.0.0.1:3000");
    } else {
        printf("[BetterBoombox] API tersambung ke IP: %s", API_BASE_URL);
    }

    for(new i = 0; i < MAX_PLAYERS; i++) {
        PlayerListeningTo[i] = -1;
        Boombox[i][bbExists] = false;
        for(new s = 0; s < MAX_PLAYLIST_SONGS; s++) {
            PlayerPlaylist[i][s][plUsed] = false;
        }
    }
    SetTimer("BBB_Update", 1000, true);
    return 1;
}

public OnFilterScriptExit()
{
    for(new i = 0; i < MAX_BOOMBOXES; i++) {
        if(Boombox[i][bbExists]) {
            DestroyObject(Boombox[i][bbObjectID]);
            Delete3DTextLabel(Boombox[i][bbLabel]);
        }
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerListeningTo[playerid] = -1;
    for(new s = 0; s < MAX_PLAYLIST_SONGS; s++) {
        PlayerPlaylist[playerid][s][plUsed] = false;
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(Boombox[playerid][bbExists]) {
        DestroyObject(Boombox[playerid][bbObjectID]);
        Delete3DTextLabel(Boombox[playerid][bbLabel]);
        Boombox[playerid][bbExists] = false;
        Boombox[playerid][bbPlaying] = false;
        
        for(new i = 0; i < MAX_PLAYERS; i++) {
            if(IsPlayerConnected(i) && PlayerListeningTo[i] == playerid) {
                StopAudioStreamForPlayer(i);
                PlayerListeningTo[i] = -1;
            }
        }
    }
    return 1;
}

forward PlaceBetterBoombox(playerid);
public PlaceBetterBoombox(playerid)
{
    if(Boombox[playerid][bbExists]) {
        SendClientMessage(playerid, 0xFF0000FF, "[BetterBoombox] You already placed a boombox! Pickup the old one first.");
        return 0; 
    }

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    x += (1.0 * floatsin(-a, degrees));
    y += (1.0 * floatcos(-a, degrees));
    z -= 0.8;

    GetPlayerName(playerid, Boombox[playerid][bbOwnerName], MAX_PLAYER_NAME);
    Boombox[playerid][bbOwnerID] = playerid;
    Boombox[playerid][bbX] = x;
    Boombox[playerid][bbY] = y;
    Boombox[playerid][bbZ] = z;
    Boombox[playerid][bbInterior] = GetPlayerInterior(playerid);
    Boombox[playerid][bbVW] = GetPlayerVirtualWorld(playerid);
    Boombox[playerid][bbRadius] = 100;
    Boombox[playerid][bbPlaying] = false;
    Boombox[playerid][bbURL][0] = '\0';

    Boombox[playerid][bbObjectID] = CreateObject(2226, x, y, z, 0.0, 0.0, a);
    
    // Animasi Naruh Boombox
    ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.0, 0, 0, 0, 0, 0);
    
    new labelStr[128];
    format(labelStr, sizeof(labelStr), "{FFaa00}%s's BetterBoombox\n{FFFFFF}/setbb or /pickupbb", Boombox[playerid][bbOwnerName]);
    Boombox[playerid][bbLabel] = Create3DTextLabel(labelStr, 0xFFFFFFFF, x, y, z + 0.8, 10.0, Boombox[playerid][bbVW], 0);

    Boombox[playerid][bbExists] = true;

    SendClientMessage(playerid, 0x00FF00FF, "[BetterBoombox] Boombox placed successfully!");
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if(strcmp(cmdtext, "/pickupbb", true) == 0)
    {
        if(!Boombox[playerid][bbExists]) return SendClientMessage(playerid, 0xFF0000FF, "[BetterBoombox] You don't have a boombox placed.");
        if(GetPlayerSpecialAction(playerid) != SPECIAL_ACTION_DUCK) return SendClientMessage(playerid, 0xFF0000FF, "[BetterBoombox] You must crouch (C) to pick up your boombox.");
        if(GetPlayerDistanceFromPoint(playerid, Boombox[playerid][bbX], Boombox[playerid][bbY], Boombox[playerid][bbZ]) > 3.0) return SendClientMessage(playerid, 0xFF0000FF, "[BetterBoombox] You are too far from your boombox.");

        // Animasi Ngambil Boombox
        ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.0, 0, 0, 0, 0, 0);

        for(new i = 0; i < MAX_PLAYERS; i++) {
            if(IsPlayerConnected(i) && PlayerListeningTo[i] == playerid) {
                StopAudioStreamForPlayer(i);
                PlayerListeningTo[i] = -1;
            }
        }

        DestroyObject(Boombox[playerid][bbObjectID]);
        Delete3DTextLabel(Boombox[playerid][bbLabel]);
        Boombox[playerid][bbExists] = false;
        Boombox[playerid][bbPlaying] = false;
        
        CallRemoteFunction("OnBetterBoomboxPickup", "i", playerid);
        
        SendClientMessage(playerid, 0x00FF00FF, "[BetterBoombox] Boombox picked up!");
        return 1;
    }

    if(strcmp(cmdtext, "/setbb", true) == 0)
    {
        if(!Boombox[playerid][bbExists]) return SendClientMessage(playerid, 0xFF0000FF, "[BetterBoombox] You don't have a boombox placed.");
        if(GetPlayerSpecialAction(playerid) != SPECIAL_ACTION_DUCK) return SendClientMessage(playerid, 0xFF0000FF, "[BetterBoombox] You must crouch (C) to set the boombox.");
        if(GetPlayerDistanceFromPoint(playerid, Boombox[playerid][bbX], Boombox[playerid][bbY], Boombox[playerid][bbZ]) > 3.0) return SendClientMessage(playerid, 0xFF0000FF, "[BetterBoombox] You are too far from your boombox.");

        ShowBBBMainMenu(playerid);
        return 1;
    }

    return 0;
}

stock ShowBBBMainMenu(playerid)
{
    new str[256];
    format(str, sizeof(str), "Play Direct URL\nMy Playlist (Favorites)\nStop Music\nSet Radius (Current: %d%%)", Boombox[playerid][bbRadius]);
    ShowPlayerDialog(playerid, DIALOG_BBB_MAIN, DIALOG_STYLE_LIST, "BetterBoombox Menu", str, "Select", "Close");
    return 1;
}

stock ShowBBBPlaylist(playerid)
{
    new str[512];
    for(new i = 0; i < MAX_PLAYLIST_SONGS; i++) {
        if(PlayerPlaylist[playerid][i][plUsed]) {
            format(str, sizeof(str), "%s%d. %s\n", str, i+1, PlayerPlaylist[playerid][i][plTitle]);
        } else {
            format(str, sizeof(str), "%s%d. [Empty Slot]\n", str, i+1);
        }
    }
    ShowPlayerDialog(playerid, DIALOG_BBB_PL_LIST, DIALOG_STYLE_LIST, "My Playlist", str, "Select", "Back");
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_BBB_MAIN)
    {
        if(!response) return 1;
        switch(listitem)
        {
            case 0: ShowPlayerDialog(playerid, DIALOG_BBB_URL, DIALOG_STYLE_INPUT, "Play Music", "Enter YouTube URL (Max 10 Mins):", "Play", "Back");
            case 1: ShowBBBPlaylist(playerid);
            case 2: 
            {
                Boombox[playerid][bbPlaying] = false;
                for(new i = 0; i < MAX_PLAYERS; i++) {
                    if(IsPlayerConnected(i) && PlayerListeningTo[i] == playerid) {
                        StopAudioStreamForPlayer(i);
                        PlayerListeningTo[i] = -1;
                    }
                }
                ShowBBBMainMenu(playerid);
            }
            case 3:
            {
                new str[128];
                format(str, sizeof(str), "20%%\n40%%\n60%%\n80%%\n100%%");
                ShowPlayerDialog(playerid, DIALOG_BBB_RADIUS, DIALOG_STYLE_LIST, "Radius", str, "Save", "Back");
            }
        }
        return 1;
    }
    
    if(dialogid == DIALOG_BBB_URL)
    {
        if(!response) return ShowBBBMainMenu(playerid);
        if(strlen(inputtext) < 5) return ShowBBBMainMenu(playerid);

        format(Boombox[playerid][bbURL], 256, "%s", inputtext);
        Boombox[playerid][bbPlaying] = true;
        
        SendClientMessage(playerid, 0xFFFF00FF, "[BetterBoombox] Please wait a few seconds for the audio stream to buffer...");
        
        for(new i = 0; i < MAX_PLAYERS; i++) {
            if(IsPlayerConnected(i) && PlayerListeningTo[i] == playerid) {
                StopAudioStreamForPlayer(i);
                PlayerListeningTo[i] = -1;
            }
        }
        return 1;
    }

    if(dialogid == DIALOG_BBB_RADIUS)
    {
        if(!response) return ShowBBBMainMenu(playerid);
        Boombox[playerid][bbRadius] = 20 + (listitem * 20);
        for(new i = 0; i < MAX_PLAYERS; i++) {
            if(IsPlayerConnected(i) && PlayerListeningTo[i] == playerid) {
                StopAudioStreamForPlayer(i);
                PlayerListeningTo[i] = -1;
            }
        }
        ShowBBBMainMenu(playerid);
        return 1;
    }

    if(dialogid == DIALOG_BBB_PL_LIST)
    {
        if(!response) return ShowBBBMainMenu(playerid);
        SelectedPlaylistSlot[playerid] = listitem;
        
        if(PlayerPlaylist[playerid][listitem][plUsed]) {
            ShowPlayerDialog(playerid, DIALOG_BBB_PL_ACT, DIALOG_STYLE_LIST, "Playlist Action", "Play Song\nDelete Song", "Select", "Back");
        } else {
            ShowPlayerDialog(playerid, DIALOG_BBB_PL_ADD1, DIALOG_STYLE_INPUT, "Add to Playlist", "Enter YouTube URL (Max 10 Mins):", "Next", "Back");
        }
        return 1;
    }

    if(dialogid == DIALOG_BBB_PL_ACT)
    {
        if(!response) return ShowBBBPlaylist(playerid);
        new slot = SelectedPlaylistSlot[playerid];
        
        if(listitem == 0) // Play
        {
            format(Boombox[playerid][bbURL], 256, "%s", PlayerPlaylist[playerid][slot][plURL]);
            Boombox[playerid][bbPlaying] = true;
            
            SendClientMessage(playerid, 0xFFFF00FF, "[BetterBoombox] Please wait a few seconds for the audio stream to buffer...");
            
            for(new i = 0; i < MAX_PLAYERS; i++) {
                if(IsPlayerConnected(i) && PlayerListeningTo[i] == playerid) {
                    StopAudioStreamForPlayer(i);
                    PlayerListeningTo[i] = -1;
                }
            }
        }
        else if(listitem == 1) // Delete
        {
            PlayerPlaylist[playerid][slot][plUsed] = false;
            ShowBBBPlaylist(playerid);
        }
        return 1;
    }

    if(dialogid == DIALOG_BBB_PL_ADD1)
    {
        if(!response) return ShowBBBPlaylist(playerid);
        if(strlen(inputtext) < 5) return ShowBBBPlaylist(playerid);
        
        new slot = SelectedPlaylistSlot[playerid];
        format(PlayerPlaylist[playerid][slot][plURL], 256, "%s", inputtext);
        ShowPlayerDialog(playerid, DIALOG_BBB_PL_ADD2, DIALOG_STYLE_INPUT, "Add to Playlist", "Enter Song Title:", "Save", "Back");
        return 1;
    }

    if(dialogid == DIALOG_BBB_PL_ADD2)
    {
        if(!response) return ShowBBBPlaylist(playerid);
        if(strlen(inputtext) < 1) return ShowBBBPlaylist(playerid);
        
        new slot = SelectedPlaylistSlot[playerid];
        format(PlayerPlaylist[playerid][slot][plTitle], 64, "%s", inputtext);
        PlayerPlaylist[playerid][slot][plUsed] = true;
        
        ShowBBBPlaylist(playerid);
        return 1;
    }

    return 0;
}

public BBB_Update()
{
    new highest_player = GetMaxPlayers();
    if(highest_player == 0) return;

    for(new i = 0; i <= highest_player; i++)
    {
        if(!IsPlayerConnected(i)) continue;

        new closest_bb_owner = -1;
        new Float:closest_dist = 99999.0;
        new Float:pX, Float:pY, Float:pZ;
        new pVW = GetPlayerVirtualWorld(i);
        new pInt = GetPlayerInterior(i);
        
        GetPlayerPos(i, pX, pY, pZ);

        for(new b = 0; b <= highest_player; b++)
        {
            if(!Boombox[b][bbExists] || !Boombox[b][bbPlaying]) continue;
            if(pVW != Boombox[b][bbVW]) continue;
            if(pInt != Boombox[b][bbInterior]) continue;

            new Float:dist = VectorSize(pX - Boombox[b][bbX], pY - Boombox[b][bbY], pZ - Boombox[b][bbZ]);
            if(dist <= 100.0 && dist < closest_dist) {
                closest_dist = dist;
                closest_bb_owner = b;
            }
        }

        if(closest_bb_owner != -1)
        {
            new Float:maxDist = 30.0 * (float(Boombox[closest_bb_owner][bbRadius]) / 100.0);
            if(PlayerListeningTo[i] != closest_bb_owner)
            {
                new api_url[512];
                format(api_url, sizeof(api_url), "http://%s/play?token=bbb_premium_889&url=%s", API_BASE_URL, Boombox[closest_bb_owner][bbURL]);
                
                StopAudioStreamForPlayer(i);
                PlayAudioStreamForPlayer(i, api_url, Boombox[closest_bb_owner][bbX], Boombox[closest_bb_owner][bbY], Boombox[closest_bb_owner][bbZ], maxDist, 1);
                PlayerListeningTo[i] = closest_bb_owner;
            }
        }
        else
        {
            if(PlayerListeningTo[i] != -1)
            {
                StopAudioStreamForPlayer(i);
                PlayerListeningTo[i] = -1;
            }
        }
    }
}
