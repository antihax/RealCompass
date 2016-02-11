local addonName = "RealCompass"
local versionString = "v0.1.5"
REALCOMPASS_Variables = {}
local defaults = {
  left = 0,
  top = 0
}

local groupLeader 

local function UpdateUI()
  local cameraHeading = GetPlayerCameraHeading()
  local center = 110
  local length = 80
  
  RealCompassMain_Fabric:SetTextureRotation(-cameraHeading)

  local foundLeader = false

  local x, y = GetMapPlayerPosition("player")
  for i = 1, GROUP_SIZE_MAX do
    local groupTag = ZO_Group_GetUnitTagForGroupIndex(i)
    if DoesUnitExist(groupTag) and IsUnitOnline(groupTag) and not AreUnitsEqual("player", groupTag) then
        local isLeader = IsUnitGroupLeader(groupTag)
        if isLeader then
            foundLeader = true
            groupLeader:SetHidden(false)
            
            local x1, y1 = GetMapPlayerPosition(groupTag)
            local bearing = -(math.atan2( (x1-x), (y1-y) ) - (math.pi/2))
            local distance = math.sqrt( ((x1-x)^2) + ((y1-y)^2) )
            local distM = distance * 1000
            if distM > 1 then
              distM = 1
            end
            
            local angle = (bearing + cameraHeading)
            
            if angle > math.pi then
              angle = angle - 2 * math.pi
            elseif angle < -math.pi then
              angle = angle + 2 * math.pi
            end            
            
            local glx = (math.cos(angle) * (length * distM)) + center
            local gly = (math.sin(angle) * (length * distM)) + center
            
            groupLeader:ClearAnchors()
            groupLeader:SetAnchor(TOPLEFT, RealCompassMain, TOPLEFT, glx, gly)
        end
    end
  end
  
  if not foundLeader then
    groupLeader:SetHidden(true)
  end
end

function SetVisible(_, _, active)
    RealCompassMain:SetHidden(active > 2)
end

 -- Main entrypoint
local function AddonLoaded(eventCode, name)
  -- Prevent loading twice
  if name ~= addonName then return end
  REALCOMPASS_Variables = ZO_SavedVars:NewAccountWide("RealCompassSavedVariables", 1, "Position", defaults)
  
  groupLeader = WINDOW_MANAGER:CreateControl("RC_GroupLeaderImg", RealCompassMain, CT_TEXTURE)
  groupLeader:SetDimensions(26, 26)
  groupLeader:SetTexture("EsoUI/Art/Compass/groupLeader.dds")
  groupLeader:SetHidden(true)
  groupLeader:SetAnchor(TOPLEFT, RealCompassMain, TOPLEFT, 0, 0)
  groupLeader:SetDrawLayer(2)
  
  EVENT_MANAGER:RegisterForUpdate("RealCompass", 17, UpdateUI) 
  EVENT_MANAGER:RegisterForEvent('RealCompass', EVENT_ACTION_LAYER_POPPED, SetVisible)
  EVENT_MANAGER:RegisterForEvent('RealCompass', EVENT_ACTION_LAYER_PUSHED, SetVisible)
  
  RealCompassMain:ClearAnchors()
  RealCompassMain:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, REALCOMPASS_Variables.left, REALCOMPASS_Variables.top)
end

EVENT_MANAGER:RegisterForEvent("RealCompass", EVENT_ADD_ON_LOADED, AddonLoaded)

function REALCOMPASS_OnMoveStop()
  REALCOMPASS_Variables.left = RealCompassMain:GetLeft()
  REALCOMPASS_Variables.top = RealCompassMain:GetTop()
end