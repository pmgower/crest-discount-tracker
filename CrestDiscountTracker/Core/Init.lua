-- Init.lua - Initialize the addon namespace
local addonName, addon = ...

-- Create namespace tables
addon.Core = {}
addon.Services = {}
addon.UI = {}
addon.Data = {}

-- Export the addon name
addon.name = addonName 