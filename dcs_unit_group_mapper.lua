-- DCS World Unit and Group ID to Name Mapper
-- Updates DCS log every 3 seconds with unit/group mappings as XML

local updateInterval = 3 -- seconds
local DEBUG = true -- Set to false to disable debug messages

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

-- Function to get all units and groups data
local function getUnitsAndGroups()
    debugMsg("Starting data collection...")
    
    local data = {
        units = {},
        groups = {}
    }
    
    local totalGroups = 0
    local totalUnits = 0
    
    -- Get all coalitions
    local coalitions = {coalition.side.RED, coalition.side.BLUE, coalition.side.NEUTRAL}
    
    for _, coalitionSide in ipairs(coalitions) do
        local coalitionName = (coalitionSide == coalition.side.RED and "RED") or 
                             (coalitionSide == coalition.side.BLUE and "BLUE") or "NEUTRAL"
        debugMsg("Processing " .. coalitionName .. " coalition...")
        
        -- Get all groups for this coalition
        local groups = coalition.getGroups(coalitionSide)
        local coalitionGroups = 0
        local coalitionUnits = 0
        
        for _, group in ipairs(groups) do
            if group and group:isExist() then
                local groupId = group:getID()
                local groupName = group:getName()
                local groupCategory = group:getCategory()
                
                -- Store group data
                data.groups[groupId] = {
                    name = groupName,
                    category = groupCategory,
                    coalition = coalitionSide
                }
                coalitionGroups = coalitionGroups + 1
                
                -- Get all units in this group
                local units = group:getUnits()
                for _, unit in ipairs(units) do
                    if unit and unit:isExist() then
                        local unitId = unit:getID()
                        local unitName = unit:getName()
                        local unitType = unit:getTypeName()
                        
                        -- Store unit data
                        data.units[unitId] = {
                            name = unitName,
                            type = unitType,
                            groupId = groupId,
                            groupName = groupName,
                            coalition = coalitionSide
                        }
                        coalitionUnits = coalitionUnits + 1
                    end
                end
            end
        end
        
        debugMsg(coalitionName .. " coalition: " .. coalitionGroups .. " groups, " .. coalitionUnits .. " units")
        totalGroups = totalGroups + coalitionGroups
        totalUnits = totalUnits + coalitionUnits
    end
    
    debugMsg("Data collection complete: " .. totalGroups .. " total groups, " .. totalUnits .. " total units")
    
    return data
end

-- Function to write XML to file
local function writeXMLFile(data)
    debugMsg("Generating XML output...")
    
    local missionTime = timer.getAbsTime()
    local totalSeconds = math.floor(missionTime)
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    local timestamp = string.format("Mission Time %02d:%02d:%02d", hours, minutes, seconds)
    
    local xml = '<?xml version="1.0" encoding="UTF-8"?>\n'
    xml = xml .. '<dcs_mapping timestamp="' .. escapeXML(timestamp) .. '">\n'
    
    -- Write groups section
    xml = xml .. '  <groups>\n'
    local groupCount = 0
    for groupId, groupData in pairs(data.groups) do
        xml = xml .. '    <group id="' .. escapeXML(groupId) .. '" '
        xml = xml .. 'name="' .. escapeXML(groupData.name) .. '" '
        xml = xml .. 'category="' .. escapeXML(groupData.category) .. '" '
        xml = xml .. 'coalition="' .. escapeXML(groupData.coalition) .. '"/>\n'
        groupCount = groupCount + 1
    end
    xml = xml .. '  </groups>\n'
    
    -- Write units section
    xml = xml .. '  <units>\n'
    local unitCount = 0
    for unitId, unitData in pairs(data.units) do
        xml = xml .. '    <unit id="' .. escapeXML(unitId) .. '" '
        xml = xml .. 'name="' .. escapeXML(unitData.name) .. '" '
        xml = xml .. 'type="' .. escapeXML(unitData.type) .. '" '
        xml = xml .. 'group_id="' .. escapeXML(unitData.groupId) .. '" '
        xml = xml .. 'group_name="' .. escapeXML(unitData.groupName) .. '" '
        xml = xml .. 'coalition="' .. escapeXML(unitData.coalition) .. '"/>\n'
        unitCount = unitCount + 1
    end
    xml = xml .. '  </units>\n'
    
    xml = xml .. '</dcs_mapping>\n'
    
    debugMsg("Outputting XML with " .. groupCount .. " groups and " .. unitCount .. " units to DCS log...")
    
    -- Output XML to DCS log with special markers for external parsing
    env.info("=== DCS_MAPPER_XML_START ===")
    env.info(xml)
    env.info("=== DCS_MAPPER_XML_END ===")
    
    debugMsg("XML data successfully logged to DCS log (look for DCS_MAPPER_XML markers)")
end

-- Main update function
local function updateMapping()
    debugMsg("Starting mapping update cycle...")
    
    local success, result = pcall(function()
        local data = getUnitsAndGroups()
        writeXMLFile(data)
    end)
    
    if not success then
        local errorMsg = "Error updating unit/group mapping: " .. tostring(result)
        debugMsg("ERROR: " .. errorMsg)
        env.error(errorMsg)
    else
        debugMsg("Mapping update cycle completed successfully")
    end
end

-- Initial update
debugMsg("DCS Unit/Group ID Mapper initializing...")
updateMapping()

-- Schedule periodic updates
timer.scheduleFunction(function()
    updateMapping()
    return timer.getTime() + updateInterval
end, nil, timer.getTime() + updateInterval)

debugMsg("DCS Unit/Group ID Mapper started. Update interval: " .. updateInterval .. "s")
env.info("DCS Unit/Group ID Mapper started. Logging to DCS log") 