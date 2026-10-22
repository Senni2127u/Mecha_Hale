//Mecha Hale Loop Sound script.
// Credit - Senni
// Purpose: Handles the looping engine sound on Mecha Hale.

PrecacheSound(engineLoopSound);

::MECHA_HALE_LOOP_SOUND_MIN_RANGE <- 100;  // in hammer units, the distance a Merc needs to be at to hear it fully.
::MECHA_HALE_LOOP_SOUND_MAX_RANGE <- 450; // in hammer units, the distance a Merc needs to be for it to be silent.
::MECHA_HALE_LOOP_SOUND_CHANNEL <- 6;
::SND_CHANGE_VOL <- 1;
::SND_STOP <- 4;

class MechaHaleLoopSoundTrait extends BossTrait
{
    loopingTargets = null; // target -> current volume

    function OnTickAlive(timeDelta)
    {
        if (loopingTargets == null)
            loopingTargets = {};

        local bossOrigin = boss.GetOrigin();
        local nearby = {};

        foreach(target in GetAliveMercs()) //We're only targeting Mercs, because hearing it as Mecha Hale all of the time is both annoying and loud.
        {
            if (target == boss)
                continue;

            local distance = (bossOrigin - target.GetOrigin()).Length(); //Grabbing distance of the Mercenary from Mecha Hale.
            if (distance > MECHA_HALE_LOOP_SOUND_MAX_RANGE)
                continue;

            local volume = ComputeVolume(distance);
            nearby[target] <- true;

            if (!(target in loopingTargets))
            {
                StartLoopFor(target, volume);
                loopingTargets[target] <- volume;
            }
            else if (fabs(loopingTargets[target] - volume) > 0.02)
            {
                UpdateLoopVolumeFor(target, volume);
                loopingTargets[target] = volume;
            }
        }

        // Both here and OnDeath stops the loop for anybody who is dead or disconnected.
        local toRemove = [];
        foreach(target, _ in loopingTargets)
        {
            if (!(target in nearby))
                toRemove.append(target);
        }
        foreach(target in toRemove)
        {
            if (target != null && target.IsValid())
                StopLoopFor(target);
            delete loopingTargets[target];
        }
    }

    function OnDeath(attacker, params)
    {
        if (loopingTargets == null)
            return;

        foreach(target, _ in loopingTargets)
        {
            if (target != null && target.IsValid())
                StopLoopFor(target);
        }
        loopingTargets = null;
    }

    function ComputeVolume(distance) //Distance's based fade of the sound.
    {
        if (distance <= MECHA_HALE_LOOP_SOUND_MIN_RANGE)
            return 1.0;
        if (distance >= MECHA_HALE_LOOP_SOUND_MAX_RANGE)
            return 0.0;
        local span = MECHA_HALE_LOOP_SOUND_MAX_RANGE - MECHA_HALE_LOOP_SOUND_MIN_RANGE;
        return 1.0 - ((distance - MECHA_HALE_LOOP_SOUND_MIN_RANGE).tofloat() / span);
    }

    function StartLoopFor(target, volume)
    {
        EmitSoundEx({
            sound_name = engineLoopSound,
            channel = MECHA_HALE_LOOP_SOUND_CHANNEL,
            entity = target,
            volume = volume,
            filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_SINGLE_PLAYER
        });
    }

    function UpdateLoopVolumeFor(target, volume)
    {
        EmitSoundEx({
            sound_name = engineLoopSound,
            channel = MECHA_HALE_LOOP_SOUND_CHANNEL,
            entity = target,
            volume = volume,
            flags = SND_CHANGE_VOL,
            filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_SINGLE_PLAYER
        });
    }

    function StopLoopFor(target) //We use Recipient_Filter_Global here because if not, if they fall out of range, the sound does not fully remove itself.
    {
        EmitSoundEx({
            sound_name = engineLoopSound,
            channel = MECHA_HALE_LOOP_SOUND_CHANNEL,
            entity = target,
            flags = SND_STOP,
            filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
        });
    }
};
