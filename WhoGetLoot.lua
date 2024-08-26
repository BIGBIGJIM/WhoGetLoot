function whoGetLoot_OnLoad()
  if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage(string.format(WHOGETLOOT_MSG_LOAD, WHOGETLOOT_VERSION))
	end

	this:RegisterEvent("VARIABLES_LOADED")
	this:RegisterEvent("CHAT_MSG_LOOT")
	this:RegisterEvent("CHAT_MSG_SYSTEM")


  -- listen loot status:
  whoGetLoot_listent_loot_stusts = false
	
	-- Default settings:
	whoGetLoot_settings = {}
	whoGetLoot_settings["enablePoor"] = false
	whoGetLoot_settings["enableCommon"] = false
	whoGetLoot_settings["enableUncommon"] = false
	whoGetLoot_settings["enableRare"] = false
	whoGetLoot_settings["enableEpic"] = true
	whoGetLoot_settings["enableLegendary"] = true

  -- Quality mapping:
  whoGetLoot_quality_mapping = {}
  whoGetLoot_quality_mapping["enablePoor"] = "9d9d9d"
  whoGetLoot_quality_mapping["enableCommon"] = "ffffff"
  whoGetLoot_quality_mapping["enableUncommon"] = "1eff00"
  whoGetLoot_quality_mapping["enableRare"] = "0070dd"
  whoGetLoot_quality_mapping["enableEpic"] = "a335ee"
  whoGetLoot_quality_mapping["enableLegendary"] = "ff8000"

  whoGetLoot_row_array = {}
  whoGetLoot_row_total = 0
  whoGetLoot_current_page_number = 1
  whoGetLoot_current_page_size = 20

	-- Register a slash command:
  SlashCmdList["WHOGETLOOT"] = whoGetLoot_toggle_main
  SLASH_WHOGETLOOT1 = "/wgl"
  SLASH_WHOGETLOOT2 = "/whoGetLoot"

	
	-- Make the options frame closable with ESC:
	table.insert(UISpecialFrames,"whoGetLoot_option");
	table.insert(UISpecialFrames,"whoGetLoot_setDKP");
  table.insert(UISpecialFrames,"whoGetLoot_exportDKP");
  table.insert(UISpecialFrames,"whoGetLoot_tips");
  
end

function whoGetLoot_OnEvent()
	if (event == "VARIABLES_LOADED") then
		whoGetLoot_initialize()
	end
	
	if (event == "CHAT_MSG_LOOT") then
    whoGetLoot_handle_loot_message(arg1)
	end

  if event == "CHAT_MSG_SYSTEM" and arg1 == WHOGETLOOT_MSG_SYSTEM_MESSAGE_JOIN then
    whoGetLoot_start_listen()
  end

  if event == "CHAT_MSG_SYSTEM" and arg1 == WHOGETLOOT_MSG_SYSTEM_MESSAGE_LEAVE then
    whoGetLoot_stop_listen()
  end
end

function whoGetLoot_initialize()

	whoGetLoot_language = GetDefaultLanguage("player")
	-- Set the checkboxes:
	whoGetLoot_optionEnablePoor:SetChecked(whoGetLoot_settings["enablePoor"])
	whoGetLoot_optionEnableCommon:SetChecked(whoGetLoot_settings["enableCommon"])
	whoGetLoot_optionEnableUncommon:SetChecked(whoGetLoot_settings["enableUncommon"])
	whoGetLoot_optionEnableRare:SetChecked(whoGetLoot_settings["enableRare"])
	whoGetLoot_optionEnableEpic:SetChecked(whoGetLoot_settings["enableEpic"])
	whoGetLoot_optionEnableLegendary:SetChecked(whoGetLoot_settings["enableLegendary"])

  whoGetLoot_allow_color = whoGetLoot_get_enable_color()

  whoGetLoot_init_listen_status()

	-- Hide the window:
	whoGetLoot_main:Hide()
	whoGetLoot_option:Hide()
  whoGetLoot_setDKP:Hide()
  whoGetLoot_exportDKP:Hide()
  whoGetLoot_tips:Hide()

end

