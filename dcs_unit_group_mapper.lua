-- DCS World Unit and Group ID to Name Mapper
-- Updates DCS log every 3 seconds with unit/group mappings as XML

local updateInterval = 3 -- seconds
local DEBUG = true -- Set to false to disable debug messages

-- Persistent tables to store all units and groups encountered during the mission
local allUnits = {}
local allGroups = {}
local lastUpdateTime = 0

-- Function to output debug messages to both outMessage and log
local function debugMsg(message)
    if DEBUG then
        local missionTime = timer.getAbsTime()
        local hours = math.floor(missionTime / 3600)
        local minutes = math.floor((missionTime % 3600) / 60)
        local seconds = math.floor(missionTime % 60)
        local timestamp = string.format("%02d:%02d:%02d", hours, minutes, seconds)
        local formattedMsg = "[DCS Mapper " .. timestamp .. "] " .. message
        
        -- Output to player message
        trigger.action.outText(formattedMsg, 10)
        
        -- Output to log file
        env.info(formattedMsg)
    end
end

-- Function to escape XML special characters
local function escapeXML(str)
    if not str then return "" end
    str = tostring(str)
    str = string.gsub(str, "&", "&amp;")
    str = string.gsub(str, "<", "&lt;")
    str = string.gsub(str, ">", "&gt;")
    str = string.gsub(str, '"', "&quot;")
    str = string.gsub(str, "'", "&apos;")
    return str
end

-- Function to get all units and groups data and accumulate in persistent tables
local function getUnitsAndGroups()
    local currentTime = timer.getAbsTime()
    local currentUnits = {}
    local currentGroups = {}
    local newUnitsCount = 0
    local newGroupsCount = 0
    
    -- Get all coalitions
    local coalitions = {coalition.side.RED, coalition.side.BLUE, coalition.side.NEUTRAL}
    
    for _, coalitionSide in ipairs(coalitions) do
        -- Get all groups for this coalition
        local groups = coalition.getGroups(coalitionSide)
        
        for _, group in ipairs(groups) do
            if group and group:isExist() then
                local groupId = group:getID()  -- Groups use getID(), not getObjectID()
                local groupName = group:getName()
                local groupCategory = group:getCategory()
                
                -- Mark this group as currently active
                currentGroups[groupId] = true
                
                -- Add or update group in persistent table
                if not allGroups[groupId] then
                    allGroups[groupId] = {
                        name = groupName,
                        category = groupCategory,
                        coalition = coalitionSide,
                        firstSeen = currentTime,
                        lastSeen = currentTime,
                        active = true
                    }
                    newGroupsCount = newGroupsCount + 1
                else
                    -- Update existing group
                    allGroups[groupId].lastSeen = currentTime
                    allGroups[groupId].active = true
                end
                
                -- Get all units in this group
                local units = group:getUnits()
                for _, unit in ipairs(units) do
                    if unit and unit:isExist() then
                        local unitObjectId = unit:getObjectID()  -- Units use getObjectID()
                        local unitName = unit:getName()
                        local unitType = unit:getTypeName()
                        
                        -- Check if unit is controlled by a player
                        local playerName = unit:getPlayerName()
                        local displayName = unitName  -- Default to unit name
                        local isPlayerControlled = false
                        
                        if playerName then
                            displayName = playerName  -- Use player name if available
                            isPlayerControlled = true
                        end
                        
                        -- Mark this unit as currently active
                        currentUnits[unitObjectId] = true
                        
                        -- Add or update unit in persistent table
                        if not allUnits[unitObjectId] then
                            allUnits[unitObjectId] = {
                                name = unitName,  -- Keep original unit name
                                displayName = displayName,  -- Player name or unit name
                                playerName = playerName,  -- Player name (nil if AI)
                                isPlayerControlled = isPlayerControlled,
                                type = unitType,
                                groupId = groupId,  -- Reference to group ID
                                groupName = groupName,
                                coalition = coalitionSide,
                                firstSeen = currentTime,
                                lastSeen = currentTime,
                                active = true
                            }
                            newUnitsCount = newUnitsCount + 1
                        else
                            -- Update existing unit
                            allUnits[unitObjectId].lastSeen = currentTime
                            allUnits[unitObjectId].active = true
                            -- Update player control status (players can take control or leave)
                            allUnits[unitObjectId].playerName = playerName
                            allUnits[unitObjectId].isPlayerControlled = isPlayerControlled
                            allUnits[unitObjectId].displayName = displayName
                        end
                    end
                end
            end
        end
    end
    
    -- Mark units and groups that are no longer active
    for unitObjectId, unitData in pairs(allUnits) do
        if not currentUnits[unitObjectId] then
            unitData.active = false
        end
    end
    
    for groupId, groupData in pairs(allGroups) do
        if not currentGroups[groupId] then
            groupData.active = false
        end
    end
    
    local totalGroups = 0
    local activeGroups = 0
    for _, _ in pairs(allGroups) do
        totalGroups = totalGroups + 1
    end
    for _, groupData in pairs(allGroups) do
        if groupData.active then
            activeGroups = activeGroups + 1
        end
    end
    
    local totalUnits = 0
    local activeUnits = 0
    for _, _ in pairs(allUnits) do
        totalUnits = totalUnits + 1
    end
    for _, unitData in pairs(allUnits) do
        if unitData.active then
            activeUnits = activeUnits + 1
        end
    end
    
    if newGroupsCount > 0 or newUnitsCount > 0 then
        debugMsg("New discoveries: " .. newGroupsCount .. " groups, " .. newUnitsCount .. " units")
    end
    
    lastUpdateTime = currentTime
    
    return {
        units = allUnits,
        groups = allGroups
    }
