//Boss side death gibbing script.
// Credit - Senni
// Purpose: Handles Mecha Hale's gibbing on death.

PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "vsh_mecha_hale_explosion" })
PrecacheScriptSound("MVM.GiantCommonExplodes");

local GIB_MODELS = [
    "models/vsh/player/gibs/mecha_hale_gib_hat.mdl",
    "models/vsh/player/gibs/mecha_hale_gib_head.mdl",
    "models/vsh/player/gibs/mecha_hale_gib_chest.mdl",
    "models/vsh/player/gibs/mecha_hale_gib_upperarm_r.mdl",
    "models/vsh/player/gibs/mecha_hale_gib_upperarm_l.mdl",
    "models/vsh/player/gibs/mecha_hale_gib_lowerarm_l.mdl",
    "models/vsh/player/gibs/mecha_hale_gib_hip_l.mdl",
    "models/vsh/player/gibs/mecha_hale_gib_hip_r.mdl",
    "models/vsh/player/gibs/mecha_hale_gib_feet_l.mdl",
    "models/vsh/player/gibs/mecha_hale_gib_feet_r.mdl",
    "models/vsh/player/gibs/mecha_hale_gib_hand_l.mdl",
];

foreach (gib in GIB_MODELS)
    PrecacheModel(gib);

local RARE_GIB_MODEL = "models/vsh/player/gibs/mecha_hale_gib_hand_l.mdl";
local RARE_GIB_OFFSET = Vector(13.89, 18.33, 52.59);

class MechaHaleGibsTrait extends BossTrait
{
    function ShootGib(origin, gib, offset, angles)
    {
        local gibSpawner = SpawnEntityFromTable("env_shooter",
        {
            spawnflags = 5,
            m_iGibs = 1,
            m_flVelocity = 400,
            scale = 1,
            m_flVariance = 1,
            m_flGibLife = 15,
            shootsounds = 3,
            simulation = 1,
            skin = 1,
            shootmodel = gib
            nogibshadows = true
            origin = origin + offset
            angles = angles
        });
        EntFireByHandle(gibSpawner, "Shoot", "", -1, null, null);
        EntFireByHandle(gibSpawner, "Kill", "", 2, null, null);
    }

    function OnDeath(attacker, params)
    {
        DispatchParticleEffect("vsh_mecha_hale_explosion", player.EyePosition(), Vector(0, 180, 0));
        player.EmitSound("MVM.GiantCommonExplodes");
        EmitSoundEx({
            sound_name = engineLoopSound,
            filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_TEAM,
            volume = 0,
            sound_level = 75,
            flags = SND_STOP | SND_CHANGE_VOL,
            channel = 111,
            entity = player,
            filter_param = 5 - player.GetTeam(), // reason we minus 5 against GetTeam is to deal with the fact that VSH can use either BLU or RED for Mercs.
            speaker_entity = player
        });
        local origin = player.GetOrigin();
        local angles = player.GetAbsAngles();

        // We don't have native gib data to go off of, so we just spawn them all outright.
        foreach (gib in GIB_MODELS)
            this.ShootGib(origin, gib, Vector(0, 0, 0), angles);

        if (!RandomInt(0, 9)) //Random chance for a rare gib to be made.
            this.ShootGib(origin, RARE_GIB_MODEL, RARE_GIB_OFFSET, angles);

        //The ragdoll doesn't exist at the instant this function fires, so we delay it's removal by a tad, this is janky.
        EntFireByHandle(player, "RunScriptCode", "local rd = GetPropEntity(activator, \"m_hRagdoll\"); "+ "if (rd != null) EntFireByHandle(rd, \"Kill\", \"\", 0, null, null)", 0.1, player, player);
    }
};
