function whoGetLoot_OnLoad()
  if (DEFAULT_CHAT_FRAME) then
    DEFAULT_CHAT_FRAME:AddMessage(string.format(WHOGETLOOT_MSG_LOAD, WHOGETLOOT_VERSION))
  end

  this:RegisterEvent("VARIABLES_LOADED")
  this:RegisterEvent("CHAT_MSG_LOOT")
  this:RegisterEvent("CHAT_MSG_SYSTEM")
  this:RegisterEvent("CHAT_MSG_WHISPER");


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

  -- class color
  whoGetLoot_classes_color_mapping = {}
  whoGetLoot_classes_color_mapping[WHOGETLOOT_SETTLEMENT_KEY_CLASSES_WARRIOR] = { r = 0.78, g = 0.61, b = 0.43 }
  whoGetLoot_classes_color_mapping[WHOGETLOOT_SETTLEMENT_KEY_CLASSES_PALADIN] = { r = 0.96, g = 0.55, b = 0.73 }
  whoGetLoot_classes_color_mapping[WHOGETLOOT_SETTLEMENT_KEY_CLASSES_HUNTER] = { r = 0.67, g = 0.83, b = 0.45 }
  whoGetLoot_classes_color_mapping[WHOGETLOOT_SETTLEMENT_KEY_CLASSES_SHAMAN] = { r = 0.00, g = 0.44, b = 0.87 }
  whoGetLoot_classes_color_mapping[WHOGETLOOT_SETTLEMENT_KEY_CLASSES_ROGUE] = { r = 1.00, g = 0.96, b = 00.41 }
  whoGetLoot_classes_color_mapping[WHOGETLOOT_SETTLEMENT_KEY_CLASSES_PRIEST] = { r = 1.00, g = 1.00, b = 1.00 }
  whoGetLoot_classes_color_mapping[WHOGETLOOT_SETTLEMENT_KEY_CLASSES_MAGE] = { r = 0.25, g = 0.78, b = 0.92 }
  whoGetLoot_classes_color_mapping[WHOGETLOOT_SETTLEMENT_KEY_CLASSES_WARLOCK] = { r = 0.53, g = 0.53, b = 0.93 }
  whoGetLoot_classes_color_mapping[WHOGETLOOT_SETTLEMENT_KEY_CLASSES_DRUID] = { r = 1.00, g = 0.49, b = 0.04 }


  whoGetLoot_row_array = {}
  whoGetLoot_row_total = 0
  whoGetLoot_current_page_number = 1
  whoGetLoot_current_page_size = 20

  whoGetLoot_chock_in_row_array = {}
  whoGetLoot_chock_in_row_total = 0
  whoGetLoot_chock_in_current_page_number = 1
  whoGetLoot_chock_in_current_page_size = 10

  whoGetLoot_import_dkp_data_array = {}
  whoGetLoot_default_dkp = 4
  whoGetLoot_import_dkp_time = ""
  whoGetLoot_import_includ_default_dkp_flag = true
  whoGetLoot_import_dkp_data_role_name_mapping_array = {}


  whoGetLoot_raid_table_hightlight_selected_index = 0

  whoGetLoot_tab_name_list = { "whoGetLoot_main_LootPanel", "whoGetLoot_main_SettlementPanel" }

  -- Register a slash command:
  SlashCmdList["WHOGETLOOT"] = whoGetLoot_toggle_main
  SLASH_WHOGETLOOT1 = "/wgl"
  SLASH_WHOGETLOOT2 = "/whoGetLoot"


  -- Make the options frame closable with ESC:
  table.insert(UISpecialFrames, "whoGetLoot_option");
  table.insert(UISpecialFrames, "whoGetLoot_setDKP");
  table.insert(UISpecialFrames, "whoGetLoot_exportData");
  table.insert(UISpecialFrames, "whoGetLoot_tips");
  table.insert(UISpecialFrames, "whoGetLoot_dataAdd");
  table.insert(UISpecialFrames, "whoGetLoot_clockInRemarkAdd");

  UnitPopupButtons[WHOGETLOOT_POPUP_MENU_GET_LOOT_KEY] = { text = WHOGETLOOT_POPUP_MENU_GET_LOOT_TEXT, dist = 0 };

  whoGetLoot_original_unitpopup = UnitPopup_OnClick;
  UnitPopup_OnClick = whoGetLoot_popup_menu_handle;

  whoGetLoot_popup_menu_onLoad()
end

function whoGetLoot_OnEvent()
  if (event == "VARIABLES_LOADED") then
    whoGetLoot_initialize()
  end

  if (event == "CHAT_MSG_LOOT") then
    whoGetLoot_handle_loot_message(arg1)
  end

  if (event == "CHAT_MSG_WHISPER") then
    whoGetLoot_whisper_handle(arg1, arg2)
  end

  if event == "CHAT_MSG_SYSTEM" and arg1 == WHOGETLOOT_MSG_SYSTEM_MESSAGE_JOIN then
    whoGetLoot_start_listen()
  end

  if event == "CHAT_MSG_SYSTEM" and arg1 == WHOGETLOOT_MSG_SYSTEM_MESSAGE_LEAVE then
    whoGetLoot_stop_listen()
    if whoGetLoot_row_total > 200 then
      whoGetLoot_clear_tips_show()
    end
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

  whoGetLoot_refresh_row_data()

  whoGetLoot_chock_in_refresh_row_data()

  whoGetLoot_init_import_dkp()

  -- Hide the window:
  whoGetLoot_main:Hide()
  whoGetLoot_option:Hide()
  whoGetLoot_setDKP:Hide()
  whoGetLoot_exportData:Hide()
  whoGetLoot_tips:Hide()
  whoGetLoot_dataAdd:Hide()
  whoGetLoot_dataClearTips:Hide()
  whoGetLoot_clockInRemarkAdd:Hide()
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

