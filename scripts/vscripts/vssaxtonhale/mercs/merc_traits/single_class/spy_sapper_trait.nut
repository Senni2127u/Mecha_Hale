//Spy side Sapper script.
// Credit - Senni
// Purpose: Handles Spy's side of the Sapper functionality.

const SAPPER_CHARGE_TIME    = 15.0;   // cooldown timer, in seconds. (default: 15.0)
const SAPPER_RANGE          = 220.0; // hammer units required to place the sapper. (default: 220)
const SAPPER_BLUEPRINT_RANGE = 235.0; // hammer units required to get the blueprint, typically meant to be higher so the player knows beforehand. (default: 235)
const SAPPER_FACING_DOT     = 0.85;  // the cosine cone required for Spy to be able to place the sapper. (default: 0.85)

local function KillIfValid(ent)
{
    if (ent != null && ent.IsValid())
        ent.Kill();
    return null;
}

characterTraitsClasses.push(class extends CharacterTrait
{
    sapper_text = null;
    sapperCharge = 100.0;
    sapperEnt = null;
    inAttack = 0;

    function CanApply()
    {
        return player.GetPlayerClass() == TF_CLASS_SPY; //We only want Spy, this replaces the previous spy_sappercall.nut script from the old version of the mode.
    }

    function OnApply()
    {
        sapperCharge = 100.0;
        sapperEnt = null;
        inAttack = 0;


        sapper_text = SpawnEntityFromTable("game_text", { //Change this for text colors and whatnot, Mercs are RED in the default, so it's red.
            channel  = 1
            x        = "0.781"
            y        = "0.788"
            color    = "255 80 80"
            color2   = "255 80 80"
            effect   = 0
            fadein   = 0
            fadeout  = 0
            holdtime = 0.2
        });
    }

    function OnDiscard()
    {
        sapper_text = KillIfValid(sapper_text); //Removing old text from previous rounds.
    }

    function OnTickAlive(timeDelta)
    {
        if (GetPropInt(player, "m_nButtons") & IN_ATTACK)
            inAttack = Time();

        if (sapper_text != null && sapper_text.IsValid())
        {
            SetPropString(sapper_text, "m_iszMessage", format("Sapper: %d%%", sapperCharge.tointeger())); //Actual text for Sapper percentage.
            EntFireByHandle(sapper_text, "Display", "", -1, player, player);
        }

        sapperCharge = clampCeiling(100.0, sapperCharge + timeDelta * (100.0 / SAPPER_CHARGE_TIME));

        if (sapperCharge >= 100.0 && sapperEnt != null)
        {
            for (local i = 0; i < 7; i++)
                if (!GetPropEntityArray(player, "m_hMyWeapons", i))
                {
                    SetPropEntityArray(player, "m_hMyWeapons", sapperEnt, i);
                    sapperEnt = null;
                    break;
                }
        }

        local sapper = player.GetActiveWeapon();

        if (!sapper || sapper.GetSlot() != 1) //Check the slot anyway to be sure it's valid, Spy always has a Sapper.
            return;

        local bossList = GetBossPlayers();
        if (!bossList.len())
            return;
        local boss = bossList[0];
        if (!IsValidPlayer(boss) || !IsPlayerAlive(boss))
            return;

        local scope = boss.GetScriptScope();
        if (!("TryApplySapper" in scope))
            return;

        local myEyes = player.EyePosition();
        local deltaVector = boss.EyePosition() - myEyes;
        local dist = deltaVector.Norm();


        if (!scope.hasSapper)
            scope.SendBlueprintRequest(player, (dist < SAPPER_BLUEPRINT_RANGE) ? sapper : null); //Checking distance Spy is from Hale, and if to display the blueprint.

        if (sapperCharge < 100.0) //Don't allow Spy to continue if below 100% charge.
            return;

        local forward = player.EyeAngles().Forward();
        local facingDot = forward.Dot(deltaVector);

        if (dist > 0 && dist < SAPPER_RANGE && facingDot > SAPPER_FACING_DOT) //Check both the range and where Spy is facing, we don't want Spy applying a Sapper from behind.
        {
            if (Time() - inAttack <= 0.1) //If trying to attack with Sapper, attempt an apply to the boss.
            {
                if (scope.TryApplySapper(player, sapper))
                {
                    local switchTo = null;
                    for (local i = 0; i < 7; i++)
                    {
                        local weapon = GetPropEntityArray(player, "m_hMyWeapons", i);
                        if (!weapon)
                            continue;
                        local slot = weapon.GetSlot();
                        if (slot == 1)
                        {
                            sapperEnt = weapon;
                            SetPropEntityArray(player, "m_hMyWeapons", null, i);
                        }
                        if (slot == 2 || (slot == 0 && switchTo == null))
                            switchTo = weapon;
                    }
                    player.Weapon_Switch(switchTo);
                    sapperCharge = 0.0; //Reset back to 0% after usage.
                }
            }
        }
    }
});

AddListener("spawn", -1, function (player, params)
{
    if (!IsBoss(player))
        return;
    player.ValidateScriptScope();
    local oldScope = player.GetScriptScope();

//This is to clean up sounds playing after a new round occurs.

    if ("hasSapper" in oldScope && oldScope.hasSapper)
    {
        if ("sapper_wearable" in oldScope && oldScope.sapper_wearable != null && oldScope.sapper_wearable.IsValid())
        {
            oldScope.sapper_wearable.StopSound("Weapon_Sapper.Timer");
            oldScope.sapper_wearable.Kill();
        }
        if ("sapper_particle" in oldScope && oldScope.sapper_particle != null && oldScope.sapper_particle.IsValid())
            oldScope.sapper_particle.Kill();
    }

    DoIncludeScript("vssaxtonhale/bosses/generic/misc/sapper_attachment", oldScope); //No, we do not include this anywhere else but here, because the boss script needs to be executed right after this one is done.
});


AddListener("death", -1, function (player, attacker, params) //if Mecha Hale died while being sapped, the Sapper would stay, this removes it on death.
{
    local scope = player.GetScriptScope();

    if (!("hasSapper" in scope) || !scope.hasSapper)
        return;

    if ("sapper_wearable" in scope && scope.sapper_wearable != null && scope.sapper_wearable.IsValid())
    {
        scope.sapper_wearable.StopSound("Weapon_Sapper.Timer");
        scope.sapper_wearable.Kill();
    }
    if ("sapper_particle" in scope && scope.sapper_particle != null && scope.sapper_particle.IsValid())
        scope.sapper_particle.Kill();

    scope.hasSapper = false;
    //printl("[SapperDebug] sapper cleanup completed on death");
});
