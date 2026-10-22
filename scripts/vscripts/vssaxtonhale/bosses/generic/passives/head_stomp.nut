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

class HeadStompTrait extends BossTrait
{
    downVel = 0;

    function OnFrameTickAlive()
    {
        if (!boss.IsOnGround())
            downVel = -boss.GetAbsVelocity().z;
        else
        {
            if (downVel >= 500 && boss.GetWaterLevel() < 2)
            {
                local victim = GetPropEntity(boss, "m_hGroundEntity");
                if (!IsValidPlayer(victim))
                    return;

                custom_dmg_stomp.SetAbsOrigin(boss.GetOrigin());
                victim.TakeDamageEx(
                    custom_dmg_stomp,
                    boss,
                    boss.GetActiveWeapon(),
                    Vector(0,0,0),
                    boss.GetOrigin(),
                    clamp(downVel, 500, 1500) / 7.77,
                    1);

                EmitAmbientSoundOn("Weapon_Mantreads.Impact", 8, 1, 100, victim);
                EmitAmbientSoundOn("Player.FallDamageDealt", 4, 1, 100, victim);
                DispatchParticleEffect("stomp_text", boss.GetOrigin(), Vector(0,0,0));
            }
            downVel = 0;
        }
    }
};