end

-- Function to write XML to file
local function writeXMLFile(data)
    local missionTime = timer.getAbsTime()
    local totalSeconds = math.floor(missionTime)
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    local timestamp = string.format("Mission Time %02d:%02d:%02d", hours, minutes, seconds)
    
    local xml = '<?xml version="1.0" encoding="UTF-8"?>\n'
    xml = xml .. '<dcs_mapping timestamp="' .. escapeXML(timestamp) .. '" mission_time="' .. escapeXML(missionTime) .. '">\n'
    
    -- Write groups section
    xml = xml .. '  <groups>\n'
    local groupCount = 0
    local activeGroupCount = 0
    for groupId, groupData in pairs(data.groups) do
        xml = xml .. '    <group id="' .. escapeXML(groupId) .. '" '
        xml = xml .. 'name="' .. escapeXML(groupData.name) .. '" '
        xml = xml .. 'category="' .. escapeXML(groupData.category) .. '" '
        xml = xml .. 'coalition="' .. escapeXML(groupData.coalition) .. '" '
        xml = xml .. 'first_seen="' .. escapeXML(groupData.firstSeen) .. '" '
        xml = xml .. 'last_seen="' .. escapeXML(groupData.lastSeen) .. '" '
        xml = xml .. 'active="' .. escapeXML(tostring(groupData.active)) .. '"/>\n'
        groupCount = groupCount + 1
        if groupData.active then
            activeGroupCount = activeGroupCount + 1
        end
    end
    xml = xml .. '  </groups>\n'
    
    -- Write units section
    xml = xml .. '  <units>\n'
    local unitCount = 0
    local activeUnitCount = 0
    for unitObjectId, unitData in pairs(data.units) do
        xml = xml .. '    <unit id="' .. escapeXML(unitObjectId) .. '" '
        xml = xml .. 'name="' .. escapeXML(unitData.name) .. '" '
        xml = xml .. 'display_name="' .. escapeXML(unitData.displayName) .. '" '
        if unitData.playerName then
            xml = xml .. 'player_name="' .. escapeXML(unitData.playerName) .. '" '
        end
        xml = xml .. 'is_player_controlled="' .. escapeXML(tostring(unitData.isPlayerControlled)) .. '" '
        xml = xml .. 'type="' .. escapeXML(unitData.type) .. '" '
        xml = xml .. 'group_id="' .. escapeXML(unitData.groupId) .. '" '
        xml = xml .. 'group_name="' .. escapeXML(unitData.groupName) .. '" '
        xml = xml .. 'coalition="' .. escapeXML(unitData.coalition) .. '" '
        xml = xml .. 'first_seen="' .. escapeXML(unitData.firstSeen) .. '" '
        xml = xml .. 'last_seen="' .. escapeXML(unitData.lastSeen) .. '" '
        xml = xml .. 'active="' .. escapeXML(tostring(unitData.active)) .. '"/>\n'
        unitCount = unitCount + 1
        if unitData.active then
            activeUnitCount = activeUnitCount + 1
        end
    end
    xml = xml .. '  </units>\n'
    
    xml = xml .. '</dcs_mapping>\n'
    
    debugMsg("XML logged: " .. groupCount .. " groups (" .. activeGroupCount .. " active), " .. 
             unitCount .. " units (" .. activeUnitCount .. " active)")
    
    -- Output XML to DCS log with special markers for external parsing
    env.info("=== DCS_MAPPER_XML_START ===")
    env.info(xml)
    env.info("=== DCS_MAPPER_XML_END ===")
end

-- Main update function
local function updateMapping()
    local success, result = pcall(function()
        local data = getUnitsAndGroups()
        writeXMLFile(data)
    end)
    
    if not success then
        local errorMsg = "Error updating unit/group mapping: " .. tostring(result)
        debugMsg("ERROR: " .. errorMsg)
        env.error(errorMsg)
    end
end

-- Initial update
debugMsg("DCS Mapper starting...")
updateMapping()

-- Schedule periodic updates
timer.scheduleFunction(function()
    updateMapping()
    return timer.getTime() + updateInterval
end, nil, timer.getTime() + updateInterval)

debugMsg("DCS Mapper running (interval: " .. updateInterval .. "s)")
env.info("DCS Unit/Group ID Mapper started. Logging to DCS log with XML markers") 