function whoGetLoot_open_frame_dataAdd()
  if not whoGetLoot_dataAdd:IsVisible() then
    if (GetNumRaidMembers() > 0) then
      local unitName = UnitName("target")
      for i = 1, GetNumRaidMembers(), 1 do
        local name = UnitName("raid" .. i)
        if (unitName == name) then
          local nowTime = date(WHOGETLOOT_MSG_TIME_FORMATE)
          whoGetLoot_dataAddTimeContent:SetText(nowTime)
          whoGetLoot_dataAddNameContent:SetText(unitName)
          whoGetLoot_dataAddLootEditBox:SetText("")
          whoGetLoot_dataAddDKPEditBox:SetText(0)
          whoGetLoot_radio_button_from_data_selected("whoGetLoot_dataAddEffectDkpCheckButtonYes",
            "whoGetLoot_dataAddEffectDkpCheckButtonNo", "whoGetLoot_dataAddEffectDKPFlagValue", WHOGETLOOT_BUTTON_NO)
          whoGetLoot_dataAddRemarkEditBox:SetText("")
          whoGetLoot_dataAdd:Show()
          break
        end
      end
    end
  end
end

function whoGetLoot_open_frame_setDKP(dataIndex)
  if not whoGetLoot_setDKP:IsVisible() then
    local dataIndex = getglobal(dataIndex):GetText()
    local row = whoGetLoot_row_array[tonumber(dataIndex)]
    whoGetLoot_setDKPDataIndex:SetText(dataIndex)
    whoGetLoot_setDKPTimeContent:SetText(row[WHOGETLOOT_KEY_TIME])
    whoGetLoot_setDKPNameContent:SetText(row[WHOGETLOOT_KEY_ROLE_NAME])
    whoGetLoot_setDKPLootContent:SetText(row[WHOGETLOOT_KEY_LOOT])
    whoGetLoot_setDKPDKPEditBox:SetText(row[WHOGETLOOT_KEY_DKP])
    whoGetLoot_radio_button_from_data_selected("whoGetLoot_setDKPEffectDkpCheckButtonYes",
      "whoGetLoot_setDKPEffectDkpCheckButtonNo", "whoGetLoot_setDKPEffectDKPFlagValue",
      row[WHOGETLOOT_KEY_EFFECT_DKP_FLAG])
    whoGetLoot_setDKPRemarkEditBox:SetText(row[WHOGETLOOT_KEY_REMARK])
    whoGetLoot_setDKP:Show()
  end
end

function whoGetLoot_start_listen()
  whoGetLoot_listent_loot_stusts = true
  whoGetLoot_main_LootPanelStatusInfo:SetText(WHOGETLOOT_LABEL_LISTENING)
  whoGetLoot_main_LootPanelStatusInfo:SetTextColor(0, 1.0, 0, 1)
  whoGetLoot_Message(WHOGETLOOT_LABEL .. " |CFFFFFF00" .. "开始记录！" .. FONT_COLOR_CODE_CLOSE)
end

function whoGetLoot_stop_listen()
  whoGetLoot_listent_loot_stusts = false
  whoGetLoot_main_LootPanelStatusInfo:SetText(WHOGETLOOT_LABEL_STOP_LISTEN)
  whoGetLoot_main_LootPanelStatusInfo:SetTextColor(1.0, 0, 0, 0.5)
  whoGetLoot_Message(WHOGETLOOT_LABEL .. " |CFFFFFF00" .. "停止记录！" .. FONT_COLOR_CODE_CLOSE)
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
    getglobal("FrameListButton" .. j .. "EffectDkpFlag"):SetText(row[WHOGETLOOT_KEY_EFFECT_DKP_FLAG]);
    getglobal("FrameListButton" .. j .. "Remark"):SetText(row[WHOGETLOOT_KEY_REMARK]);
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
  local pageInfo = string.format(WHOGETLOOT_LABEL_LOOT_PAGE_INFO_TEMPLATE, whoGetLoot_row_total,
    whoGetLoot_current_page_number)
  whoGetLoot_main_LootPanelPageInfo:SetText(pageInfo)
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
    local nowTime = date(WHOGETLOOT_MSG_TIME_FORMATE)
    local rowInfo = {}
    rowInfo[WHOGETLOOT_KEY_TIME] = nowTime
    rowInfo[WHOGETLOOT_KEY_ROLE_NAME] = player
    rowInfo[WHOGETLOOT_KEY_LOOT] = lootInfo
    rowInfo[WHOGETLOOT_KEY_DKP] = 0
    rowInfo[WHOGETLOOT_KEY_EFFECT_DKP_FLAG] = WHOGETLOOT_BUTTON_NO
    rowInfo[WHOGETLOOT_KEY_REMARK] = ""
    table.insert(whoGetLoot_row_array, rowInfo)
    whoGetLoot_refresh_row_data()
  end
end

function whoGetLoot_get_enable_color()
  local colorArray = {}
  for key, value in pairs(whoGetLoot_settings) do
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

function whoGetLoot_loot_next_page()
  local currentPageMaxIndex = whoGetLoot_current_page_number * whoGetLoot_current_page_size
  if currentPageMaxIndex < whoGetLoot_row_total then
    whoGetLoot_current_page_number = whoGetLoot_current_page_number + 1
    whoGetLoot_refresh_row_data()
  end
end

function whoGetLoot_loot_previous_page()
  if whoGetLoot_current_page_number > 1 then
    whoGetLoot_current_page_number = whoGetLoot_current_page_number - 1
    whoGetLoot_refresh_row_data()
  end
end

function whoGetLoot_dkp_confirm()
  local rowIndex = whoGetLoot_setDKPDataIndex:GetText()
  local ponit = whoGetLoot_setDKPDKPEditBox:GetText()
  local remark = whoGetLoot_setDKPRemarkEditBox:GetText()
  local effectDkp = whoGetLoot_setDKPEffectDKPFlagValue:GetText()
  local row = whoGetLoot_row_array[tonumber(rowIndex)]
  row[WHOGETLOOT_KEY_DKP] = tonumber(ponit)
  row[WHOGETLOOT_KEY_EFFECT_DKP_FLAG] = effectDkp
  row[WHOGETLOOT_KEY_REMARK] = remark
  whoGetLoot_refresh_row_data()
  whoGetLoot_setDKP:Hide()
  if (GetNumRaidMembers() > 0) then
    local raidMessage = string.format(WHOGETLOOT_MSG_RAID_SET_DKP_TEMPLATE, row[WHOGETLOOT_KEY_ROLE_NAME],
      row[WHOGETLOOT_KEY_TIME], row[WHOGETLOOT_KEY_LOOT], ponit)
    SendChatMessage(raidMessage, "RAID")
  end
end