function whoGetLoot_Message(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function whoGetLoot_toggle_main() 
  if whoGetLoot_main:IsVisible() then
		whoGetLoot_main:Hide()
	else
		whoGetLoot_main:Show()
	end
end

function whoGetLoot_toggle_option() 
  if whoGetLoot_option:IsVisible() then
		whoGetLoot_option:Hide()
	else
		whoGetLoot_option:Show()
	end
end

function whoGetLoot_toggle_tips() 
  if whoGetLoot_tips:IsVisible() then
		whoGetLoot_tips:Hide()
	else
		whoGetLoot_tips:Show()
	end
end


function whoGetLoot_open_frame_setDKP(rowName) 
  if not whoGetLoot_setDKP:IsVisible() then
    local dataIndex = getglobal(rowName):GetText()
    local row = whoGetLoot_row_array[tonumber(dataIndex)]
    whoGetLoot_setDKPDataIndex:SetText(dataIndex)
    whoGetLoot_setDKPTimeContent:SetText(row[WHOGETLOOT_KEY_TIME])
    whoGetLoot_setDKPNameContent:SetText(row[WHOGETLOOT_KEY_ROLE_NAME])
    whoGetLoot_setDKPLootContent:SetText(row[WHOGETLOOT_KEY_LOOT])
    whoGetLoot_setDKPLootContent:SetText(row[WHOGETLOOT_KEY_LOOT])
    whoGetLoot_setDKPDKPEditBox:SetText(row[WHOGETLOOT_KEY_DKP])
		whoGetLoot_setDKP:Show()
	end
end

function whoGetLoot_start_listen()
  whoGetLoot_listent_loot_stusts = true
  whoGetLoot_mainStatusInfo:SetText(WHOGETLOOT_LABEL_LISTENING)
  whoGetLoot_mainStatusInfo:SetTextColor(0, 1.0, 0, 1)
  whoGetLoot_Message(WHOGETLOOT_LABEL.." |CFFFFFF00".."开始记录！"..FONT_COLOR_CODE_CLOSE)
end

function whoGetLoot_stop_listen()
  whoGetLoot_listent_loot_stusts = false
  whoGetLoot_mainStatusInfo:SetText(WHOGETLOOT_LABEL_STOP_LISTEN)
  whoGetLoot_mainStatusInfo:SetTextColor(1.0, 0, 0, 0.5)
  whoGetLoot_Message(WHOGETLOOT_LABEL.." |CFFFFFF00".."停止记录！"..FONT_COLOR_CODE_CLOSE)
end

function whoGetLoot_row_data_clear() 
  whoGetLoot_row_array = {}
  whoGetLoot_row_total = 0
  whoGetLoot_current_page_number = 1
  whoGetLoot_refresh_row_data()
  if whoGetLoot_setDKP:IsVisible() then
    whoGetLoot_setDKP:Hide()
  end
end

function whoGetLoot_refresh_row_data()
  whoGetLoot_row_total = table.getn(whoGetLoot_row_array)
  local startIndex, endIndex
  startIndex = whoGetLoot_row_total - (whoGetLoot_current_page_number - 1) * whoGetLoot_current_page_size
  endIndex = whoGetLoot_row_total - whoGetLoot_current_page_number * whoGetLoot_current_page_size + 1
  endIndex = (endIndex > 0 and endIndex or 1)

  local row = nil
  local j = 1

  for i = startIndex, endIndex, -1 do
    row = whoGetLoot_row_array[i]
    getglobal("FrameListButton" .. j .. "DataIndex"):SetText(i);
    getglobal("FrameListButton" .. j .. "Time"):SetText(row[WHOGETLOOT_KEY_TIME]);
    getglobal("FrameListButton" .. j .. "Name"):SetText(row[WHOGETLOOT_KEY_ROLE_NAME]);
    getglobal("FrameListButton" .. j .. "Loot"):SetText(row[WHOGETLOOT_KEY_LOOT]);
    getglobal("FrameListButton" .. j .. "DKP"):SetText(row[WHOGETLOOT_KEY_DKP]);
    getglobal("FrameListButton" .. j .. "SetDkpButton"):Show();
    getglobal("FrameListButton" .. j):Show();
    j = j + 1
  end
  if j <= whoGetLoot_current_page_size then
    for jj = j, whoGetLoot_current_page_size do
      getglobal("FrameListButton" .. jj .. "SetDkpButton"):Hide();
      getglobal("FrameListButton" .. jj):Hide();
    end
  end
  whoGetLoot_update_page_message()
end

function whoGetLoot_update_page_message()
  local pageInfo = string.format(WHOGETLOOT_LABEL_PAGE_INFO_TEMPLATE, whoGetLoot_row_total, whoGetLoot_current_page_number)
  whoGetLoot_mainPageInfo:SetText(pageInfo)
end


-- text:e.g. "You receive loot: |cffffffff|Hitem:2589::::::::20:257::::::|h[Linen Cloth]|h|rx2."
function whoGetLoot_handle_loot_message(message)
  if (whoGetLoot_listent_loot_stusts) then
    if (string.find(message, WHOGETLOOT_MSG_PATTERN)) then
      whoGetLoot_do_loot_message_handle(message, WHOGETLOOT_MSG_PATTERN, WHOGETLOOT_MSG_LOOT_PATTERN)
    elseif (string.find(message, WHOGETLOOT_MSG_WIN_PATTERN)) then
      whoGetLoot_do_loot_message_handle(message, WHOGETLOOT_MSG_WIN_PATTERN, WHOGETLOOT_MSG_WIN_LOOT_PATTERN)
    end
  end
end

function whoGetLoot_do_loot_message_handle(message, pattern, pattern2)
  local _, _, player, color = string.find(message, pattern)
  local addFlag = false
  for key, value in pairs(whoGetLoot_allow_color) do
    if (color == value) then 
      addFlag = true
    end
  end
  if (addFlag) then
    if (player == WHOGETLOOT_MSG_SELF) then
      player = UnitName("player")
      currentMessage = string.gsub(message, WHOGETLOOT_MSG_SELF, player)
    end
    local _, _, lootInfo = string.find(message, pattern2)
    local nowTime = date("20%y/%m/%d %H:%M:%S")
    local rowInfo = {}
    rowInfo[WHOGETLOOT_KEY_TIME] = nowTime
    rowInfo[WHOGETLOOT_KEY_ROLE_NAME] = player
    rowInfo[WHOGETLOOT_KEY_LOOT] = lootInfo
    rowInfo[WHOGETLOOT_KEY_DKP] = 0
    table.insert(whoGetLoot_row_array, rowInfo)
    whoGetLoot_refresh_row_data()
  end
end

function whoGetLoot_get_enable_color() 
  local colorArray = {}
  for key,value in pairs(whoGetLoot_settings) do
    if (value) then
      colorArray[key] = whoGetLoot_quality_mapping[key]
    end
  end
  return colorArray
end

function whoGetLoot_quality_toggle(key, checked)
  whoGetLoot_settings[key] = checked
  whoGetLoot_allow_color = whoGetLoot_get_enable_color()
end

function whoGetLoot_next_page()
  local currentPageMaxIndex = whoGetLoot_current_page_number * whoGetLoot_current_page_size
  if currentPageMaxIndex < whoGetLoot_row_total then
    whoGetLoot_current_page_number = whoGetLoot_current_page_number + 1
    whoGetLoot_refresh_row_data()
  end
end

function whoGetLoot_previous_page()
  if whoGetLoot_current_page_number > 1 then
    whoGetLoot_current_page_number = whoGetLoot_current_page_number - 1
    whoGetLoot_refresh_row_data()
  end
end

function whoGetLoot_dkp_confirm()
  local rowIndex = whoGetLoot_setDKPDataIndex:GetText()
  local ponit = whoGetLoot_setDKPDKPEditBox:GetText()
  local row = whoGetLoot_row_array[tonumber(rowIndex)]
  row[WHOGETLOOT_KEY_DKP] = ponit
  whoGetLoot_refresh_row_data()
  whoGetLoot_setDKP:Hide()
  if (GetNumRaidMembers() > 0) then
    local raidMessage = string.format(WHOGETLOOT_MSG_RAID_SET_DKP_TEMPLATE, row[WHOGETLOOT_KEY_ROLE_NAME], row[WHOGETLOOT_KEY_TIME], row[WHOGETLOOT_KEY_LOOT], ponit)
    SendChatMessage(raidMessage,"RAID")
  end
end

function whoGetLoot_export_csv_data()
  local csvText = WHOGETLOOT_BUTTON_HEADER_TIME..","..WHOGETLOOT_BUTTON_HEADER_NAME..","..WHOGETLOOT_BUTTON_HEADER_LOOT..","..WHOGETLOOT_BUTTON_HEADER_DKP..WHOGETLOOT_MSG_NEW_LINE
  for i = 1, whoGetLoot_row_total do
      local row = whoGetLoot_row_array[i]
      csvText = csvText .. row[WHOGETLOOT_KEY_TIME] .. "," .. row[WHOGETLOOT_KEY_ROLE_NAME] .. "," .. row[WHOGETLOOT_KEY_LOOT] .. "," .. row[WHOGETLOOT_KEY_DKP] .. WHOGETLOOT_MSG_NEW_LINE
  end
  getglobal("whoGetLoot_exportDKPExportEdit"):SetText(csvText);
  getglobal("whoGetLoot_exportDKP"):Show();
end

function whoGetLoot_init_listen_status()
  if (GetNumRaidMembers() > 0) then
    whoGetLoot_start_listen()
  else
    whoGetLoot_stop_listen()
  end
end

function whoGetLoot_update_receiver(rowName)
  if (GetNumRaidMembers() > 0) then
    local unitName = UnitName("target")
    for i = 1, GetNumRaidMembers(),1 do
      local name = UnitName("raid"..i)
      if (unitName == name) then
        local dataIndex = getglobal(rowName):GetText()
        local row = whoGetLoot_row_array[tonumber(dataIndex)]
        local raidMessage = string.format(WHOGETLOOT_MSG_RAID_UPDATE_ROLE_NAME_TEMPLATE, row[WHOGETLOOT_KEY_ROLE_NAME], row[WHOGETLOOT_KEY_TIME], row[WHOGETLOOT_KEY_LOOT], name)
        row[WHOGETLOOT_KEY_ROLE_NAME] = name
        whoGetLoot_refresh_row_data()
        SendChatMessage(raidMessage,"RAID")
        break
      end
    end
  end
end