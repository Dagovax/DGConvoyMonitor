waitUntil {uiSleep 5; !(isNil "DGCore_Initialized")}; // Wait until DGCore was initialized

["Starting Dagovax Games Convoy Monitor"] call DGCore_fnc_log;
execvm "\x\addons\a3_dg_convoyMonitor\config\DGCM_config.sqf";
execvm "\x\addons\a3_dg_convoyMonitor\init\convoyMonitor.sqf";
