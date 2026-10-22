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

class BuildingDamageRescaleTrait extends BossTrait
{
    function OnDamageDealt(victim, params)
    {
        if (victim == null || IsCollateralDamage(params.damage_type) || !startswith(victim.GetClassname(), "obj_"))
            return;

        local level = GetPropInt(victim, "m_iUpgradeLevel");
        if (GetPropInt(victim, "m_nShieldLevel") > 0)
        {
            if (level == 2)
                params.damage = 260;
            else if (level == 3)
                params.damage = 310;
        }
        else
        {
            if (level >= 2)
                params.damage = 160;
        }
    }
};