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

characterTraitsClasses.push(class extends CharacterTrait
{
    primary = null;
    function CanApply()
    {
        return player.GetPlayerClass() == TF_CLASS_HEAVY;
    }

    function OnApply()
    {
        primary = player.GetWeaponBySlot(TF_WEAPONSLOTS.PRIMARY);
    }

    function OnDamageDealt(victim, params)
    {
        if (params.weapon == primary && player.IsCritBoosted())
            params.damage *= 0.7;
    }
});