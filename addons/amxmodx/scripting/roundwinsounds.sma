#pragma semicolon 1

#include <amxmodx>
#include <cstrike>

#define PLUGIN "Round Win Sounds"
#define VERSION "1.0.0"
#define AUTHOR "PixelSam123"

#define SOUND_DIR "customroundwin"
#define MAX_SOUND_PATH 64
#define MAX_MENU_ITEM 64
#define PLAY_DELAY 0.08

// Index 0 = None (plays nothing). 1..N = real sounds.
new const g_SoundFiles[][] =
{
    "",
    "candyland.wav",
    "sorry.wav",
    "whoisdonk.wav"
};

new const g_SoundDisplayNames[][] =
{
    "None",
    "Candyland",
    "Sorry",
    "Who is Donk?"
};

new g_PlayerChoice[33];
new g_LastKillerT;
new g_LastKillerCT;
new g_MaxPlayers;

public plugin_precache()
{
    new path[MAX_SOUND_PATH];

    for (new i = 1; i < sizeof(g_SoundFiles); i++)
    {
        formatex(path, charsmax(path), "%s/%s", SOUND_DIR, g_SoundFiles[i]);
        precache_sound(path);
    }
}

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

    if (killer < 1 || killer > g_MaxPlayers || !is_user_connected(killer))
    {
        return;
    }

    // Skip suicides (includes kill console command).
    if (killer == victim)
    {
        return;
    }

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
    new menu = menu_create("Select Round Win Sound:", "MenuHandler");
    new itemText[MAX_MENU_ITEM];
    new numStr[4];
    new count = sizeof(g_SoundFiles);

    for (new i = 0; i < count; i++)
    {
        if (g_PlayerChoice[id] == i)
        {
            formatex(itemText, charsmax(itemText), "%s [Selected]", g_SoundDisplayNames[i]);
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
    if (item < 0)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new cmd[4];
    new access;
    new callback;
    menu_item_getinfo(menu, item, access, cmd, charsmax(cmd), _, _, callback);

    new choice = str_to_num(cmd);

    if (choice >= 0 && choice < sizeof(g_SoundFiles))
    {
        g_PlayerChoice[id] = choice;
        client_print(id, print_chat, "[Round Win Sounds] Selected: %s", g_SoundDisplayNames[choice]);
    }

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

    if (id == 0)
    {
        return;
    }

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
    new players[32];
    new num;
    new teamName[10];

    if (team == CS_TEAM_T)
    {
        copy(teamName, charsmax(teamName), "TERRORIST");
    }
    else
    {
        copy(teamName, charsmax(teamName), "CT");
    }

    get_players(players, num, "e", teamName);

    for (new i = 0; i < num; i++)
    {
        if (g_PlayerChoice[players[i]] > 0 && g_PlayerChoice[players[i]] < sizeof(g_SoundFiles))
        {
            return players[i];
        }
    }

    return 0;
}
