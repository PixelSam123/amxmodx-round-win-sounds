# AMX Mod X Round Win Sounds

Play custom sounds after winning a round in CS 1.6 server.  
Choices are hardcoded, but pickable for each player.

Each player picks their custom sound through a command that shows a menu of choices.  
When the round finishes, the custom sound is played depending on which player gets the latest kill during the round.  
For scenarios where round finishes without a kill (like no one gets a kill and the round time runs out), the sound played defaults to the first player in the winning team.

## SOUND FILE WARNING

The `.wav` files supplied are placeholder empty files to avoid copyright issues!  
Please supply your own sound files.

## Round Win Sound Variations

Sounds are stored under `cstrike/sound/customroundwin/<soundname>.wav`.  
All variations are precached via a loop over the configurable sound name variations array. There's two configurable arrays, one for the real file names, and the other for the displayed choice names. Recompile to apply changes.

## Player Commands

Players can choose their round win sound variation in-game via chat:

- `.winsound`
- `.ws` (short alias)

Both `say` and `say_team` are supported (case-sensitive).

Typing either command opens a numeric select menu:

```
Select Round Win Sound:
1. None [Selected]
2. Candyland
3. Sorry
4. Who is Donk?
```

Selection is per-player, in-memory only, and defaults to None (a special choice that does not play any sound) when a player joins.