function whoGetLoot_export_loot_csv_data()
  local csvText = WHOGETLOOT_BUTTON_HEADER_TIME ..
      "," .. WHOGETLOOT_BUTTON_HEADER_NAME ..
      "," .. WHOGETLOOT_BUTTON_HEADER_LOOT ..
      "," .. WHOGETLOOT_BUTTON_HEADER_DKP ..
      "," .. WHOGETLOOT_BUTTON_HEADER_EFFECT_DKP_FLAG ..
      "," .. WHOGETLOOT_BUTTON_HEADER_LOOT_REMARK .. WHOGETLOOT_MSG_NEW_LINE
  for i = 1, whoGetLoot_row_total do
    local row = whoGetLoot_row_array[i]
    csvText = csvText ..
        row[WHOGETLOOT_KEY_TIME] ..
        "," .. row[WHOGETLOOT_KEY_ROLE_NAME] ..
        "," .. row[WHOGETLOOT_KEY_LOOT] ..
        "," .. row[WHOGETLOOT_KEY_DKP] ..
        "," .. row[WHOGETLOOT_KEY_EFFECT_DKP_FLAG] ..
        "," .. row[WHOGETLOOT_KEY_REMARK] .. WHOGETLOOT_MSG_NEW_LINE
  end
  getglobal("whoGetLoot_exportDataExportEdit"):SetText(csvText);
  getglobal("whoGetLoot_exportData"):Show();
end

function whoGetLoot_init_listen_status()
  if (GetNumRaidMembers() > 0) then
    whoGetLoot_start_listen()
  else
    whoGetLoot_stop_listen()
  end
end

function whoGetLoot_update_receiver(dataIndex)
  if (GetNumRaidMembers() > 0) then
    local unitName = UnitName("target")
    for i = 1, GetNumRaidMembers(), 1 do
      local name = UnitName("raid" .. i)
      if (unitName == name) then
        local dataIndex = getglobal(dataIndex):GetText()
        local row = whoGetLoot_row_array[tonumber(dataIndex)]
        local raidMessage = string.format(WHOGETLOOT_MSG_RAID_UPDATE_ROLE_NAME_TEMPLATE, row[WHOGETLOOT_KEY_ROLE_NAME],
          row[WHOGETLOOT_KEY_TIME], row[WHOGETLOOT_KEY_LOOT], name)
        row[WHOGETLOOT_KEY_ROLE_NAME] = name
        whoGetLoot_refresh_row_data()
        SendChatMessage(raidMessage, "RAID")
        break
      end
    end
  end
end

function whoGetLoot_data_add_confirm()
  local lootInfo = whoGetLoot_dataAddLootEditBox:GetText()
  if not (lootInfo == nil or lootInfo == "") then
    local nowTime = whoGetLoot_dataAddTimeContent:GetText()
    local player = whoGetLoot_dataAddNameContent:GetText()
    local dkp = whoGetLoot_dataAddDKPEditBox:GetText()
    local effectDkp = whoGetLoot_dataAddEffectDKPFlagValue:GetText()
    local remark = whoGetLoot_dataAddRemarkEditBox:GetText()

    local rowInfo = {}
    rowInfo[WHOGETLOOT_KEY_TIME] = nowTime
    rowInfo[WHOGETLOOT_KEY_ROLE_NAME] = player
    rowInfo[WHOGETLOOT_KEY_LOOT] = lootInfo
    rowInfo[WHOGETLOOT_KEY_DKP] = 0
    rowInfo[WHOGETLOOT_KEY_EFFECT_DKP_FLAG] = effectDkp
    rowInfo[WHOGETLOOT_KEY_REMARK] = remark
    if not (dkp == nil or dkp == "") then
      rowInfo[WHOGETLOOT_KEY_DKP] = tonumber(dkp)
    end
    table.insert(whoGetLoot_row_array, rowInfo)
    whoGetLoot_refresh_row_data()
  end
  whoGetLoot_dataAdd:Hide()
end

function whoGetLoot_delete_data(dataIndex)
  local dataIndex = tonumber(getglobal(dataIndex):GetText())
  if (dataIndex <= whoGetLoot_row_total) then
    table.remove(whoGetLoot_row_array, dataIndex)
    if ((whoGetLoot_row_total - 1) == (whoGetLoot_current_page_number - 1) * whoGetLoot_current_page_size) then
      if (whoGetLoot_current_page_number > 1) then
        whoGetLoot_current_page_number = whoGetLoot_current_page_number - 1
      end
    end
    whoGetLoot_refresh_row_data()
  end
end

function whoGetLoot_clear_tips_show()
  whoGetLoot_dataClearTips:Show()
end

function whoGetLoot_clear_tips_hide()
  whoGetLoot_dataClearTips:Hide()
end

function whoGetLoot_clear_tips_clear_confirm()
  whoGetLoot_row_data_clear()
  whoGetLoot_dataClearTips:Hide()
end

function whoGetLoot_row_hightLight_show(hightLightName)
  local highlightTexture = getglobal(hightLightName)
  highlightTexture:Show()
end

function whoGetLoot_row_hightLight_hide(hightLightName)
  local highlightTexture = getglobal(hightLightName)
  highlightTexture:Hide()
end

function whoGetLoot_select_tab(tabName)
  for index, value in ipairs(whoGetLoot_tab_name_list) do
    local panel = getglobal(value)
    if tabName == value then
      panel:Show()
    else
      panel:Hide()
    end
  end
end

function whoGetLoot_chock_in()
  if (GetNumRaidMembers() > 0) then
    local numRaidMembers = GetNumRaidMembers()
    local groups = {}
    local detail = {}

    -- 按队伍分组
    for i = 1, numRaidMembers do
      local name, _, subgroup, _, class = GetRaidRosterInfo(i)
      if name and class then
        if not groups[subgroup] then
          groups[subgroup] = {}
        end
        table.insert(groups[subgroup], { name = name, class = class })
      end
    end

    for i = 1, 8 do
      local members = groups[i]
      if members then
        for j = 1, 5 do
          local member = members[j]
          if member then
            table.insert(detail, { name = member.name, class = member.class, status = true })
          else
            table.insert(detail, { name = "", class = "", status = true })
          end
        end
      else
        for j = 1, 5 do
          table.insert(detail, { name = "", class = "", status = true })
        end
      end
    end

    local nowTime = date(WHOGETLOOT_MSG_TIME_FORMATE)
    local rowInfo = {}

    rowInfo[WHOGETLOOT_SETTLEMENT_KEY_TIME] = nowTime
    rowInfo[WHOGETLOOT_SETTLEMENT_KEY_TOTAL] = numRaidMembers
    rowInfo[WHOGETLOOT_SETTLEMENT_KEY_REMARK] = ""
    rowInfo[WHOGETLOOT_SETTLEMENT_KEY_DETAIL] = detail

    table.insert(whoGetLoot_chock_in_row_array, rowInfo)
    whoGetLoot_chock_in_refresh_row_data()

    local raidMessage = string.format(WHOGETLOOT_MSG_CLOCK_IN_TEMPLATE, rowInfo[WHOGETLOOT_SETTLEMENT_KEY_TIME],
      rowInfo[WHOGETLOOT_SETTLEMENT_KEY_TOTAL])
    SendChatMessage(raidMessage, "RAID")
  end
