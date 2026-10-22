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

// Per-class pain sounds for Eye Laser hits (game sound script names)
const EYE_LASER_PAIN_COOLDOWN = 0.5;

::EyeLaserPainSounds <- {
    [Constants.ETFClass.TF_CLASS_SCOUT]        = { prefix = "Scout",    count = 8 },
    [Constants.ETFClass.TF_CLASS_SOLDIER]      = { prefix = "Soldier",  count = 8 },
    [Constants.ETFClass.TF_CLASS_PYRO]         = { prefix = "Pyro",     count = 7 },
    [Constants.ETFClass.TF_CLASS_DEMOMAN]      = { prefix = "Demoman",  count = 7 },
    [Constants.ETFClass.TF_CLASS_HEAVYWEAPONS] = { prefix = "Heavy",    count = 5 },
    [Constants.ETFClass.TF_CLASS_ENGINEER]     = { prefix = "Engineer", count = 8 },
    [Constants.ETFClass.TF_CLASS_MEDIC]        = { prefix = "Medic",    count = 8 },
    [Constants.ETFClass.TF_CLASS_SNIPER]       = { prefix = "Sniper",   count = 4 },
    [Constants.ETFClass.TF_CLASS_SPY]          = { prefix = "Spy",      count = 4 },
}

::EyeLaserPainSound <- function(cls)
{
    local entry = ::EyeLaserPainSounds[cls]
    return entry.prefix + ".PainSharp0" + RandomInt(1, entry.count)
}

foreach (entry in ::EyeLaserPainSounds)
    for (local i = 1; i <= entry.count; i++)
        PrecacheScriptSound(entry.prefix + ".PainSharp0" + i)

class ScreenShakeTrait extends BossTrait
{
    function OnTickAlive(timeDelta)
    {
        if (boss.GetAbsVelocity().Length() < 200)
            return;
        local bossOrigin = boss.GetOrigin();
        foreach(target in GetAliveMercs())
        {
            if (target == boss)
                continue;
            local targetOrigin = target.GetOrigin();
            local distance = (bossOrigin - targetOrigin).Length();
            if (distance > 1600)
                continue;
            local shakeFactorAmp = clamp((1600 - distance) / 100, 3, 10) / 2;
            local shakeFactorDur = clamp((1600 - distance) / 1000, 0.1, 1);
            ScreenShake(targetOrigin, shakeFactorAmp, 16, shakeFactorDur, 50, 0, true);
        }
    }

    function OnDamageDealt(victim, params)
    {
        if (victim == null || !victim.IsValid())
            return;

        if ("inflictor" in params && (params.inflictor == custom_dmg_eye_lasers || params.inflictor == custom_dmg_eye_lasers_collateral))
        {
            if (victim.IsPlayer())
            {
                if (victim.InCond(TF_COND_INVULNERABLE))
                    {
                        return;
                    }
                        {
                            victim.ValidateScriptScope()
                            local scope = victim.GetScriptScope()
                            local now = Time()

                            if (!("last_laser_pain" in scope))
                            scope.last_laser_pain <- 0.0

                            if (now - scope.last_laser_pain >= EYE_LASER_PAIN_COOLDOWN)
                            {
                                local cls = victim.GetPlayerClass()
                                if (cls in ::EyeLaserPainSounds)        // <- this line
                                    {
                                        scope.last_laser_pain = now
                                        EmitSoundEx({
                                        sound_name = ::EyeLaserPainSound(cls),
                                        entity = victim,
                                        channel = 2,
                                        sound_level = 90
                                        })
                                    }
                            }
                        }
            }
        else
            {
                ScreenShake(victim.GetCenter(), 140, 1, 1, 10, 0, true);
            }
        }
    }
};
