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

::hudAbilityInstances <- {};

class AbilityHudTrait extends BossTrait
{
    game_text_charge = null;
    game_text_punch = null;
    game_text_slam = null;

    //₁₂₃₄₅₆₇₈₉₀
    //¹²³⁴⁵⁶⁷⁸⁹⁰
    big2small = {
        " ": " ", //" "
        "r": "✔",
        "1": "₁",
        "2": "₂",
        "3": "₃",
        "4": "₄",
        "5": "₅",
        "6": "₆",
        "7": "₇",
        "8": "₈",
        "9": "₉",
        "0": "₀",
    };

    function OnApply()
    {
        game_text_charge = SpawnEntityFromTable("game_text",
        {
            color = "255 255 255",
            color2 = "0 0 0",
            channel = 0,
            effect = 0,
            fadein = 0,
            fadeout = 0,
            fxtime = 0,
            holdtime = 250,
            message = "0",
            spawnflags = 0,
            x = 0.67,
            y = 0.91 //Original value is 0.939, i'm changing it here because Mecha Hale's UI has text on the bottom. - Senni
        });

        game_text_punch = SpawnEntityFromTable("game_text",
        {
            color = "255 255 255",
            color2 = "0 0 0",
            channel = 1,
            effect = 0,
            fadein = 0,
            fadeout = 0,
            fxtime = 0,
            holdtime = 250,
            message = "0",
            spawnflags = 0,
            x = 0.778,
            y = 0.91 //Same here.
        });

        game_text_slam = SpawnEntityFromTable("game_text",
        {
            color = "255 255 255",
            color2 = "0 0 0",
            channel = 2,
            effect = 0,
            fadein = 0,
            fadeout = 0,
            fxtime = 0,
            holdtime = 250,
            message = "0",
            spawnflags = 0,
            x = 0.885,
            y = 0.91 //Same here.
        });
    }

    function OnTickAlive(timeDelta)
    {
        if (!(player in hudAbilityInstances))
            return;

        local progressBarTexts = [];
        local overlay = "";
        foreach(ability in hudAbilityInstances[player])
        {
            local percentage = ability.MeterAsPercentage();
            local progressBarText = BigToSmallNumbers(ability.MeterAsNumber())+" ";
            local i = 13;
            for(; i < clampCeiling(100, percentage); i+=13)
                progressBarText += "▰";
            for(; i <= 100; i+=13)
                progressBarText += "▱";
            progressBarTexts.push(progressBarText);
            if (percentage >= 100)
                overlay += "1";
            else
                overlay += "0";
        }
        if (braveJumpCharges >= 2)
            overlay += "0";
        else
            overlay += cos(Time() * 12) < 0 ? "1" : "2";

        SetPropString(game_text_charge, "m_iszMessage", progressBarTexts[0]);
        game_text_charge.AcceptInput("Display", "", boss, boss);

        SetPropString(game_text_punch, "m_iszMessage", progressBarTexts[1]);
        game_text_punch.AcceptInput("Display", "", boss, boss);

        SetPropString(game_text_slam, "m_iszMessage", progressBarTexts[2]);
        game_text_slam.AcceptInput("Display", "", boss, boss);

        player.SetScriptOverlayMaterial(API_GetString("ability_hud_folder") + "/" + overlay + "_facility");
    }

    function OnDeath(attacker, params)
    {
        SetPropString(game_text_charge, "m_iszMessage", "");
        game_text_charge.AcceptInput("Display", "", boss, boss);

        SetPropString(game_text_punch, "m_iszMessage", "");
        game_text_punch.AcceptInput("Display", "", boss, boss);

        SetPropString(game_text_slam, "m_iszMessage", "");
        game_text_slam.AcceptInput("Display", "", boss, boss);

        player.SetScriptOverlayMaterial("");
    }

    function BigToSmallNumbers(input)
    {
        local result = "";
        foreach (char in input)
            result += big2small[char.tochar()];
        return result;
    }
};