end

function whoGetLoot_chock_in_refresh_row_data()
  whoGetLoot_chock_in_row_total = table.getn(whoGetLoot_chock_in_row_array)
  local startIndex, endIndex
  startIndex = whoGetLoot_chock_in_row_total -
      (whoGetLoot_chock_in_current_page_number - 1) * whoGetLoot_chock_in_current_page_size
  endIndex = whoGetLoot_chock_in_row_total -
      whoGetLoot_chock_in_current_page_number * whoGetLoot_chock_in_current_page_size + 1
  endIndex = (endIndex > 0 and endIndex or 1)

  local row = nil
  local j = 1

  for i = startIndex, endIndex, -1 do
    row = whoGetLoot_chock_in_row_array[i]
    getglobal("ClockInFrameListButton" .. j .. "DataIndex"):SetText(i);
    getglobal("ClockInFrameListButton" .. j .. "Time"):SetText(row[WHOGETLOOT_SETTLEMENT_KEY_TIME]);
    getglobal("ClockInFrameListButton" .. j .. "Total"):SetText(row[WHOGETLOOT_SETTLEMENT_KEY_TOTAL]);
    getglobal("ClockInFrameListButton" .. j .. "Remark"):SetText(row[WHOGETLOOT_SETTLEMENT_KEY_REMARK]);
    getglobal("ClockInFrameListButton" .. j):Show();
    j = j + 1
  end
  if j <= whoGetLoot_chock_in_current_page_size then
    for jj = j, whoGetLoot_chock_in_current_page_size do
      getglobal("ClockInFrameListButton" .. jj):Hide();
    end
  end
  whoGetLoot_chock_in_update_page_message()
  whoGetLoot_raid_detail_table_hide()
end

function whoGetLoot_chock_in_update_page_message()
  local pageInfo = string.format(WHOGETLOOT_LABEL_SETTLEMENT_PAGE_INFO_TEMPLATE, whoGetLoot_chock_in_row_total,
    whoGetLoot_chock_in_current_page_number)
  whoGetLoot_main_clockIn_table_framePageInfo:SetText(pageInfo)
end

function whoGetLoot_chock_in_next_page()
  local currentPageMaxIndex = whoGetLoot_chock_in_current_page_number * whoGetLoot_chock_in_current_page_size
  if currentPageMaxIndex < whoGetLoot_chock_in_row_total then
    whoGetLoot_chock_in_current_page_number = whoGetLoot_chock_in_current_page_number + 1
    whoGetLoot_chock_in_refresh_row_data()
  end
end

function whoGetLoot_chock_in_previous_page()
  if whoGetLoot_chock_in_current_page_number > 1 then
    whoGetLoot_chock_in_current_page_number = whoGetLoot_chock_in_current_page_number - 1
    whoGetLoot_chock_in_refresh_row_data()
  end
end

function whoGetLoot_chock_in_delete_data(dataIndex)
  local dataIndex = tonumber(getglobal(dataIndex):GetText())
  if (dataIndex <= whoGetLoot_chock_in_row_total) then
    table.remove(whoGetLoot_chock_in_row_array, dataIndex)
    if ((whoGetLoot_chock_in_row_total - 1) == (whoGetLoot_chock_in_current_page_number - 1) * whoGetLoot_chock_in_current_page_size) then
      if (whoGetLoot_chock_in_current_page_number > 1) then
        whoGetLoot_chock_in_current_page_number = whoGetLoot_chock_in_current_page_number - 1
      end
    end
    whoGetLoot_chock_in_refresh_row_data()
  end
end

function whoGetLoot_parse_class_color(className)
  local r, g, b = whoGetLoot_classes_color_mapping[className]
  return r, g, b
end

function whoGetLoot_raid_detail_table_hide()
  local hightLight = getglobal("ClockInFrameListButton" ..
    whoGetLoot_raid_table_hightlight_selected_index .. "RowHightlight")
  if hightLight then
    whoGetLoot_raid_table_hightlight_selected_index = WHOGETLOOT_HIGHTLIGHT_DEFAULT_INDEX
    hightLight:Hide()
    for i = 1, 40, 1 do
      local lable = getglobal("PartyFrameData" .. i)
      lable:SetText("")
    end
  end
end

function whoGetLoot_raid_detail_table_toggle(hightLightId, dataIdTextName)
  if whoGetLoot_raid_table_hightlight_selected_index == hightLightId then
    whoGetLoot_raid_detail_table_hide()
  else
    local oldHightLight = getglobal("ClockInFrameListButton" ..
      whoGetLoot_raid_table_hightlight_selected_index .. "RowHightlight")
    local newHightLight = getglobal("ClockInFrameListButton" .. hightLightId .. "RowHightlight")
    if oldHightLight then
      oldHightLight:Hide()
    end
    whoGetLoot_raid_table_hightlight_selected_index = hightLightId
    if newHightLight then
      newHightLight:Show()
      local dataId = getglobal(dataIdTextName):GetText()
      local row = whoGetLoot_chock_in_row_array[tonumber(dataId)]
      local detail = row[WHOGETLOOT_SETTLEMENT_KEY_DETAIL]
      for index, value in ipairs(detail) do
        local lable = getglobal("PartyFrameData" .. index)
        if value.name ~= "" and value.class ~= "" then
          if value.status ~= true then
            lable:SetText(value.name)
            lable:SetTextColor(1.0, 0, 0)
          else
            local color = whoGetLoot_parse_class_color(value.class)
            lable:SetText(value.name)
            lable:SetTextColor(color.r, color.g, color.b)
          end
        else
          lable:SetText("")
        end
      end
    end
  end
