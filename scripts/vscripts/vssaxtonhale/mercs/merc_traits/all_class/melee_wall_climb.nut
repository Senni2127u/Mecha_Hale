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

hitStreak <- {};
ignoreWallClimb <- [
    "player",
    "tf_bot",
    "obj_",
    "tf_projectile",
    "func_button"
]

function MeleeWallClimb_Hit(params)
{
    if (IsMercValidAndAlive(params.attacker))
        MeleeClimb_Perform(params.attacker);
}

function MeleeWallClimb_Check(params)
{
    local classname = params.const_entity.GetClassname();
    foreach (entry in ignoreWallClimb)
        if (classname.find(entry) == 0)
            return false;
    return true;
}

AddListener("tick_always", 0, function (timeDelta)
{
    foreach (player in GetAliveMercs())
        if ((player.GetFlags() & FL_ONGROUND))
            hitStreak[player] <- 0;
});

function MeleeClimb_Perform(player, quickFixLink = false)
{
    local hits = (player in hitStreak ? hitStreak[player] : 0) + 1;
    local launchVelocity = hits == 1 ? 600 : hits == 2 ? 450 : hits <= 4 ? 400 : 200;
    hitStreak[player] <- hits;

    SetPropEntity(player, "m_hGroundEntity", null);
    player.RemoveFlag(FL_ONGROUND);

    local newVelocity = player.GetAbsVelocity();
    newVelocity.z = launchVelocity > 430 ? launchVelocity : launchVelocity + newVelocity.z;
    player.SetAbsVelocity(newVelocity);
    FireListeners("wall_climb", player, hits, quickFixLink);

    if (!quickFixLink)
        foreach (otherPlayer in GetAliveMercs())
        {
            if (otherPlayer.GetPlayerClass() != TF_CLASS_MEDIC)
                continue;
            local medigun = otherPlayer.GetWeaponBySlot(TF_WEAPONSLOTS.SECONDARY);
            if (!WeaponIs(medigun,"quick_fix"))
                continue;
            local target = GetPropEntity(medigun, "m_hHealingTarget");
            if (target == player)
                MeleeClimb_Perform(otherPlayer, true);
        }
}