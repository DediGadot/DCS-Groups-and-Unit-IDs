# DCS World Unit/Group ID Mapper

A simple Lua script for DCS World that maps unit IDs and group IDs to their names and outputs the data in XML format.

## Features

- Maps unit IDs to unit names, types, and associated group information
- Maps group IDs to group names, categories, and coalition
- Outputs data in well-formatted XML
- Updates automatically every 3 seconds
- Includes error handling and XML character escaping

## Installation

1. Copy `dcs_unit_group_mapper.lua` to your DCS World Scripts folder
2. Add the script to your mission or load it via DCS triggers

## Usage

### In Mission Editor
1. Add a "DO SCRIPT FILE" trigger
2. Point it to `dcs_unit_group_mapper.lua`
3. Set trigger to activate when mission starts

### Via DCS Console
```lua
dofile("path/to/dcs_unit_group_mapper.lua")
```

## Output

The script creates `unit_group_mapping.xml` with the following structure:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<dcs_mapping timestamp="2024-01-01 12:00:00">
  <groups>
    <group id="1" name="Red Ground-1" category="0" coalition="1"/>
    <group id="2" name="Blue Air-1" category="1" coalition="2"/>
  </groups>
  <units>
    <unit id="101" name="Red Ground-1-1" type="M-1 Abrams" group_id="1" group_name="Red Ground-1" coalition="1"/>
    <unit id="102" name="Blue Air-1-1" type="F/A-18C_hornet" group_id="2" group_name="Blue Air-1" coalition="2"/>
  </units>
</dcs_mapping>
```

## Configuration

Edit the script to modify:
- `logFile`: Change output filename (default: "unit_group_mapping.xml")
- `updateInterval`: Change update frequency in seconds (default: 3)

## Coalition Values
- 0: Neutral
- 1: Red
- 2: Blue

## Category Values
- 0: Ground units
- 1: Aircraft
- 2: Helicopters
- 3: Ships

## Notes

- The script only tracks existing units/groups
- Updates stop if all units in a group are destroyed
- XML file is overwritten on each update
- Uses DCS World's coalition and group APIs 