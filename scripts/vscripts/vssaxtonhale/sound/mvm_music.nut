//==============================
//MvM Music
//==============================

// Custom channel for our music so we can stop/replace it independently of
// other sounds. Values 0-7 and 8-107 have special engine meaning (weapons,
// voice chat, etc.) so we pick something outside that range.
::MUSIC_CHANNEL <- 110;

::CurrentMusicSound <- null;

// Bumped every time we stop music or start a new setup countdown, so a
// RunWithDelay2 callback scheduled by an earlier round/setup can detect it's
// stale (e.g. boss dies 1 second into setup, before the 4-second start jingle
// delay elapses) and skip playing.
::MusicGeneration <- 0;

PrecacheScriptSound("music.mvm_start_wave");
PrecacheScriptSound("music.mvm_end_mid_wave");
PrecacheScriptSound("music.mvm_lost_wave");

// Plays a music soundscript globally, stopping whatever was previously
// playing on our music channel first.
// Declared with :: so it lives on the true root table and is reachable
// from any script scope (RunWithDelay2's rebound `this`, other files'
// listener callbacks, etc.) - a bare `function PlayMusic(...)` would only
// attach to this file's own local scope and fail everywhere else.
::PlayMusic <- function(sound_name)
{
    if (::CurrentMusicSound != null)
    {
        EmitSoundEx(
        {
            sound_name  = ::CurrentMusicSound,
            channel     = ::MUSIC_CHANNEL,
            flags       = 4, // SND_STOP
            filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
        });
    }

    EmitSoundEx(
    {
        sound_name  = sound_name,
        channel     = ::MUSIC_CHANNEL,
        volume      = 0.55,
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
    });

    ::CurrentMusicSound = sound_name;
}

// Stops whatever is currently playing on our music channel, if anything.
::StopMusic <- function()
{
    ::MusicGeneration++;

    if (::CurrentMusicSound == null)
        return;

    EmitSoundEx(
    {
        sound_name  = ::CurrentMusicSound,
        channel     = ::MUSIC_CHANNEL,
        flags       = 4, // SND_STOP
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
    });

    ::CurrentMusicSound = null;
}

// Fires every round (round_logic.nut already hooks this for team setup),
// so this replaces the old one-shot RunWithDelay2 that only ran at map load.
AddListener("setup_start", 0, function()
{
    ::StopMusic(); // clear out any leftover track from a previous round
    local myGeneration = ::MusicGeneration;

    RunWithDelay2(this, 4, function()
    {
        // Skip if the round/setup already ended since this was scheduled.
        if (myGeneration == ::MusicGeneration)
            ::PlayMusic("music.mvm_start_wave");
    });
});

// EndRound() in round_logic.nut calls FireListeners("round_end", winner) with
// winner as a plain team int (TF_TEAM_MERCS / TF_TEAM_BOSS / TF_TEAM_UNASSIGNED),
// not a params table. Note round_logic.nut also calls EndRound(TF_TEAM_UNASSIGNED)
// when the boss dies mid-setup, so that case is covered here too.
AddListener("round_end", 0, function(winner)
{
    if (winner == TF_TEAM_MERCS)
        ::PlayMusic("music.mvm_end_mid_wave");
    else if (winner == TF_TEAM_BOSS)
        ::PlayMusic("music.mvm_lost_wave");
    else
        ::StopMusic(); // TF_TEAM_UNASSIGNED (stalemate/draw): no win/lose track
});

// Extra safety net: if the boss disconnects, stop the music even if nothing
// else in the framework ends the round for it.
AddListener("disconnect", 0, function(player, params)
{
    if (IsValidBoss(player))
        ::StopMusic();
});