end

function whoGetLoot_radio_button_from_view_selected(anotherButtonName, thisButtonName, valueName, value)
  local anotherButton = getglobal(anotherButtonName)
  local thisButton = getglobal(thisButtonName)
  local valueText = getglobal(valueName)
  anotherButton:SetChecked(false)
  thisButton:SetChecked(true)
  valueText:SetText(value)
end

function whoGetLoot_radio_button_from_data_selected(yesButtonName, noButtonName, valueName, value)
  local yesButton = getglobal(yesButtonName)
  local noButton = getglobal(noButtonName)
  local valueText = getglobal(valueName)
  if value == WHOGETLOOT_BUTTON_YES then
    yesButton:SetChecked(true)
    noButton:SetChecked(false)
  else
    yesButton:SetChecked(false)
    noButton:SetChecked(true)
  end
  valueText:SetText(value)
end

function whoGetLoot_clock_in_remark_open_frame(dataIndex)
  if not whoGetLoot_clockInRemarkAdd:IsVisible() then
    local dataIndex = getglobal(dataIndex):GetText()
    local row = whoGetLoot_chock_in_row_array[tonumber(dataIndex)]
    whoGetLoot_clockInRemarkAddDataIndex:SetText(dataIndex)
    whoGetLoot_clockInRemarkAddTimeContent:SetText(row[WHOGETLOOT_SETTLEMENT_KEY_TIME])
    whoGetLoot_clockInRemarkAddTotalContent:SetText(row[WHOGETLOOT_SETTLEMENT_KEY_TOTAL])
    whoGetLoot_clockInRemarkAddRemarkEditBox:SetText(row[WHOGETLOOT_SETTLEMENT_KEY_REMARK])
    whoGetLoot_clockInRemarkAdd:Show()
  end
end

function whoGetLoot_clock_in_remark_add_confirm()
  local rowIndex = whoGetLoot_clockInRemarkAddDataIndex:GetText()
  local remark = whoGetLoot_clockInRemarkAddRemarkEditBox:GetText()
  local row = whoGetLoot_chock_in_row_array[tonumber(rowIndex)]
  row[WHOGETLOOT_SETTLEMENT_KEY_REMARK] = remark
  whoGetLoot_chock_in_refresh_row_data()
  whoGetLoot_clockInRemarkAdd:Hide()
end

function whoGetLoot_export_clock_in_data()
  local clockInHeader = WHOGETLOOT_BUTTON_HEADER_TIME ..
      "," .. WHOGETLOOT_BUTTON_TOTAL ..
      "," .. WHOGETLOOT_BUTTON_HEADER_SETTLEMENT_REMARK .. WHOGETLOOT_MSG_NEW_LINE

  local exportData = ""

  for i = 1, whoGetLoot_chock_in_row_total do
    local row = whoGetLoot_chock_in_row_array[i]
    exportData = exportData .. clockInHeader ..
        row[WHOGETLOOT_SETTLEMENT_KEY_TIME] ..
        "," .. row[WHOGETLOOT_SETTLEMENT_KEY_TOTAL] ..
        "," .. row[WHOGETLOOT_SETTLEMENT_KEY_REMARK] .. WHOGETLOOT_MSG_NEW_LINE
        .. WHOGETLOOT_BUTTON_EXPORT_DETAIL_TITLE .. WHOGETLOOT_MSG_NEW_LINE
    local detailArray = row[WHOGETLOOT_SETTLEMENT_KEY_DETAIL]
    for _, value in ipairs(detailArray) do
      if value.name ~= "" and value.class ~= "" then
        local statusText = WHOGETLOOT_MSG_CLOCK_IN_STATUS_NORMAL
        if value.status ~= true then
          statusText = WHOGETLOOT_MSG_CLOCK_IN_STATUS_ABSENTL
        end
        exportData = exportData .. value.name .. "," .. value.class .. "," .. statusText .. WHOGETLOOT_MSG_NEW_LINE
      end
    end
    exportData = exportData .. WHOGETLOOT_MSG_NEW_LINE
  end
  getglobal("whoGetLoot_exportDataExportEdit"):SetText(exportData);
  getglobal("whoGetLoot_exportData"):Show();
end

