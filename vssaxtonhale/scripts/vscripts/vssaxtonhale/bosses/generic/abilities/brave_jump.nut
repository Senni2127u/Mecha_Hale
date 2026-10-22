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

PrecacheClassVoiceLines("jump")

enum BOSS_JUMP_STATUS
{
    WALKING = 0,
    JUMP_STARTED = 1,
    CAN_DOUBLE_JUMP = 2,
    DOUBLE_JUMPED = 3
};

::braveJumpCharges <- 5;

class BraveJumpTrait extends BossTrait
{
    jumpForce = API_GetFloat("jump_force");
    jumpStatus = BOSS_JUMP_STATUS.WALKING;
    voiceLinePlayed = 0;
    shouldNotifyJump = true;
    lastTimeJumped = Time();

    jumpSpamForwardVel = [0.1, 0.3, 0.7, 1.0, 1.0, 1.0];
    jumpSpamUpwardVel =  [0.5, 0.5, 0.7, 1.0, 1.0, 1.0];
    jumpSpamGrav =       [0.9, 0.7, 0.8, 1.0, 1.0, 1.0];
    jumpSpamStates =     [2, 1, 1, 0, 0, 0];
    jumpSpamCooloff =    [4.0, 4.0, 3.0, 3.0, 2.0, 2.0];
    charges = 5;

    function OnFrameTickAlive()
    {
        local time = Time();
        local buttons = GetPropInt(boss, "m_nButtons");

        if (!boss.IsOnGround())
        {
            if (jumpStatus == BOSS_JUMP_STATUS.WALKING)
                jumpStatus = BOSS_JUMP_STATUS.JUMP_STARTED;
            else if (jumpStatus == BOSS_JUMP_STATUS.JUMP_STARTED && !(buttons & IN_JUMP))
                jumpStatus = BOSS_JUMP_STATUS.CAN_DOUBLE_JUMP;
        }
        else
        {
            if (jumpStatus == BOSS_JUMP_STATUS.DOUBLE_JUMPED)
            {
                boss.SetGravity(1);
                lastTimeJumped = time;
            }
            jumpStatus = BOSS_JUMP_STATUS.WALKING;
        }

        if (buttons & IN_JUMP && jumpStatus == BOSS_JUMP_STATUS.CAN_DOUBLE_JUMP)
        {
            if (!IsRoundSetup() && time - voiceLinePlayed > 1.5)
            {
                voiceLinePlayed = time;
                if (charges > 0)
                    EmitPlayerVO(boss, "jump");
            }

            jumpStatus = BOSS_JUMP_STATUS.DOUBLE_JUMPED;
            Perform();
            charges = clampFloor(0, charges - 1);
            braveJumpCharges = charges;
        }

        if (shouldNotifyJump && time > lastTimeJumped + API_GetInt("setup_length") + 30)
            NotifyJump();
        if (time - lastTimeJumped >= jumpSpamCooloff[charges])
        {
            charges = 5;
            braveJumpCharges = 5;
        }
    }

    function Perform()
    {
        shouldNotifyJump = false;
        lastTimeJumped = Time() + 99;

        local buttons = GetPropInt(boss, "m_nButtons");
        local eyeAngles = boss.EyeAngles();
        local forward = eyeAngles.Forward();
        forward.z = 0;
        forward.Norm();
        local left = eyeAngles.Left();
        left.z = 0;
        left.Norm();

        local forwardmove = 0
        if (buttons & IN_FORWARD)
            forwardmove = 1;
        else if (buttons & IN_BACK)
            forwardmove = -1;
        local sidemove = 0
        if (buttons & IN_MOVELEFT)
            sidemove = -1;
        else if (buttons & IN_MOVERIGHT)
            sidemove = 1;

        local newVelocity = Vector(0,0,0);
        newVelocity.x = forward.x * forwardmove + left.x * sidemove;
        newVelocity.y = forward.y * forwardmove + left.y * sidemove;
        newVelocity.Norm();
        newVelocity *= 300 * jumpSpamForwardVel[charges];
        newVelocity.z = jumpForce * jumpSpamUpwardVel[charges];

        boss.SetGravity(jumpSpamGrav[charges]);

        local currentVelocity = boss.GetAbsVelocity();
        if (currentVelocity.z < 300)
            currentVelocity.z = 0;

        SetPropEntity(boss, "m_hGroundEntity", null);
        boss.SetAbsVelocity(currentVelocity + newVelocity);
    }

    function NotifyJump()
    {
        local text_tf = SpawnEntityFromTable("game_text_tf", {
            message = "#ClassTips_1_2",
            icon = "ico_notify_flag_moving_alt",
            background = TF_TEAM_BOSS,
            display_to_team = TF_TEAM_BOSS
        });
        EntFireByHandle(text_tf, "Display", "", 0.1, player, player);
        EntFireByHandle(text_tf, "Kill", "", 1, player, player);
    }
};