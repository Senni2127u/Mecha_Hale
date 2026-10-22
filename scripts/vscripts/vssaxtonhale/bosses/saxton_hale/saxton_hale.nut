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

PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_01.wav");
PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_02.wav");
PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_03.wav");
PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_04.wav");

::custom_dmg_melee <- SpawnEntityFromTable("info_target", { classname = "hale_punch" });
::custom_dmg_melee_collateral <- SpawnEntityFromTable("info_target", { classname = "hale_punch_collateral" });
::custom_dmg_stomp <- SpawnEntityFromTable("info_target", { classname = "hale_stomp" });
::custom_dmg_hale_taunt <- SpawnEntityFromTable("info_target", { classname = "hale_taunt" });
::custom_dmg_slam <- SpawnEntityFromTable("info_target", { classname = "hale_slam" });
::custom_dmg_slam_collateral <- SpawnEntityFromTable("info_target", { classname = "hale_slam_collateral" });
::custom_dmg_saxton_punch <- SpawnEntityFromTable("info_target", { classname = "hale_megapunch" });
::custom_dmg_saxton_punch_aoe <- SpawnEntityFromTable("info_target", { classname = "hale_megapunch_collateral" });
::custom_dmg_charge <- SpawnEntityFromTable("info_target", { classname = "hale_charge" });

::engineLoopSound <- "mecha_hale_loop.wav";
::saxton_model_path <- "models/vsh/player/mecha_hale.mdl";
::saxton_aura_model_path <- "models/vsh/player/items/vsh_effect_body_aura.mdl"
::saxton_viewmodel_path <- "models/vsh/weapons/c_models/c_mecha_hale_arms.mdl"
::saxton_viewmodel_index <- GetModelIndex("models/vsh/weapons/c_models/c_mecha_hale_arms.mdl")

PrecacheModel(saxton_model_path);
PrecacheModel(saxton_aura_model_path);
PrecacheModel(saxton_viewmodel_path);

class SaxtonHale extends Boss
{
    name = "saxton_hale";

    function OnApply0Delay()
    {
        player.SetPlayerClass(TF_CLASS_HEAVY);
        player.Regenerate(true);
        SetPropInt(player, "m_bForcedSkin", 1);
        SetPropInt(player, "m_nForcedSkin", 0);

        base.OnApply0Delay();

        player.SetCustomModelWithClassAnimations(saxton_model_path);
        vsh_vscript.Hale_SetRedArm(player, false);
        vsh_vscript.Hale_SetBlueArm(player, false);
        RunWithDelay2(this, 0.1, function() {
            vsh_vscript.Hale_SetRedArm(player, false);
            vsh_vscript.Hale_SetBlueArm(player, false);
            local wearable = FindByName(null, "wearable_vs_hale_aura_body");
            if (wearable != null)
                wearable.Kill();
            wearable = player.CreateCustomWearable(null, saxton_aura_model_path);
            wearable.KeyValueFromString("targetname", "wearable_vs_hale_aura_body");

            player.GiveWeapon("Hale's Own Fists");
        });

        player.SetModelScale(API_GetFloat("boss_scale"), 0);
        player.GiveWeapon("Hale's Own Fists");

        player.AddCustomAttribute("move speed bonus", 1.8, -1);
        player.AddCustomAttribute("cancel falling damage", 1, -1);
        player.AddCustomAttribute("voice pitch scale", 0, -1);
        player.AddCustomAttribute("melee range multiplier", 1.2, -1);
        player.AddCustomAttribute("damage bonus", 3, -1);
        player.AddCustomAttribute("melee bounds multiplier", 1.1, -1);
        player.AddCustomAttribute("crit mod disabled hidden", 0, -1);
        player.AddCustomAttribute("increase player capture value", 2, -1);
        player.AddCustomAttribute("cannot pick up intelligence", 1, -1);
        player.AddCustomAttribute("patient overheal penalty", 1, -1);
        player.AddCustomAttribute("health from packs decreased", 0, -1);
        player.AddCustomAttribute("damage force reduction", 0.75, -1);
        player.AddCustomAttribute("dmg taken from crit reduced", 0.75, -1);
        player.AddCustomAttribute("dmg taken from blast increased", 1.5, -1);
        player.AddCustomAttribute("dmg taken from fire increased", 1.25, -1);

        player.AddCond(TF_COND_CANNOT_SWITCH_FROM_MELEE);
    }
}
RegisterBoss("saxton_hale", SaxtonHale);

Include("/bosses/saxton_hale/abilities/sweeping_charge.nut");
Include("/bosses/saxton_hale/abilities/mighty_slam.nut");
Include("/bosses/saxton_hale/abilities/eye_lasers.nut"); //Replaces Crit Punch.
Include("/bosses/saxton_hale/misc/colored_arms.nut");
Include("/bosses/saxton_hale/misc/visible_weapon_fix.nut");
Include("/bosses/saxton_hale/misc/mecha_hale_loop_sound.nut");
Include("/bosses/saxton_hale/misc/ability_particles.nut");

AddBossTrait("saxton_hale", AbilityHudTrait);
AddBossTrait("saxton_hale", SweepingChargeTrait);
AddBossTrait("saxton_hale", EyeLasersTrait); //Replaces Crit Punch.
AddBossTrait("saxton_hale", MightySlamTrait);

AddBossTrait("saxton_hale", BraveJumpTrait);
AddBossTrait("saxton_hale", DeathCleanupTrait);
AddBossTrait("saxton_hale", MechaHaleLoopSoundTrait); //Handles engine sound while alive.
AddBossTrait("saxton_hale", MechaHaleGibsTrait); //Handles explosion/gibs on death for Mecha Hale.
AddBossTrait("saxton_hale", MovespeedTrait);
AddBossTrait("saxton_hale", ScreenShakeTrait);
AddBossTrait("saxton_hale", SetupStatRefreshTrait);
AddBossTrait("saxton_hale", TauntHandlerTrait);
AddBossTrait("saxton_hale", AoEPunchTrait);
AddBossTrait("saxton_hale", DebuffResistanceTrait);
AddBossTrait("saxton_hale", HeadStompTrait);
AddBossTrait("saxton_hale", ReceivedDamageScalingTrait);
AddBossTrait("saxton_hale", StunBreakoutTrait);
AddBossTrait("saxton_hale", BuildingDamageRescaleTrait);
AddBossTrait("saxton_hale", SpawnProtectionTrait);
//AddBossTrait("saxton_hale", NoGibFixTrait); //do not re-enable, we don't want this as it prevents gibbing.

AddBossTrait("saxton_hale", JaratedVoiceLine);
AddBossTrait("saxton_hale", LastMannHidingVoiceLine);
AddBossTrait("saxton_hale", KillVoiceLine);

RegisterCustomWeapon(
    "Hale's Own Fists",
    "Fists",
    null,
    Defaults,
    function (table, player) {
        table.worldModel = "models/empty.mdl";
        table.viewModel = saxton_viewmodel_path;
        table.classArms = saxton_viewmodel_path;
    },
    function (weapon, player)
    {
        if (player.ValidateScriptScope())
            player.GetScriptScope()["hide_base_arms"] <- true;

        weapon.AddAttribute("kill eater", casti2f(8473), -1) //Instead of over 9000 joke, 8473 is the unit number said by Gray.
        local isModelFlipped = false;
        try { isModelFlipped = Convars.GetClientConvarValue("cl_flipviewmodels", player.entindex()).tointeger() > 0; }
        catch(ignored) { }
        SetPropInt(weapon, "m_bFlipViewModel", isModelFlipped ? 1 : 0);
    }
)