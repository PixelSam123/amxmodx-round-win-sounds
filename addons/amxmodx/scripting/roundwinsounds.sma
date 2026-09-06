#pragma semicolon 1

#include <amxmodx>
#include <cstrike>

#define PLUGIN "Round Win Sounds"
#define VERSION "1.0.0"
#define AUTHOR "PixelSam123"

#define SOUND_DIR "customroundwin"
#define MAX_SOUND_PATH 64
#define MAX_MENU_ITEM 64

#define PLAY_DELAY 0.1
#define NUM_VARIATIONS 4

// Index 0 = None (plays nothing). 1..N = real sounds.
new const g_SoundFiles[NUM_VARIATIONS][] =
{
    "",
    "candyland.wav",
    "sorry.wav",
    "whoisdonk.wav"
};
new const g_SoundDisplayNames[NUM_VARIATIONS][] =
{
    "None",
    "Candyland",
    "Sorry",
    "Who is Donk?"
};

new g_PlayerChoice[MAX_PLAYERS + 1];
new g_LastKillerT;
new g_LastKillerCT;
new g_MaxPlayers;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_MaxPlayers = get_maxplayers();
    g_LastKillerT = 0;
    g_LastKillerCT = 0;

    register_event("DeathMsg", "OnDeath", "a");
    register_event("SendAudio", "OnTerWin", "a", "2&%!MRAD_terwin");
    register_event("SendAudio", "OnCtWin", "a", "2&%!MRAD_ctwin");
    register_logevent("OnRoundStart", 2, "0=World triggered", "1=Round_Start");

    register_clcmd("say .winsound", "Cmd_ShowMenu");
    register_clcmd("say .ws", "Cmd_ShowMenu");
    register_clcmd("say_team .winsound", "Cmd_ShowMenu");
    register_clcmd("say_team .ws", "Cmd_ShowMenu");
}

public plugin_precache()
{
    new path[MAX_SOUND_PATH];

    // start from 1 because 0th sound is for None
    for (new i = 1; i < sizeof(g_SoundFiles); i++)
    {
        formatex(path, charsmax(path), "%s/%s", SOUND_DIR, g_SoundFiles[i]);
        precache_sound(path);
    }
}

public client_putinserver(id)
{
    g_PlayerChoice[id] = 0;
}

public client_disconnected(id)
{
    g_PlayerChoice[id] = 0;
}

public OnRoundStart()
{
    g_LastKillerT = 0;
    g_LastKillerCT = 0;
}

public OnDeath()
{
    new killer = read_data(1);
    new victim = read_data(2);

    if (killer < 1 || killer > g_MaxPlayers || !is_user_connected(killer)) return;

    // Ignore self-kill
    if (killer == victim) return;

    new CsTeams:team = cs_get_user_team(killer);

    if (team == CS_TEAM_T)
    {
        g_LastKillerT = killer;
    }
    else if (team == CS_TEAM_CT)
    {
        g_LastKillerCT = killer;
    }
}

public Cmd_ShowMenu(id)
{
    ShowMenu(id);
    return PLUGIN_HANDLED;
}

ShowMenu(id)
{
    new menu = menu_create("\ySelect Round Win Sound:", "MenuHandler");

    new itemText[MAX_MENU_ITEM];
    new numStr[4];
    for (new i = 0; i < sizeof(g_SoundFiles); i++)
    {
        if (g_PlayerChoice[id] == i)
        {
            formatex(itemText, charsmax(itemText), "%s \r[Selected]", g_SoundDisplayNames[i]);
        }
        else
        {
            formatex(itemText, charsmax(itemText), "%s", g_SoundDisplayNames[i]);
        }
        num_to_str(i, numStr, charsmax(numStr));

        menu_additem(menu, itemText, numStr);
    }

    menu_setprop(menu, MPROP_EXITNAME, "Exit");

    menu_display(id, menu, 0);
}

public MenuHandler(id, menu, item)
{
    if (item == MENU_EXIT)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    if (item < 0 || item >= sizeof(g_SoundFiles))
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    g_PlayerChoice[id] = item;
    client_print(id, print_chat, "[Round Win Sounds] Selected: %s", g_SoundDisplayNames[item]);

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public OnTerWin()
{
    set_task(PLAY_DELAY, "Task_PlayWinSound", _:CS_TEAM_T);
}

public OnCtWin()
{
    set_task(PLAY_DELAY, "Task_PlayWinSound", _:CS_TEAM_CT);
}

public Task_PlayWinSound(CsTeams:team)
{
    new id = ResolveWinSoundPlayer(team);

    if (id == 0) return;

    new path[MAX_SOUND_PATH];
    formatex(path, charsmax(path), "%s/%s", SOUND_DIR, g_SoundFiles[g_PlayerChoice[id]]);
    client_cmd(0, "spk ^"%s^"", path);
}

// Returns player whose sound should play, or 0 for silence.
ResolveWinSoundPlayer(CsTeams:team)
{
    new candidate = (team == CS_TEAM_T) ? g_LastKillerT : g_LastKillerCT;

    if (IsEligible(candidate, team))
    {
        return candidate;
    }

    return FindFallback(team);
}

// Validation
bool:IsEligible(id, CsTeams:team)
{
    if (id < 1 || id > g_MaxPlayers || !is_user_connected(id))
    {
        return false;
    }

    if (cs_get_user_team(id) != team)
    {
        return false;
    }

    if (g_PlayerChoice[id] <= 0 || g_PlayerChoice[id] >= sizeof(g_SoundFiles))
    {
        return false;
    }

    return true;
}

// First connected player on the winning team with a non-None choice, else 0.
FindFallback(CsTeams:team)
{
    new players[MAX_PLAYERS];
    new numPlayersOnTeam;
    new teamName[10];

    if (team == CS_TEAM_T)
    {
        copy(teamName, charsmax(teamName), "TERRORIST");
    }
    else
    {
        copy(teamName, charsmax(teamName), "CT");
    }

    get_players(players, numPlayersOnTeam, "e", teamName);

    for (new i = 0; i < numPlayersOnTeam; i++)
    {
        if (g_PlayerChoice[players[i]] > 0 && g_PlayerChoice[players[i]] < sizeof(g_SoundFiles))
        {
            return players[i];
        }
    }

    return 0;
}
