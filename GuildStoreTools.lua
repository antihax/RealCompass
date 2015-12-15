local addonName = "GuildStoreTools"
local versionString = "v0.0.1"
local serverName = ""
local GST_Original_ZO_LinkHandler_OnLinkMouseUp 

-- Returns a string with the server name.
local function getServerName() 
  local charName = GetUnitName("player")
  local uniqueName = GetUniqueNameForCharacter(charName)
  local serverName = string.sub(uniqueName, 1, string.find(uniqueName, charName)-2)
  return serverName
end

local selectedItem

 -- Main entrypoint
function GUILDSTORETOOLS_addonLoaded(eventCode, name)
  -- Prevent loading twice
  if name ~= addonName then return end

  -- get the serverName
  serverName = getServerName()

  -- Hook the link handler right click.
  GST_Original_ZO_LinkHandler_OnLinkMouseUp = ZO_LinkHandler_OnLinkMouseUp
  ZO_LinkHandler_OnLinkMouseUp = function(iL, b, c) 
    GUILDSTORETOOLS_LinkHandler_OnLinkMouseUp(iL, b, c) end

  ZO_PreHookHandler(ItemTooltip, "OnUpdate", function(c, ...) GUILDSTORETOOLS_OnTooltip(c) end)
end
EVENT_MANAGER:RegisterForEvent("GuildStoreTools", EVENT_ADD_ON_LOADED, GUILDSTORETOOLS_addonLoaded)

 -- Copied from MasterMerchant (MIT license. Copyright (c) 2014, Dan Stone (aka @khaibit) / Chris Lasswell (aka @Philgo68))
function GUILDSTORETOOLS_LinkHandler_OnLinkMouseUp(link, button, control)
    if (type(link) == 'string' and #link > 0) then
    local handled = LINK_HANDLER:FireCallbacks(LINK_HANDLER.LINK_MOUSE_UP_EVENT, link, button, ZO_LinkHandler_ParseLink(link))
    if (not handled) then
            GST_Original_ZO_LinkHandler_OnLinkMouseUp(link, button, control)
            if (button == 2 and link ~= '') then        
              AddMenuItem("Item Statistics", function() GUILDSTORETOOLS_StatsLinkMenu(link) end)
                ShowMenu(control)
            end
        end
    end
end
-- END

function GUILDSTORETOOLS_OnTooltip(tip)
  local item = GUILDSTORETOOLS_GetItemLinkFromMOC()
  if selectedItem ~= item and tip then
    selectedItem = item
    
    local itemID = ESODR_ItemIDFromLink(item)
    local uniqueID = ESODR_UniqueIDFromLink(item)
    local data = GUILDSTORETOOLS_GetStatistics(item)
    
    if data then
      ZO_Tooltip_AddDivider(tip)
      tip:AddLine(
        data["days"] .. " days: " .. ESODR_NumberToText(data["count"]) .. 
        " sales and " .. ESODR_NumberToText(data["sum"]) .. 
        " items." 
        , "ZoFontGame", 255,255,255)
      tip:AddLine(
        "25th: " .. ESODR_CurrencyToText(data["p25th"]) ..
        "   median: " .. ESODR_CurrencyToText(data["median"]) ..
        "   75th: " .. ESODR_CurrencyToText(data["p75th"])
        , "ZoFontGame", 255,255,255)
    end
  end  
end

function GUILDSTORETOOLS_GetItemLinkFromMOC()
  local item = moc()
  if not item or not item.GetParent then return nil end
  local parent = item:GetParent()

  if parent then
    local parentName = parent:GetName()
    if (item.dataEntry and item.dataEntry.data.bagId) then
      return GetItemLink(item.dataEntry.data.bagId, item.dataEntry.data.slotIndex)
    elseif parentName == "ZO_StoreWindowListContents" then
      return GetStoreItemLink(item.dataEntry.data.slotIndex, LINK_STYLE_DEFAULT)
    elseif parentName == "ZO_TradingHouseItemPaneSearchResultsContents" 
      and item.dataEntry and item.dataEntry.data and item.dataEntry.data.timeRemaining then
      
      return GetTradingHouseSearchResultItemLink(item.dataEntry.data.slotIndex)
    elseif parentName == "ZO_TradingHousePostedItemsListContents" then
      return GetTradingHouseListingItemLink(item.dataEntry.data.slotIndex)
    end
  end
  
  return nil
end

function GUILDSTORETOOLS_GetStatistics(l)
  local days = 7
  local data = nil
  local data = ESODR_StatisticsForRange(ESODR_ItemIDFromLink(l), ESODR_UniqueIDFromLink(l), days)
  if not data or data["count"] < 10 then 
    days = 15
    data = ESODR_StatisticsForRange(ESODR_ItemIDFromLink(l), ESODR_UniqueIDFromLink(l), days)
    if not data or data["count"] < 10 then
      days = 30
      data = ESODR_StatisticsForRange(ESODR_ItemIDFromLink(l), ESODR_UniqueIDFromLink(l), days)
    end
  end
  if data then data["days"] = days end
  return data
end

function GUILDSTORETOOLS_StatsLinkMenu(l)
  local data = GUILDSTORETOOLS_GetStatistics(l)
  if not data then
    d("No data available for " .. l .. ".")
    return
  end
  
  local ChatEditControl = CHAT_SYSTEM.textEntry.editControl
  if (not ChatEditControl:HasFocus()) then StartChatInput() end
  ChatEditControl:InsertText(
    l .. 
    " " .. data["days"] .. " days: " .. ESODR_NumberToText(data["count"]) .. 
    " sales/" .. ESODR_NumberToText(data["sum"]) .. 
    " items. Price Stats: " ..  
    "   25th: " .. ESODR_CurrencyToText(data["p25th"]) ..
    "   median: " .. ESODR_CurrencyToText(data["median"]) ..
    "   75th: " .. ESODR_CurrencyToText(data["p75th"]))
end