function whoGetLoot_export_settlement_data()
  if whoGetLoot_chock_in_row_total > 0 then
    local item_2_array = {}
    local item_3_array = {}
    local item_4_array = {}
    -- absence people
    local item_5_array = {}


    local result = {}
    local uniqueSet = {}
    for i = 1, whoGetLoot_chock_in_row_total do
      local row = whoGetLoot_chock_in_row_array[i]
      local detailArray = row[WHOGETLOOT_SETTLEMENT_KEY_DETAIL]
      for _, value in ipairs(detailArray) do
        if value.name ~= "" and value.class ~= "" then
          if uniqueSet[value.name] then
            if value.status == true then
              uniqueSet[value.name] = uniqueSet[value.name] + 1
            end
          else
            table.insert(result, value)
            if value.status == true then
              uniqueSet[value.name] = 1
            else
              uniqueSet[value.name] = 0
            end
          end
        end
      end
    end

    for _, value in ipairs(result) do
      if uniqueSet[value.name] ~= whoGetLoot_chock_in_row_total then
        local remark = string.format(WHOGETLOOT_LABEL_SELLEMENT_ITEM_TEMPLATE_4_REMARK_1, whoGetLoot_chock_in_row_total,
          uniqueSet[value.name])
        table.insert(item_5_array, { name = value.name, class = value.class, remark = remark })
      else
        local notEffectDkpLoot = {}
        local getEffectLootFlag = false
        for _, lootLog in ipairs(whoGetLoot_row_array) do
          if lootLog[WHOGETLOOT_KEY_ROLE_NAME] == value.name then
            if lootLog[WHOGETLOOT_KEY_EFFECT_DKP_FLAG] == WHOGETLOOT_BUTTON_YES then
              if getEffectLootFlag == false then
                getEffectLootFlag = true
                local remark = string.format(WHOGETLOOT_LABEL_SELLEMENT_ITEM_TEMPLATE_4_REMARK_2,
                  lootLog[WHOGETLOOT_KEY_LOOT])
                table.insert(item_4_array, { name = value.name, class = value.class, remark = remark })
              end
            else
              table.insert(notEffectDkpLoot, lootLog[WHOGETLOOT_KEY_LOOT])
            end
          end
        end

        local notEffectLootSize = table.getn(notEffectDkpLoot)
        if getEffectLootFlag == false then
          if notEffectLootSize > 0 then
            local tempStr = ""
            for _, lootName in ipairs(notEffectDkpLoot) do
              tempStr = tempStr .. lootName .. ","
            end
            local remark = string.format(WHOGETLOOT_LABEL_SELLEMENT_ITEM_TEMPLATE_3_REMARK_1, tempStr)
            table.insert(item_3_array, { name = value.name, class = value.class, remark = remark })
          else
            table.insert(item_2_array, { name = value.name, class = value.class, remark = "" })
          end
        end
      end
    end

    for _, value in ipairs(item_5_array) do
      local getEffectLootFlag = false
      for _, lootLog in ipairs(whoGetLoot_row_array) do
        if lootLog[WHOGETLOOT_KEY_ROLE_NAME] == value.name then
          if lootLog[WHOGETLOOT_KEY_EFFECT_DKP_FLAG] == WHOGETLOOT_BUTTON_YES then
            if getEffectLootFlag == false then
              getEffectLootFlag = true
              value.remark = value.remark .. "," .. string.format(WHOGETLOOT_LABEL_SELLEMENT_ITEM_TEMPLATE_4_REMARK_2,
                lootLog[WHOGETLOOT_KEY_LOOT])
              break
            end
          end
        end
      end
      if not getEffectLootFlag then
        value.remark = value.remark .. "," .. WHOGETLOOT_LABEL_SELLEMENT_ITEM_TEMPLATE_4_REMARK_3
      end
      table.insert(item_4_array, { name = value.name, class = value.class, remark = value.remark })
    end


    local totalPersonNum = table.getn(result)
    local item_2_personNum = 0
    local item_3_personNum = 0
    local item_4_personNum = 0


    local item_2_detail_data = ""
    local item_3_detail_data = ""
    local item_4_detail_data = ""


    for _, value in ipairs(item_2_array) do
      item_2_detail_data = item_2_detail_data ..
          value.name .. "," .. value.class .. "," .. value.remark .. WHOGETLOOT_MSG_NEW_LINE
      item_2_personNum = item_2_personNum + 1
    end

    for _, value in ipairs(item_3_array) do
      item_3_detail_data = item_3_detail_data ..
          value.name .. "," .. value.class .. "," .. value.remark .. WHOGETLOOT_MSG_NEW_LINE
      item_3_personNum = item_3_personNum + 1
    end

    for _, value in ipairs(item_4_array) do
      item_4_detail_data = item_4_detail_data ..
          value.name .. "," .. value.class .. "," .. value.remark .. WHOGETLOOT_MSG_NEW_LINE
      item_4_personNum = item_4_personNum + 1
    end


    local item_1 = string.format(WHOGETLOOT_LABEL_SELLEMENT_ITEM_TEMPLATE_1, totalPersonNum)
    local item_2 = string.format(WHOGETLOOT_LABEL_SELLEMENT_ITEM_TEMPLATE_2, item_2_personNum)
    local item_3 = string.format(WHOGETLOOT_LABEL_SELLEMENT_ITEM_TEMPLATE_3, item_3_personNum)
    local item_4 = string.format(WHOGETLOOT_LABEL_SELLEMENT_ITEM_TEMPLATE_4, item_4_personNum)

    local exportData = item_1 .. WHOGETLOOT_MSG_NEW_LINE
        .. item_2 .. WHOGETLOOT_MSG_NEW_LINE

    if item_2_personNum > 0 then
      exportData = exportData
          .. WHOGETLOOT_BUTTON_EXPORT_DETAIL_TITLE .. WHOGETLOOT_MSG_NEW_LINE
          ..
          WHOGETLOOT_BUTTON_HEADER_NAME ..
          "," ..
          WHOGETLOOT_BUTTON_HEADER_CLASS ..
          "," .. WHOGETLOOT_BUTTON_HEADER_SELLEMENT_EXPORT_REMARK .. WHOGETLOOT_MSG_NEW_LINE
          .. item_2_detail_data .. WHOGETLOOT_MSG_NEW_LINE
    end

    exportData = exportData .. item_3 .. WHOGETLOOT_MSG_NEW_LINE
    if item_3_personNum > 0 then
      exportData = exportData
          .. WHOGETLOOT_BUTTON_EXPORT_DETAIL_TITLE .. WHOGETLOOT_MSG_NEW_LINE
          ..
          WHOGETLOOT_BUTTON_HEADER_NAME ..
          "," ..
          WHOGETLOOT_BUTTON_HEADER_CLASS ..
          "," .. WHOGETLOOT_BUTTON_HEADER_SELLEMENT_EXPORT_REMARK .. WHOGETLOOT_MSG_NEW_LINE
          .. item_3_detail_data .. WHOGETLOOT_MSG_NEW_LINE
    end

    exportData = exportData .. item_4 .. WHOGETLOOT_MSG_NEW_LINE
    if item_4_personNum > 0 then
      exportData = exportData
          .. WHOGETLOOT_BUTTON_EXPORT_DETAIL_TITLE .. WHOGETLOOT_MSG_NEW_LINE
          ..
          WHOGETLOOT_BUTTON_HEADER_NAME ..
          "," ..
          WHOGETLOOT_BUTTON_HEADER_CLASS ..
          "," .. WHOGETLOOT_BUTTON_HEADER_SELLEMENT_EXPORT_REMARK .. WHOGETLOOT_MSG_NEW_LINE
          .. item_4_detail_data .. WHOGETLOOT_MSG_NEW_LINE
    end

    getglobal("whoGetLoot_exportDataExportEdit"):SetText(exportData);
    getglobal("whoGetLoot_exportData"):Show();
  end
end

