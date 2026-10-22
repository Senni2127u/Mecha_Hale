::backThrustersModelFx <- "models/vsh/player/items/thrusters_back_fx_constant.mdl";
::feetThrustersModelFx <- "models/vsh/player/items/thrusters_legs_fx_constant.mdl";
::shortFeetThrustersModelFx <- "models/vsh/player/items/thrusters_legs_fx.mdl";

PrecacheModel(backThrustersModelFx);
PrecacheModel(feetThrustersModelFx);
PrecacheModel(shortFeetThrustersModelFx);
PrecacheScriptSound("TFPlayer.AirBlastImpact");

// NOTE: This file must be included/executed AFTER sweeping_charge.nut and
// brave_jump.nut, since it patches methods that live on their classes
// (SweepingChargeTrait / BraveJumpTrait). If this loads first, these
// classes won't exist yet and the lines below will error.

::KillWearableFx <- function(ent)
{
    if (ent != null && ent.IsValid())
        EntFireByHandle(ent, "Kill", "", 0, null, null);
    return null;
}


SweepingChargeTrait.thrusters_wearable_back <- null;
SweepingChargeTrait.thrusters_wearable_feet <- null;

local WindUpReal = SweepingChargeTrait.WindUp;
local FinishReal = SweepingChargeTrait.Finish;
local PerformBraveJumpReal = BraveJumpTrait.Perform;


SweepingChargeTrait.WindUp <- function()
{
    if (this.meter <= 0)
    {
        this.thrusters_wearable_back = this.boss.CreateCustomWearable(null, backThrustersModelFx);
        if (!this.boss.IsOnGround())
            this.thrusters_wearable_feet = this.boss.CreateCustomWearable(null, feetThrustersModelFx);
    }
    WindUpReal.call(this);
}

SweepingChargeTrait.Finish <- function()
{
    FinishReal.call(this);
    this.thrusters_wearable_back = KillWearableFx(this.thrusters_wearable_back);
    this.thrusters_wearable_feet = KillWearableFx(this.thrusters_wearable_feet);
}

BraveJumpTrait.Perform <- function()
{
    PerformBraveJumpReal.call(this);
    EntFireByHandle(this.boss.CreateCustomWearable(null, shortFeetThrustersModelFx), "Kill", "", 2, null, null);
    this.boss.EmitSound("TFPlayer.AirBlastImpact");
}
