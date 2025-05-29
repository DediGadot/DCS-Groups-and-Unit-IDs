-- DCS World Unit and Group ID to Name Mapper
-- Updates XML logfile every 3 seconds with unit/group mappings

local logFile = "unit_group_mapping.xml"
local updateInterval = 3 -- seconds

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
    local data = {
        units = {},
        groups = {}
    }
    
    -- Get all coalitions
    local coalitions = {coalition.side.RED, coalition.side.BLUE, coalition.side.NEUTRAL}
    
    for _, coalitionSide in ipairs(coalitions) do
        -- Get all groups for this coalition
        local groups = coalition.getGroups(coalitionSide)
        
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
                    end
                end
            end
        end
    end
    
    return data
end

-- Function to write XML to file
local function writeXMLFile(data)
    local xml = '<?xml version="1.0" encoding="UTF-8"?>\n'
    xml = xml .. '<dcs_mapping timestamp="' .. escapeXML(os.date("%Y-%m-%d %H:%M:%S")) .. '">\n'
    
    -- Write groups section
    xml = xml .. '  <groups>\n'
    for groupId, groupData in pairs(data.groups) do
        xml = xml .. '    <group id="' .. escapeXML(groupId) .. '" '
        xml = xml .. 'name="' .. escapeXML(groupData.name) .. '" '
        xml = xml .. 'category="' .. escapeXML(groupData.category) .. '" '
        xml = xml .. 'coalition="' .. escapeXML(groupData.coalition) .. '"/>\n'
    end
    xml = xml .. '  </groups>\n'
    
    -- Write units section
    xml = xml .. '  <units>\n'
    for unitId, unitData in pairs(data.units) do
        xml = xml .. '    <unit id="' .. escapeXML(unitId) .. '" '
        xml = xml .. 'name="' .. escapeXML(unitData.name) .. '" '
        xml = xml .. 'type="' .. escapeXML(unitData.type) .. '" '
        xml = xml .. 'group_id="' .. escapeXML(unitData.groupId) .. '" '
        xml = xml .. 'group_name="' .. escapeXML(unitData.groupName) .. '" '
        xml = xml .. 'coalition="' .. escapeXML(unitData.coalition) .. '"/>\n'
    end
    xml = xml .. '  </units>\n'
    
    xml = xml .. '</dcs_mapping>\n'
    
    -- Write to file
    local file = io.open(logFile, "w")
    if file then
        file:write(xml)
        file:close()
        env.info("DCS Unit/Group mapping updated: " .. logFile)
    else
        env.error("Failed to write to " .. logFile)
    end
end

-- Main update function
local function updateMapping()
    local success, result = pcall(function()
        local data = getUnitsAndGroups()
        writeXMLFile(data)
    end)
    
    if not success then
        env.error("Error updating unit/group mapping: " .. tostring(result))
    end
end

-- Initial update
updateMapping()

-- Schedule periodic updates
timer.scheduleFunction(function()
    updateMapping()
    return timer.getTime() + updateInterval
end, nil, timer.getTime() + updateInterval)

env.info("DCS Unit/Group ID Mapper started. Logging to: " .. logFile) 