function whoGetLoot_clock_in_player_status_toggle(buttonId)
  if whoGetLoot_raid_table_hightlight_selected_index > 0 then
    local detailBUtton = getglobal("PartyFrameData" .. buttonId)
    if detailBUtton:GetText() ~= "" and detailBUtton:GetText() ~= nil then
      local hightLightId = whoGetLoot_raid_table_hightlight_selected_index
      local dataIdTextName = "ClockInFrameListButton" .. hightLightId .. "DataIndex"
      local dataIdText = getglobal(dataIdTextName):GetText()
      local row = whoGetLoot_chock_in_row_array[tonumber(dataIdText)]
      local detailArray = row[WHOGETLOOT_SETTLEMENT_KEY_DETAIL]
      local person = detailArray[tonumber(buttonId)]
      local statusText = WHOGETLOOT_MSG_CLOCK_IN_STATUS_NORMAL
      if person.status == true then
        person.status = false
        statusText = WHOGETLOOT_MSG_CLOCK_IN_STATUS_ABSENTL
        detailBUtton:SetTextColor(1.0, 0, 0)
      else
        person.status = true
        local color = whoGetLoot_parse_class_color(person.class)
        detailBUtton:SetTextColor(color.r, color.g, color.b)
      end
      local raidMessage = string.format(WHOGETLOOT_MSG_CLOCK_IN_STATUS_TEMPLATE, row[WHOGETLOOT_SETTLEMENT_KEY_TIME],
        person.name, statusText)
      SendChatMessage(raidMessage, "RAID")
    end
  end
end

function whoGetLoot_clock_in_clear()
  whoGetLoot_chock_in_row_array = {}
  whoGetLoot_chock_in_row_total = 0
  whoGetLoot_chock_in_current_page_number = 1
  whoGetLoot_chock_in_refresh_row_data()
  if whoGetLoot_clockInRemarkAdd:IsVisible() then
    whoGetLoot_clockInRemarkAdd:Hide()
  end
end

function whoGetLoot_init_import_dkp()
  local importData = ""
  if whoGetLoot_import_dkp_data_array then
    for index in whoGetLoot_import_dkp_data_array do
      local item = whoGetLoot_import_dkp_data_array[index]
      importData = importData ..
          item[WHOGETLOOT_KEY_ROLE_NAME] .. "," .. item[WHOGETLOOT_KEY_DKP] .. WHOGETLOOT_MSG_NEW_LINE
    end
    local dataFrame = getglobal("whoGetLoot_importDkpImportEdit")
    dataFrame:SetText(importData)
  end
  local mappingData = ""
  if whoGetLoot_import_dkp_data_role_name_mapping_array then
    for index in whoGetLoot_import_dkp_data_role_name_mapping_array do
      local item = whoGetLoot_import_dkp_data_role_name_mapping_array[index]
      mappingData = mappingData ..
          item[WHOGETLOOT_INCLUDE_DKP_ROLE_NAME_MAPPING_NICKNAME_KEY] .. "," .. item[WHOGETLOOT_INCLUDE_DKP_ROLE_NAME_MAPPING_REALNAME_KEY] .. WHOGETLOOT_MSG_NEW_LINE
    end
    local dataFrame = getglobal("whoGetLoot_importDkpImportRoleNameMappingEdit")
    dataFrame:SetText(mappingData)
  end
  local defaultDkp = getglobal("whoGetLoot_importDkpDefaultDKPEditBox")
  defaultDkp:SetText(whoGetLoot_default_dkp)
  local includeDefaultDkp = getglobal("whoGetLoot_importDkpEnableIncludDefaultDKP")
  if whoGetLoot_import_includ_default_dkp_flag == nil then
    whoGetLoot_import_includ_default_dkp_flag = false
  end
  includeDefaultDkp:SetChecked(whoGetLoot_import_includ_default_dkp_flag)

end

function whoGetLoot_import_dkp_toggle()
  local importFrame = getglobal("whoGetLoot_importDkp")
  if importFrame:IsVisible() then
    importFrame:Hide()
  else
    importFrame:Show()
  end
end

function whoGetLoot_import_dkp_comfirm()
  local importFrame = getglobal("whoGetLoot_importDkp")
  local dataFrame = getglobal("whoGetLoot_importDkpImportEdit")
  local mappingFrame = getglobal("whoGetLoot_importDkpImportRoleNameMappingEdit")
  local data = dataFrame:GetText()
  local mappingData = mappingFrame:GetText()
  -- init data
  whoGetLoot_import_dkp_data_array = {}
  whoGetLoot_import_dkp_data_role_name_mapping_array = {}
  
  if mappingData then
    local mappingArray = string.gmatch(mappingData, "[^\n]+")
    if mappingArray then
      for line in mappingArray do
        local nickname, realname = string.match(line, "(.-),(.*)")
        local mapping = {}
        mapping[WHOGETLOOT_INCLUDE_DKP_ROLE_NAME_MAPPING_NICKNAME_KEY] = nickname
        mapping[WHOGETLOOT_INCLUDE_DKP_ROLE_NAME_MAPPING_REALNAME_KEY] = realname
        if nickname and  nickname ~= "" and realname and realname ~= "" then
          table.insert(whoGetLoot_import_dkp_data_role_name_mapping_array, mapping)
        end
      end
    end
  end

  if data then
    local lineArray = string.gmatch(data, "[^\n]+")
    if lineArray then
      for line in lineArray do
        local roleName, dkp = string.match(line, "(.-),(.*)")
        local numDkp = tonumber(dkp)
        local rowInfo = {}
        rowInfo[WHOGETLOOT_KEY_ROLE_NAME] = roleName
        rowInfo[WHOGETLOOT_KEY_DKP] = numDkp
        if roleName and  roleName ~= "" and numDkp and numDkp ~= "" then
          if whoGetLoot_import_dkp_data_role_name_mapping_array then
            for mapping in whoGetLoot_import_dkp_data_role_name_mapping_array do
              local item = whoGetLoot_import_dkp_data_role_name_mapping_array[mapping]
              if roleName == item[WHOGETLOOT_INCLUDE_DKP_ROLE_NAME_MAPPING_NICKNAME_KEY] then
                rowInfo[WHOGETLOOT_KEY_ROLE_NAME] = item[WHOGETLOOT_INCLUDE_DKP_ROLE_NAME_MAPPING_REALNAME_KEY]
              end
            end
          end
          table.insert(whoGetLoot_import_dkp_data_array, rowInfo)
        end
      end
    end
  end
  local defaultDkp = getglobal("whoGetLoot_importDkpDefaultDKPEditBox")
  whoGetLoot_default_dkp = tonumber(defaultDkp:GetText())
  local nowTime = date(WHOGETLOOT_MSG_TIME_FORMATE)
  whoGetLoot_import_dkp_time = nowTime
  -- SendChatMessage(WHOGETLOOT_WHISPER_QUERY_ANNOUNCE, "RAID")
  importFrame:Hide()
