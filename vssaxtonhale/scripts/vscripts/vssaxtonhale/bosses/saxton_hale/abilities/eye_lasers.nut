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

PrecacheArbitrarySound("saxton_hale.laser_ready");
PrecacheArbitrarySound("saxton_hale.laser_fire");
PrecacheArbitrarySound("saxton_hale.laser_firing");
PrecacheArbitrarySound("saxton_hale.laser_kill");
PrecacheArbitrarySound("saxton_hale.laser_use");
PrecacheSound(")weapons/vaccinator_charge_tier_01.wav");
PrecacheArbitrarySound("MVM.Warning");
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "vsh_tesla_shield" });
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "vsh_laser_tp" });
PrecacheModel("models/vsh/player/items/vsh_laser_effect.mdl");

::custom_dmg_eye_lasers <- SpawnEntityFromTable("info_target", { classname = "hale_eye_lasers" });
::custom_dmg_eye_lasers_collateral <- SpawnEntityFromTable("info_target", { classname = "hale_eye_lasers_collateral" });

// Tracks, per-boss, whether the laser is currently active/firing so the
// BossPlayViewModelAnim wrapper below can suppress other anim calls while
// the real arms viewmodel is hidden in favor of the wearable laser effect.
// (This replaces the old global PlayViewModelAnim override from mecha_hale_misc.nut.)
::eyeLasersActive <- {};

::BossPlayViewModelAnimBase <- BossPlayViewModelAnim;
function BossPlayViewModelAnim(boss, animation)
{
    if (!(boss in eyeLasersActive) || !eyeLasersActive[boss])
        BossPlayViewModelAnimBase(boss, animation);
}

class EyeLasersTrait extends BossTrait
{
    meter = -30;
    duration = 5;
    isActive = false;
    isFiring = false;
    everFired = false;
    beamUpdateAccumulator = 0;
    lastKillVOTime = -999;
    laser_target = null;
    laser_target_camera = null;
    laser_target_helper = null;
    soundQueue = null;
    voChannelFreeAt = 0;
    lastFireTime = -999;
    recentlyLasered = null;
    laserUseNagPlayed = false;
    laserUseIdleThreshold = 15; // seconds without using the laser before the nag VO plays
    readySinceTime = -999;

    function OnApply()
    {
        if (!(player in hudAbilityInstances))
            hudAbilityInstances[player] <- [];
        hudAbilityInstances[player].push(this);

        eyeLasersActive[boss] <- false;
        soundQueue = [];
        recentlyLasered = {};
        lastFireTime = Time();
        laserUseNagPlayed = false;

        local entsToKill = [];
        for (local ent; ent = Entities.FindByName(ent, "laser_target*");)
            entsToKill.push(ent);
        foreach (ent in entsToKill)
            ent.Kill();

        laser_target = SpawnEntityFromTable("prop_dynamic",
        {
            targetname = "laser_target",
            model = "models/empty.mdl"
        });

        laser_target_camera = SpawnEntityFromTable("prop_dynamic",
        {
            targetname = "laser_target_camera",
            model = "models/empty.mdl"
        });
        EntFireByHandle(laser_target_camera, "SetParent", "!activator", 0, boss, boss);

        laser_target_helper = SpawnEntityFromTable("prop_dynamic",
        {
            targetname = "laser_target_helper",
            model = "models/empty.mdl"
        });
    }

    // EmitSoundOn/EmitEntityVO calls on the same entity in the same tick silently
    // drop the earlier call in favor of the latest one. QueueSound staggers a
    // sound to play a short moment later instead of colliding with one already
    // firing this tick.
    function QueueSound(delay, fn)
    {
        soundQueue.push({ time = Time() + delay, fn = fn });
    }

    function ProcessSoundQueue()
    {
        if (soundQueue.len() == 0)
            return;

        local now = Time();
        local remaining = [];
        foreach (item in soundQueue)
        {
            if (now >= item.time)
            {
                local fn = item.fn;
                fn();
            }
            else
                remaining.push(item);
        }
        soundQueue = remaining;
    }

