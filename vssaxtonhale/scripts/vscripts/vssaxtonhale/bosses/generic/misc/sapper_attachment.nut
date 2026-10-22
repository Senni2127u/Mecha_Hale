//Boss side Sapper script.
// Credit - Senni
// Purpose: Handles the Boss side of the Sapper functionality.

// Sapper sound effects (from game_sounds_weapons.txt).
const SAPPER_SOUND_PLANT   = "Weapon_Sapper.Plant"; //The actual, well, plant sound when Spy applies it.
const SAPPER_SOUND_TIMER   = "Weapon_Sapper.Timer";  // the hissing from the Sapper sound.
const SAPPER_SOUND_REMOVED = "Weapon_Sapper.Removed"; // the "break" sound
const SAPPER_PARTICLE_ZAP  = "ExplosionCore_sapperdestroyed"; // electrical break particle effect after destroyed.

// Optional attachment override, typically leave null as tf_wearable bone merges automatically.
local SAPPER_ATTACHMENT = null;

PrecacheSound(SAPPER_SOUND_PLANT);
PrecacheSound(SAPPER_SOUND_TIMER);
PrecacheSound(SAPPER_SOUND_REMOVED);
PrecacheModel("models/buildables/sapper_placed.mdl");
PrecacheModel("models/buildables/sapper_placement.mdl");
PrecacheModel("models/buildables/p2rec_placed.mdl");
PrecacheModel("models/buildables/p2rec_placement.mdl");
PrecacheModel("models/buildables/sd_sapper_placed.mdl");
PrecacheModel("models/buildables/sd_sapper_placement.mdl");
PrecacheModel("models/buildables/sapper_xmas_placed.mdl");
PrecacheModel("models/buildables/sapper_xmas_placement.mdl");
PrecacheModel("models/buildables/breadmonster_sapper_placed.mdl");
PrecacheModel("models/buildables/breadmonster_sapper_placement.mdl");

hasSapper <- false;
blueprintRequests <- {};
sapperRemoveAt <- 0.0;

sapper_wearable <- null;
sapper_particle <- null;
blueprint_wearable <- null;

local function KillIfValid(ent)
{
    if (ent != null && ent.IsValid())
        ent.Kill();
    return null;
}


local function SetDestroyCallback(entity, callback)
{
    entity.ValidateScriptScope();
    local scope = entity.GetScriptScope();
    scope.setdelegate({}.setdelegate({
            parent   = scope.getdelegate()
            id       = entity.GetScriptId()
            index    = entity.entindex()
            callback = callback
            _get = function(k)
            {
                return parent[k];
            }
            _delslot = function(k)
            {
                if (k == id)
                {
                    entity = EntIndexToHScript(index);
                    local scope = entity.GetScriptScope();
                    scope.self <- entity;
                    callback.pcall(scope);
                }
                delete parent[k];
            }
        })
    );
}


local function CreateWorldModel(model)
{
    local worldModel = SpawnEntityFromTable("tf_wearable", {}); //Reason we create a tf_wearable is because those automatically bone merge to the parent.
    if (worldModel == null)
        return null;
    worldModel.SetModelSimple(model);
    SetPropBool(worldModel, "m_bForcePurgeFixedupStrings", true);
    SetPropBool(worldModel, "m_bValidatedAttachedEntity", true);
    SetPropBool(worldModel, "m_AttributeManager.m_Item.m_bInitialized", true);
    SetPropEntity(worldModel, "m_hOwnerEntity", self);
    EntFireByHandle(worldModel, "SetParent", "!activator", 0, self, self);
    if (SAPPER_ATTACHMENT != null)
        EntFireByHandle(worldModel, "SetParentAttachment", SAPPER_ATTACHMENT, 0, self, self);
    return worldModel;
}


local function ParentTo(ent, parent)
{
    ent.AcceptInput("SetParent", "!activator", parent, parent);
}

local function CreateParticle(effectName, parent)
{
    local fx = SpawnEntityFromTable("info_particle_system", {
        effect_name  = effectName
        start_active = 1
    });
    if (fx != null)
        ParentTo(fx, parent); // follows parent's origin.
    return fx;
}

local function GetItemId(weapon)
{
    return GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex"); //We need to grab Sapper indexes here.
}