end

function whoGetLoot_popup_menu_onLoad()
  if UnitPopupMenus["PARTY"] then
    if not whoGetLoot_contain(WHOGETLOOT_POPUP_MENU_GET_LOOT_KEY, UnitPopupMenus["PARTY"]) then
      table.insert(UnitPopupMenus["PARTY"], WHOGETLOOT_POPUP_MENU_GET_LOOT_KEY)
    end
  end
  if UnitPopupMenus["RAID"] then
    if not whoGetLoot_contain(WHOGETLOOT_POPUP_MENU_GET_LOOT_KEY, UnitPopupMenus["RAID"]) then
      table.insert(UnitPopupMenus["RAID"], WHOGETLOOT_POPUP_MENU_GET_LOOT_KEY)
    end
  end
  if UnitPopupMenus["PLAYER"] then
    if not whoGetLoot_contain(WHOGETLOOT_POPUP_MENU_GET_LOOT_KEY, UnitPopupMenus["PLAYER"]) then
      table.insert(UnitPopupMenus["PLAYER"], WHOGETLOOT_POPUP_MENU_GET_LOOT_KEY)
    end
  end
  if UnitPopupMenus["FRIEND"] then
    if not whoGetLoot_contain(WHOGETLOOT_POPUP_MENU_GET_LOOT_KEY, UnitPopupMenus["FRIEND"]) then
      table.insert(UnitPopupMenus["FRIEND"], WHOGETLOOT_POPUP_MENU_GET_LOOT_KEY)
    end
  end
end

function whoGetLoot_popup_menu_handle()
  local dropdownFrame = getglobal(UIDROPDOWNMENU_INIT_MENU);
  local button = this.value;
  local roleName = dropdownFrame.name;

  if (button == WHOGETLOOT_POPUP_MENU_GET_LOOT_KEY) then
    local message = whoGetLoot_query_loot_record(roleName)
    SendChatMessage(message, "RAID")
  else
    return whoGetLoot_original_unitpopup();
  end
end

function whoGetLoot_query_loot_record(roleName)
  local message = ""
  local defaultDkp = whoGetLoot_default_dkp
  local extarDkp = 0

  if whoGetLoot_import_dkp_data_array then
    local findDkp
    for i in whoGetLoot_import_dkp_data_array do
      local item = whoGetLoot_import_dkp_data_array[i]
      if item[WHOGETLOOT_KEY_ROLE_NAME] == roleName then
        findDkp = item[WHOGETLOOT_KEY_DKP]
      end
    end
    if findDkp then
      if whoGetLoot_import_includ_default_dkp_flag then
        extarDkp = findDkp - defaultDkp
      else
        extarDkp = findDkp
      end
    end
  end

  local totalDkp = defaultDkp + extarDkp
  local consumedDkp = 0
  local consumedLootName = ""
  local subMessage = ""
  if whoGetLoot_row_array then
    for i in whoGetLoot_row_array do
      local item = whoGetLoot_row_array[i]
      local getLootPlayerName = item[WHOGETLOOT_KEY_ROLE_NAME]
      if getLootPlayerName == roleName and item[WHOGETLOOT_KEY_DKP] > 0 then
        consumedDkp = consumedDkp + item[WHOGETLOOT_KEY_DKP]
        consumedLootName = consumedLootName .. item[WHOGETLOOT_KEY_LOOT] .. ","
      end
    end
  end

  totalDkp = totalDkp - consumedDkp

  if consumedLootName ~= "" then
    subMessage = string.format(WHOGETLOOT_MSG_QUERY_LOOTED, consumedLootName)
  else
    subMessage = WHOGETLOOT_MSG_QUERY_NOT_LOOT
  end

  message = string.format(WHOGETLOOT_MSG_QUERY_LOOT_MESSAGE, roleName, subMessage, defaultDkp, extarDkp, consumedDkp,
    totalDkp, whoGetLoot_import_dkp_time)
  return message
end

function whoGetLoot_contain(v, l)
  if not l then
    return false
  end
  local n = getn(l)
  if n > 0 then
    for i = 1, n do
      local lv = l[i]
      if v == lv then
        return true
      end
    end
  end
  return false
end

function whoGetLoot_whisper_handle(msg, playerName)
  if msg == WHOGETLOOT_WHISPER_QUERY_DKP_KEY_1 or msg == WHOGETLOOT_WHISPER_QUERY_DKP_KEY_2 then
    local mesaage = whoGetLoot_query_loot_record(playerName)
    SendChatMessage(mesaage, "WHISPER", GetDefaultLanguage(), playerName)
  end
end

function whoGetLoot_import_data_includ_default_dkp_toggle(checked)
  whoGetLoot_import_includ_default_dkp_flag = checked
end

function whoGetLoot_import_data_role_name_check_tips()
  if (GetNumRaidMembers() > 0) then
    local tipsMessage = ""
    for i = 1, GetNumRaidMembers(), 1 do
      local realRoleName = UnitName("raid" .. i)
      local findFlag = false

      if whoGetLoot_import_dkp_data_array then
        for importIndex in whoGetLoot_import_dkp_data_array do
          local importItem = whoGetLoot_import_dkp_data_array[importIndex]
          if realRoleName == importItem[WHOGETLOOT_KEY_ROLE_NAME] then
            findFlag = true
          end
        end
      end

      if whoGetLoot_import_dkp_data_role_name_mapping_array then
        for importIndex in whoGetLoot_import_dkp_data_role_name_mapping_array do
          local importItem = whoGetLoot_import_dkp_data_role_name_mapping_array[importIndex]
          if realRoleName == importItem[WHOGETLOOT_INCLUDE_DKP_ROLE_NAME_MAPPING_REALNAME_KEY] then
            findFlag = true
          end
        end
      end

      if not findFlag then
        tipsMessage = tipsMessage .. realRoleName .. ","
      end
    end

    if tipsMessage ~= "" then
      tipsMessage = WHOGETLOOT_IMPORT_ROLENAME_CHECK_TIPS_TEXT_1 .. tipsMessage
      print(tipsMessage)
    else 
      print(WHOGETLOOT_IMPORT_ROLENAME_CHECK_TIPS_TEXT_2)
      SendChatMessage(WHOGETLOOT_WHISPER_QUERY_ANNOUNCE, "RAID")
    end
  end
end