    // The boss can only have one VO line active at a time — starting a new one
    // early cuts off whatever's still playing, regardless of whether it's
    // EmitEntityVO or PlayAnnouncerVO under the hood. PlayVO keeps a running
    // "channel free at" timestamp (measured from real line lengths via
    // GetSoundDuration) so every laser VO call — ready/fire/firing/use/kill —
    // automatically queues up after whatever's already playing instead of
    // stomping it.
    //
    // laser_fire's wave (charge.mp3) doesn't follow the same path convention
    // as the other lines, so GetSoundDuration may not resolve it reliably —
    // a minimum floor guards against a too-short (or zero) reading letting
    // the next line cut it off early.
    function PlayVO(soundName, fn)
    {
        local now = Time();
        local playAt = (voChannelFreeAt > now) ? voChannelFreeAt : now;

        local vodur = GetSoundDuration(soundName, "");
        if (vodur < 0.75)
            vodur = 1.5; // fallback/floor if the duration can't be looked up reliably

        voChannelFreeAt = playAt + vodur;

        if (playAt <= now)
            fn();
        else
            QueueSound(playAt - now, fn);
    }

    function OnDamageTaken(attacker, params)
    {
        if (meter > 0.1 && !("piercing" in params))
            params.damage *= 0.5;
    }

    function OnDamageDealt(victim, params)
    {
        if (params.inflictor == custom_dmg_eye_lasers || params.inflictor == custom_dmg_eye_lasers_collateral)
        {
            if ("customkill" in params)
                params.customkill = TF_DMG_CUSTOM_PLASMA;
            else
                params.customkill <- TF_DMG_CUSTOM_PLASMA;
        }
    }

    function OnKill(victim, params)
    {
        if (!victim.IsPlayer())
            return;

        local taggedByParams = ("customkill" in params) && params.customkill == TF_DMG_CUSTOM_PLASMA;
        local taggedByTracking = (victim in recentlyLasered) && (Time() - recentlyLasered[victim] < 2.5);

        if (!taggedByParams && !taggedByTracking)
            return;

        if (victim in recentlyLasered)
            delete recentlyLasered[victim];

        if (Time() - lastKillVOTime < 15)
            return;
        lastKillVOTime = Time();
        PlayVO("saxton_hale.laser_kill", function()
        {
            PlayAnnouncerVO(boss, "laser_kill");
        });
    }

    function OnTickAlive(timeDelta)
    {
        ProcessSoundQueue();

        if (IsRoundSetup())
            return;

        if (!isActive && !laserUseNagPlayed && meter >= 0 && (Time() - readySinceTime) >= laserUseIdleThreshold)
        {
            laserUseNagPlayed = true;
            PlayVO("saxton_hale.laser_use", function()
            {
                PlayAnnouncerVO(boss, "laser_use");
            });
        }

        if (isActive)
        {
            TickActiveLaser(timeDelta);
            return;
        }

        if (meter < 0)
        {
            meter += timeDelta;
            if (meter > 0)
            {
                readySinceTime = Time();

                EmitSoundOn(")weapons/vaccinator_charge_tier_01.wav", boss);
                QueueSound(0.15, function()
                {
                    EmitSoundOn("MVM.Warning", boss);
                });
                if (!everFired || !RandomInt(0, 2))
                {
                    PlayVO("saxton_hale.laser_ready", function()
                    {
                        PlayAnnouncerVO(boss, "laser_ready");
                    });
                }
            }
        }
        else if (boss.IsCallingForMedic() && !boss.InCond(TF_COND_TAUNTING))
        {
            isActive = true;
            everFired = true;
            eyeLasersActive[boss] = true;
            meter = duration + 3;

            lastFireTime = Time();
            laserUseNagPlayed = false;

            // laser_fire (charge.mp3) is a long charging ambience that runs
            // through the whole ability, not a short VO line — it's meant to
            // be cut off once laser_firing starts, not finish first. So it
            // plays immediately and doesn't occupy the shared VO channel.
            EmitEntityVO(boss, "saxton_hale", "laser_fire");

            PlayVO("saxton_hale.laser_firing", function()
            {
                PlayAnnouncerVO(boss, "laser_firing");
            });

            BossPlayViewModelAnimBase(boss, "vsh_laser_prepare");
            local main_viewmodel = GetPropEntity(boss, "m_hViewModel");
            main_viewmodel.SetPlaybackRate(1);
        }
    }

    // DMG_PREVENT_PHYSICS_FORCE only cancels the knockback push, not the engine's
    // view punch (screen shake) applied on every TakeDamageEx call. The punch is
    // driven by both m_vecPunchAngle and its velocity m_vecPunchAngleVel — angle
    // decays over time using the velocity, so resetting only the angle still lets
    // leftover velocity re-animate the shake on later frames. With damage ticking
    // every 0.06s this stacks into a violent shake, so both must be saved and
    // restored around each hit, same as velocity is saved/restored above.
    function SavePunch(target)
    {
        if (!target.IsPlayer())
            return null;
        return {
            angle = NetProps.GetPropVector(target, "m_Local.m_vecPunchAngle"),
            vel = NetProps.GetPropVector(target, "m_Local.m_vecPunchAngleVel")
        };
    }

