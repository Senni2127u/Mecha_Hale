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

game_text_damage <- null;
bossBarTicker <- 0;

function SpawnTextEntities(void)
{
    game_text_damage = SpawnEntityFromTable("game_text",
    {
        color = "236 227 203",
        color2 = "0 0 0",
        channel = 1,
        effect = 0,
        fadein = 0,
        fadeout = 0,
        fxtime = 0,
        holdtime = 250,
        message = "0",
        spawnflags = 0,
        x = 0.481,
        y = 0.788,
    });
}
SpawnTextEntities(null);

AddListener("tick_only_valid", 2, function (timeDelta)
{
    TickBossBar(GetBossPlayers()[0]); //todo not built for duo-bosses

    foreach (player in GetValidMercs())
    {
        if (GetPropInt(player, "m_nButtons") & IN_SCORE)
            continue;
        local number = floor(player in damage ? damage[player] : 0);
        local offset = number < 10 ? 0.498 : number < 100 ? 0.493 : number < 1000 ? 0.491 : 0.487;

        SetPropString(game_text_damage, "m_iszMessage", ""+number.tointeger());
        game_text_damage.KeyValueFromFloat("x", offset);
        game_text_damage.AcceptInput("Display", "", player, player);
    }
});

function TickBossBar(boss)
{
    if (IsPlayerDead(boss))
        return;
    if (bossBarTicker < 2)
    {
        bossBarTicker++;
        SetPropInt(pd_logic, "m_nBlueScore", 0);
        SetPropInt(pd_logic, "m_nBlueTargetPoints", 0);
        return;
    }
    local barValue = floor(clamp(1024.0 * boss.GetHealth() / boss.GetMaxHealth(), 1, 1024));
    SetPropInt(pd_logic, "m_nBlueScore", boss.GetHealth());
    SetPropInt(pd_logic, "m_nBlueTargetPoints", barValue);
    SetPropInt(pd_logic, "m_nRedScore", GetAliveMercCount());
}