function SendBlueprintRequest(spyPlayer, sapperWeapon)
{
    blueprintRequests[spyPlayer] <- sapperWeapon;
}

local function GetSapperModel(weapon)
{
    local id = GetItemId(weapon);
    if (id == 933)  return "models/buildables/p2rec_placed.mdl";        // Ap-Sap
    if (id == 810)  return "models/buildables/sd_sapper_placed.mdl";    // Red Tape
    if (id == 1080) return "models/buildables/sapper_xmas_placed.mdl";  // Festive
    if (id == 1102) return "models/buildables/breadmonster_sapper_placed.mdl"; // Snack Attack
    return "models/buildables/sapper_placed.mdl"; //Original Sapper
}

local function GetBlueprintModel(weapon)
{
    local id = GetItemId(weapon);
    if (id == 933)  return "models/buildables/p2rec_placement.mdl"; //Ap-Sap
    if (id == 810)  return "models/buildables/sd_sapper_placement.mdl"; //Red Tape
    if (id == 1080) return "models/buildables/sapper_xmas_placement.mdl"; //Festive
    if (id == 1102) return "models/buildables/breadmonster_sapper_placement.mdl"; //Snack Attack
    return "models/buildables/sapper_placement.mdl"; //Original Sapper
}

function TryApplySapper(spyPlayer, sapperWeapon)
{
    if (hasSapper)
        return false;
    hasSapper = true;
    blueprintRequests = {};

    blueprint_wearable = KillIfValid(blueprint_wearable);
    sapper_wearable = KillIfValid(sapper_wearable);
    sapper_particle = KillIfValid(sapper_particle);

    sapper_wearable = CreateWorldModel(GetSapperModel(sapperWeapon));
    sapper_particle = CreateParticle("buildingdamage_spark2", sapper_wearable);

    sapper_wearable.EmitSound(SAPPER_SOUND_PLANT);
    sapper_wearable.EmitSound(SAPPER_SOUND_TIMER);
    SetDestroyCallback(sapper_wearable, function()
    {
        self.StopSound(SAPPER_SOUND_TIMER);
    });


    self.AddCondEx(TF_COND_MARKEDFORDEATH, 15, spyPlayer); //VSH VScript bosses typically have a reduced timer against Marked for Death, so it's actually 7.5 seconds in game, adjust this to balance.

    sapperRemoveAt = Time() + 7.5; //Timer that deals with the visible removal of the Sapper.
    return true;
}


function SapperMainThink()
{
    if (hasSapper)
    {
        local shouldRemove = Time() >= sapperRemoveAt || !IsPlayerAlive(self);

        if (!shouldRemove)
        {
            self.AddCustomAttribute("move speed penalty", 0.75, 0.2); //the original script did apply movement speed penalty to Hale, so it's here, but it's not a good debuff.
            return 0.1;
        }

        if (sapper_wearable != null && sapper_wearable.IsValid())
            sapper_wearable.StopSound(SAPPER_SOUND_TIMER);

        local zapAngles = self.EyeAngles();
        DispatchParticleEffect(SAPPER_PARTICLE_ZAP, self.EyePosition(), Vector(zapAngles.x, zapAngles.y, zapAngles.z));
        self.EmitSound(SAPPER_SOUND_REMOVED);

        sapper_particle = KillIfValid(sapper_particle);
        sapper_wearable = KillIfValid(sapper_wearable);
        hasSapper = false;
        return 0.1;
    }

    local blueprintModel = null;
    foreach (spyPlayer, sapperWeapon in blueprintRequests)
        if (sapperWeapon != null && sapperWeapon.IsValid()
            && spyPlayer != null && spyPlayer.IsValid() && IsPlayerAlive(spyPlayer)
            && spyPlayer.GetActiveWeapon() == sapperWeapon)
        {
            blueprintModel = GetBlueprintModel(sapperWeapon);
            break;
        }

    if (!blueprintModel)
        blueprint_wearable = KillIfValid(blueprint_wearable);
    else if (blueprint_wearable == null || !blueprint_wearable.IsValid())
        blueprint_wearable = CreateWorldModel(blueprintModel);

    return 0.1;
}

AddThinkToEnt(self, "SapperMainThink");
