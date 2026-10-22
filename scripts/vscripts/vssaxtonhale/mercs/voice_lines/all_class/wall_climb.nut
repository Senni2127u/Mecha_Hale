//=========================================================================
//Copyright LizardOfOz.
//
//Credits:
//  LizardOfOz - Programming, game design, promotional material and overall development. The original VSH Plugin from 2010.
//  Maxxy - Saxton Hale's model imitating Jungle Inferno SFM; Custom animations and promotional material.
//  Velly - VFX, animations scripting, technical assistance.
//  JPRAS - Saxton model development assistance and feedback.
//  MegapiemanPHD - Saxton Hale and Gray Mann voice acting.
//  James McGuinn - Mercenaries voice acting for custom lines.
//  Yakibomb - give_tf_weapon script bundle (used for Hale's first-person hands model).
//  Phe - game design assistance.
//=========================================================================

PrecacheClassVoiceLines("wall_climb")

characterTraitsClasses.push(class extends CustomVoiceLine
{
    tickInverval = 0.5;
    sharedPlayInterval = 20;
    sharedPlayPool = 3;
    lastTimePlayedLine = {};
    climbLineTimesPlayed = [0];
    wallClimbListener = null;
    usingBFB = false;

    function OnApply()
    {
        wallClimbListener = AddListener("wall_climb", 0, OnWallClimb, this);
        local primary = player.GetWeaponBySlot(0);
        usingBFB = primary && primary.GetAttribute("hype resets on jump", 0);
    }

    function OnWallClimb(otherPlayer, streak, quickFixLink)
    {
        if (player != otherPlayer)
            return;

        if (usingBFB)
        {
            SetPropFloat(player, "m_Shared.m_flHypeMeter", clampFloor(GetPropFloat(player, "m_Shared.m_flHypeMeter") - 20, 0));
            player.AddCustomAttribute("move speed bonus", 1.001, 0.1);
        }

        if (quickFixLink || !ShouldPlayVoiceLine())
            return;

        local inverseChance = climbLineTimesPlayed[0]++ < 3 ? 3 : 5;
        if (player.GetPlayerClass() == TF_CLASS_SCOUT)
        {
            inverseChance *= 2;
        }
        if (RandomInt(0, inverseChance) == 0)
        {
            lastTimePlayedLine[player] <- Time();
            EmitPlayerVODelayed(player, "wall_climb", 0.2);
        }
    }

    function ShouldPlayVoiceLine()
    {
        if (lastTimePlayedLine.len() > 200) //Easy anti-memory leak fix
            lastTimePlayedLine = {};
        local time = Time();
        local playSlotsOccupied = 0;
        foreach (otherPlayer, lastPlayTime in lastTimePlayedLine)
            if (time - lastPlayTime < sharedPlayInterval
                && (++playSlotsOccupied >= sharedPlayPool || player == otherPlayer))
                    return false;
        return true;
    }

    function OnDiscard()
    {
        RemoveListener(wallClimbListener);
    }
});