    function RestorePunch(target, saved)
    {
        if (saved == null)
            return;
        NetProps.SetPropVector(target, "m_Local.m_vecPunchAngle", saved.angle);
        NetProps.SetPropVector(target, "m_Local.m_vecPunchAngleVel", saved.vel);
    }

    function TickActiveLaser(timeDelta)
    {
        meter -= timeDelta;

        if (meter < 0)
        {
            if (isFiring)
            {
                GetPropEntity(boss, "m_hViewModel").EnableDraw();
                BossPlayViewModelAnimBase(boss, "vsh_show_arms");
            }
            isFiring = false;
            isActive = false;
            eyeLasersActive[boss] = false;
            meter = -30;
            beamUpdateAccumulator = 0;

            return;
        }

        if (!isFiring && meter < duration)
            Perform();
        if (!isFiring)
            return;

        beamUpdateAccumulator += timeDelta;
        if (beamUpdateAccumulator < 0.06)
            return;
        beamUpdateAccumulator = 0;

        local forward = boss.EyeAngles().Forward();
        local eyePos = boss.EyePosition();

        //Aim assist
        local aimAssistTarget = null;

        foreach (target in GetValidPlayers())
        {
            if (target == boss || IsBoss(target) || !IsPlayerAlive(target))
                continue;
            local deltaVector = target.GetCenter() - eyePos;
            local distance = deltaVector.Norm();
            if (distance > 1800)
                continue;
            local dot = forward.Dot(deltaVector);
            if (dot > (distance < 400 ? 0.98 : distance < 1000 ? 0.992 : distance < 1400 ? 0.997 : 0.999))
            {
                local fraction = TraceLine(eyePos, target.GetCenter(), null);
                if (fraction > 0.99)
                {
                    aimAssistTarget = target;
                    break;
                }
            }
        }

        local trace = {
            start = eyePos,
            end = aimAssistTarget ? aimAssistTarget.GetCenter() : eyePos + forward * 1800,
            mask = Constants.FContents.CONTENTS_SOLID|Constants.FContents.CONTENTS_MOVEABLE|Constants.FContents.CONTENTS_PLAYERCLIP|Constants.FContents.CONTENTS_WINDOW|Constants.FContents.CONTENTS_GRATE|Constants.FContents.CONTENTS_MONSTER,
            ignore = boss
        };
        TraceLineEx(trace);

        // Velly: Normalized subtraction between end and startpos is used by laser_target_helper. Tells the direction at where the laser is aiming in worldspace and applies offset to laser's tip points based from that.
        local vecHelper = trace.endpos - trace.startpos;
        vecHelper.Norm();

        // Velly: "You can subtract a normalized vector between endpos and startpos. It's guaranteed to not be inside anything." I guess this was done correctly, and by "between" you meant subtraction.
        local endpos = trace.endpos - vecHelper;

        local frame = NetProps.GetPropInt(laser_target, "m_ubInterpolationFrame");
        laser_target.SetAbsOrigin(endpos);
        NetProps.SetPropInt(laser_target, "m_ubInterpolationFrame", frame);

        // Velly: Switch z between 0 and 1 to toggle visibility of the laser's impact effects. This needs a more thoughtfull check of if laser hits a player/skybox.
        //local myTarget = "enthit" in trace ? trace.enthit : null
        vecHelper.z = (trace.fraction == 1.0) ? 1 : 0;

        // Velly: Wait, can this use laser_target's frame from above instead? I forgot to test before shipping this...
        frame = NetProps.GetPropInt(laser_target_helper, "m_ubInterpolationFrame");
        laser_target_helper.SetAbsOrigin(vecHelper);
        NetProps.SetPropInt(laser_target_helper, "m_ubInterpolationFrame", frame);

        custom_dmg_eye_lasers_collateral.SetAbsOrigin(boss.GetOrigin());
        CreateAoE(boss.GetCenter(), 150,
            function (target, deltaVector, distance)
            {
                if (target == boss)
                    return;

                local preVel = target.GetVelocity();
                local prePunch = SavePunch(target);
                target.TakeDamageEx(
                    custom_dmg_eye_lasers_collateral,
                    boss,
                    boss.GetActiveWeapon(),
                    Vector(0, 0, 0),
                    boss.GetOrigin(),
                    target.GetMaxHealth() * 0.015,
                    DMG_BURN | DMG_PREVENT_PHYSICS_FORCE);
                target.SetVelocity(preVel);
                RestorePunch(target, prePunch);

                if (target.IsPlayer())
                    recentlyLasered[target] <- Time();
            },
            function (target, deltaVector, distance) { });

        custom_dmg_eye_lasers.SetAbsOrigin(boss.GetOrigin());
        CreateAoE(endpos, 100,
            function (target, deltaVector, distance)
            {
                if (target == boss)
                    return;

                local damage = clampFloor(2, target.GetMaxHealth() * 0.06 * (1 - distance / 4200.0));
                if (!target.IsPlayer())
                    damage *= 5;

                local preVel = target.GetVelocity();
                local prePunch = SavePunch(target);
                target.TakeDamageEx(
                    custom_dmg_eye_lasers,
                    boss,
                    boss.GetActiveWeapon(),
                    Vector(0, 0, 0),
                    boss.GetOrigin(),
                    damage,
                    DMG_BURN | DMG_PREVENT_PHYSICS_FORCE);
                target.SetVelocity(preVel);
                RestorePunch(target, prePunch);

                if (target.IsPlayer())
                    recentlyLasered[target] <- Time();
            },
            function (target, deltaVector, distance) { });
    }

    function Perform()
    {
        isFiring = true;

        local particle = SpawnEntityFromTable("info_particle_system", {
            effect_name = "vsh_tesla_shield",
            start_active = 1
        });
        EntFireByHandle(particle, "SetParent", "!activator", 0, boss, boss);
        EntFireByHandle(particle, "SetParentAttachment", "vsh_tesla_shield", 0, null, null);
        EntFireByHandle(particle, "Kill", "", duration, null, null);

        particle = SpawnEntityFromTable("info_particle_system", {
            effect_name = "vsh_laser_tp",
            cpoint1 = "laser_target",
            cpoint2 = "laser_target_camera",
            cpoint3 = "laser_target_helper",
            start_active = 1
        });
        EntFireByHandle(particle, "SetParent", "!activator", 0, boss, boss);
        EntFireByHandle(particle, "SetParentAttachment", "eyes", 0, null, null);
        EntFireByHandle(particle, "Kill", "", duration, null, null);

        local viewmodel = GetPropEntity(boss, "m_hViewModel");
        local vmOrigin = viewmodel.GetOrigin();
        local vmAngles = viewmodel.GetAbsAngles();

        local wearable = SpawnEntityFromTable("tf_wearable_vm", {
            modelindex = PrecacheModel("models/vsh/player/items/vsh_laser_effect.mdl")
        });
        boss.EquipWearableViewModel(wearable);
        // LookupSequence returns -1 if "reference" isn't a real sequence on this
        // model; passing that straight to ResetSequence wraps to 255 and spams
        // "Playing sequence 255 but there's only N in total". Only reset if the
        // sequence actually exists, otherwise leave the model on its default pose.
        local refSeq = wearable.LookupSequence("reference");
        if (refSeq >= 0)
            wearable.ResetSequence(refSeq);
        EntFireByHandle(wearable, "Kill", "", duration, null, null);

        // Same 255-wraparound risk as the wearable above: BossPlayViewModelAnimBase
        // does its own LookupSequence internally and we can't guard inside it (it's
        // the native/base-game function), so check here first. The viewmodel is
        // about to be hidden by DisableDraw() below anyway, so skipping the reset
        // when the sequence doesn't exist on this model is harmless — it gets
        // replaced by "vsh_show_arms" when the arms are shown again later.
        if (GetPropEntity(boss, "m_hViewModel").LookupSequence("c_heavy_idle") >= 0)
            BossPlayViewModelAnimBase(boss, "c_heavy_idle");
        GetPropEntity(boss, "m_hViewModel").DisableDraw();
    }

    function MeterAsPercentage()
    {
        if (meter < 0)
            return (30 + meter) * 90 / 30;
        return 200;
    }

    function MeterAsNumber()
    {
        local mapped = -meter + 0.99;
        if (mapped <= 1)
            return "r";
        if (mapped < 10)
            return format(" %d", mapped);
        else
            return format("%d", mapped);
    }
};