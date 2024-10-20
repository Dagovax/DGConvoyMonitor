if (!isServer) exitWith {};

if (isNil "DGCM_Configured") then
{
	["Waiting until configuration completes...", "DG Convoy Monitor"] call DGCore_fnc_log;
	waitUntil{uiSleep 10; !(isNil "DGCM_Configured")}
};

["Initializing Dagovax Games Convoy Monitor", DGCM_MessageName] call DGCore_fnc_log;

/****************************************************************************************************/
/********************************  DO NOT EDIT THE CODE BELOW!!  ************************************/
/****************************************************************************************************/
DGCM_DebugSpawnPosition = false;
if(DGCM_DebugMode) then 
{
	["Running in Debug mode!", DGCM_MessageName, "debug"] call DGCore_fnc_log;
	DGCM_MinAmountPlayers 	= 1;
	DGCM_MinSleepTime		= 10; 
	DGCM_MaxSleepTime		= 60;
	DGCM_DebugSpawnPosition	= true;
	DGCM_MaxTravelDistance	= 1000;
};

if (DGCM_MinAmountPlayers > 0) then
{
	[format["Waiting for %1 players to be online.", DGCM_MinAmountPlayers], DGCM_MessageName, "debug"] call DGCore_fnc_log;
	waitUntil { uiSleep 10; count( playableUnits ) > ( DGCM_MinAmountPlayers - 1 ) };
};
[format["%1 players reached. Initializing main loop of Convoy Monitor!", DGCM_MinAmountPlayers], DGCM_MessageName, "debug"] call DGCore_fnc_log;

DGCM_ConvoyQueue = []; // Active convoys. 

_reInitialize = true; // Only initialize this when _reInitialize is true

// Wait randomly for first initialization
_initialWaitTime =  (DGCM_MinSleepTime) + random((DGCM_MaxSleepTime) - (DGCM_MinSleepTime));
[format["Waiting %1 seconds for first convoy spawn", _initialWaitTime], DGCM_MessageName, "debug"] call DGCore_fnc_log;
uiSleep _initialWaitTime;

while {true} do // Main Loop
{
	if(_reInitialize) then
	{
		_reInitialize = false;
		if(count DGCM_ConvoyQueue >= DGCM_MaxConvoys) exitWith{}; // Maximum amount of convoys reached
		
		// Initialize new convoy
		["Initializing new convoy...", DGCM_MessageName, "debug"] call DGCore_fnc_log;
		_convoyConfig = selectRandom DGCM_ConvoyConfigs;
		_convoyType = _convoyConfig select 0;
		_convoyMultiSpawn = _convoyConfig select 1;
		
		// Select a type of convoy
		while {true} do
		{
			if (_convoyMultiSpawn) exitWith{}; // This type can have multiple spawns, so exit
			_convoyTypeinQueue = false;
			{
				if((_x select 0) isEqualTo _convoyType) exitWith
				{
					_convoyTypeinQueue = true;
				};
			} forEach DGCM_ConvoyQueue;
			
			if (!_convoyMultiSpawn && !(_convoyTypeinQueue)) exitWith{}; // We can spawn this convoy type only once
			_convoyConfig 		= selectRandom DGCM_ConvoyConfigs;
			_convoyType 		= _convoyConfig select 0;
			_convoyMultiSpawn 	= _convoyConfig select 1;
			uiSleep 1;
		};
		[format["Spawning convoy type '%1'", _convoyType], DGCM_MessageName, "debug"] call DGCore_fnc_log;	
		
		// DGCore spawn convoy
		private ["_debugPos"];
		
		if(DGCM_DebugSpawnPosition) then
		{
			// Do some debug hack for first player
			_alivePlayers = call DGCore_fnc_getAllAlivePlayers;
			if(!isNil "_alivePlayers" && count _alivePlayers > 0) then
			{
				_cheater = selectRandom(_alivePlayers);
				_cheater allowDamage false; // Makes sure the debugger survives lol
				_debugPos = getPos _cheater;
			};
		};
		if(isNil "_debugPos") then
		{
			_debugPos = [0,0,0]; // This is default spawn position, which will be random location!!
		};
		
		_convoyInfo = [_convoyType, (_convoyConfig select 4), _debugPos, DGCM_MaxTravelDistance] call DGCore_fnc_spawnConvoyArray;
		waitUntil {uiSleep 1; !(isNil "_convoyInfo")}; // Wait until convoy info retrieved
		DGCM_ConvoyQueue pushBack [_convoyType, _convoyInfo];
		[_convoyType, _convoyConfig, _convoyInfo] spawn
		{
			params ["_convoyType", "_convoyConfig", "_convoyInfo"];
			
			// Convoy retrieved data
			_spawnPosition = _convoyInfo select 0;
			
			// Config related data
			_notificationTitle = _convoyConfig select 2;
			_notificationText = _convoyConfig select 3;
			
			["UAV_05"] remoteExec ["playSound",0];
			_startMsg = [_notificationText, _spawnPosition] call DGCore_fnc_addPositionToNotification;
			_startMsg remoteExecCall ["systemChat",-2];
			[
				"toastRequest",
				[
					"InfoEmpty",
					[
						format
						[
							"<t color='#ffff00' size='%1' font='%2'>%3</t><br/><t color='%4' size='%5' font='%6'>%7</t>",
							DGCM_ExileToasts_Title_Size,
							DGCM_ExileToasts_Title_Font,
							_notificationTitle,
							DGCM_ExileToasts_Message_Color,
							DGCM_ExileToasts_Message_Size,
							DGCM_ExileToasts_Message_Font,
							_startMsg
						]
					]
				]
			] call ExileServer_system_network_send_broadcast;
			
			private _groupArray = _convoyInfo select 1;
			
			// Create an invisible object that we will use the store variable info into! Quite usefull duh
			private _dummyObject = call DGCore_fnc_getDummy;
			
			_dummyObject setVariable ["DGCM_VehicleCount", count _groupArray];	
			[format ["Convoy, starting @ %1, is now underway with %2 vehicles!", _spawnPosition, (_dummyObject getVariable "DGCM_VehicleCount")], DGCM_MessageName, "debug"] call DGCore_fnc_log;
			
			private _convoyCompleted = false;	
			{
				_vehicle = _x select 0;
				_vehicleGroup = _x select 1;
				
				[_dummyObject, _vehicle] spawn
				{
					params["_dummyObject", "_vehicle"];
					while{true} do
					{
						if(isNull _vehicle || !alive _vehicle) exitWith
						{
							_vehicleCount = _dummyObject getVariable "DGCM_VehicleCount";
							_vehicleCount = _vehicleCount -1;
							_dummyObject setVariable ["DGCM_VehicleCount", _vehicleCount];	
						}; //vehicle destroyed or deleted
						
						if (!(_vehicle getVariable ["DGCore_IsConvoyActive", true])) exitWith
						{
							_vehicleCount = _dummyObject getVariable "DGCM_VehicleCount";
							_vehicleCount = _vehicleCount -1;
							_dummyObject setVariable ["DGCM_VehicleCount", _vehicleCount];	
						};
					};
					[format ["A vehicle either blew up, or completed the convoy task... %1 vehicle(s) remaining...", (_dummyObject getVariable "DGCM_VehicleCount")], DGCM_MessageName, "debug"] call DGCore_fnc_log;
				};
				
			} forEach _groupArray;			
			
			waitUntil {uiSleep 5; ((_dummyObject getVariable "DGCM_VehicleCount") < 1)}; // Wait until all convoy vehicles are completed
			_convoyCompleted = true;
			deleteVehicle _dummyObject; // Delete dummy after use
			[format ["Convoy that spawned @ %1 completed their task.. Removing it from the queue.", _spawnPosition], DGCM_MessageName, "debug"] call DGCore_fnc_log;
			DGCM_ConvoyQueue deleteAt ( DGCM_ConvoyQueue find [_convoyType, _convoyInfo] );
		};	
	};
	_reInitialize = true;
	
	// Wait randomly until next iteration.
	_waitTime =  (DGCM_MinSleepTime) + random((DGCM_MaxSleepTime) - (DGCM_MinSleepTime));
	[format ["Active queue [%1] = %2", count(DGCM_ConvoyQueue), DGCM_ConvoyQueue], DGCM_MessageName, "debug"] call DGCore_fnc_log;
	[format["Waiting %1 seconds for next convoy spawn iteration", _waitTime], DGCM_MessageName, "debug"] call DGCore_fnc_log;
	uiSleep _waitTime;
};




// _reInitialize = true; // Only initialize this when _reInitialize is true
// while {true} do // Main Loop
// {
	// if(_reInitialize) then
	// {
		// _reInitialize = false;
		
		// if((count DGCM_ConvoyQueue) < DGCM_MaxConvoys) then
		// {
			// diag_log format ["%1 Initializing new Convoy", DGCM_MessageName];
			// _convoyConfig 	= selectRandom DGCM_ConvoyConfigs;
			// _cvType 		= _convoyConfig select 0;
			// _cvMultiSpawn 	= _convoyConfig select 1;
			// while {true} do
			// {
				// if (_cvMultiSpawn) exitWith{}; // This type can have multiple spawns, so exit
				// if (!_cvMultiSpawn && !(_cvType in DGCM_ConvoyQueue)) exitWith{}; // We can spawn this convoy type only once
				// _convoyConfig 	= selectRandom DGCM_ConvoyConfigs;
				// _cvType 		= _convoyConfig select 0;
				// _cvMultiSpawn 	= _convoyConfig select 1;
				// uiSleep 1;
			// };
			// diag_log format ["%1 Spawning convoy type '%2'", DGCM_MessageName, _cvType];
			
			// [_cvType, (_convoyConfig select 2)] spawn
			// {
				// params ["_convoyType", "_convoyConfig"];
				// if(isNil "_convoyConfig") exitWith
				// {
					// diag_log format ["%1 Unable to load config for this convoy type:[%2] cancelling convoy spawn!", DGCM_MessageName, _convoyType];
				// };
				
				// _playerCanGetIn = _convoyConfig select 0;
				// _convoyMarker = _convoyConfig select 1;
				// _convoyMarkerColor = _convoyConfig select 2;
				// _convoyMarkerText = _convoyConfig select 3;
				// _convoyMarkerType = _convoyConfig select 4;
				// _alertConvoy = _convoyConfig select 5;
				// _alertText = _convoyConfig select 6;
				// _alertBody = _convoyConfig select 7;
				// _speedLimit = _convoyConfig select 8;
				// _convoySide = _convoyConfig select 9;
				// _uniforms = _convoyConfig select 10;
				// _moneyMin = _convoyConfig select 11;
				// _moneyMax = _convoyConfig select 12;
				// _AImoneyMin = _convoyConfig select 13;
				// _AImoneyMax = _convoyConfig select 14;
				// _dynamicLoot = _convoyConfig select 15;
				// _allConvoyVehicles = _convoyConfig select 16;
				
				// // Spawn the convoy
				// _allRoads = [0,0,0] nearRoads 50000;
				// _spawnConvoyLocation = getPos (selectRandom _allRoads);
				// _vehicleSpawnPoints = _spawnConvoyLocation nearRoads DGCM_SpawnRadius;
				
				// if !(_allConvoyVehicles isEqualTo []) then
				// {
					// if !(_vehicleSpawnPoints isEqualTo []) then
					// {
						// if ((count _vehicleSpawnPoints) > (count _allConvoyVehicles)) then
						// {
							// DGCM_ConvoyQueue pushBack _convoyType; // Add this convoy to the queue
							// // Find a good position over 4K away
							// _goodPos = false;
							// _endWaypoint = getPos (selectRandom _allRoads);
							// while {!_goodPos} do
							// {
								// _goodPosDist = 0;
								// while {_goodPosDist < 4000} do
								// {
									// _endWaypoint = getPos (selectRandom _allRoads);
									// _goodPosDist = _spawnConvoyLocation distance2D _endWaypoint;
								// };
								// _goodPos = true;
							// };
						
							// _groupArray = [];
						
							// {
								// // Spawn this vehicle
								// _vehicleClass = selectRandom (_x select 0);
								// _spawnVehicleLoc = selectRandom _vehicleSpawnPoints;
								// _indexVehSpawn = _vehicleSpawnPoints find _spawnVehicleLoc;
								// _spawnPos = getPos _spawnVehicleLoc;
								// _vehicleSpawnPoints deleteAt _indexVehSpawn;

								// _numberAI = _x select 1;
								// _staticLoot = _x select 2;
								// _flyHeight = _x select 3;
								
								
								// _vehicleGroup = createGroup east;
								// _vehicleGroup setVariable ["_groupCompleted", false];
								// _vehicleObj = createVehicle [_vehicleClass, _spawnPos, [], 0, "CAN_COLLIDE"];
								// _vehicleObj limitSpeed _speedLimit;
								// _vehicleGroup setVariable ["_vehicleObj", _vehicleObj];
								// _vehicleObj allowDamage true;
								// _vehicleObj disableAI "LIGHTS"; // override AI
								// _vehicleObj action ["LightOn", _vehicleObj];
								// _vehicleMoney = ceil((_moneyMin) + random((_moneyMax) - (_moneyMin)));
								// _vehicleObj setVariable ["ExileMoney",_vehicleMoney ,true]; // Add some money
								
								// _vehicleName = getText (configFile >> "CfgVehicles" >> (typeOf _vehicleObj) >> "displayName");
								// diag_log format ["%1 Spawned a %2 at position %3", DGCM_MessageName, _vehicleClass, _spawnPos];
								// diag_log format["%1 Adding %2 units to this %3", DGCM_MessageName, _numberAI, _vehicleName];
								// for "_i" from 1 to _numberAI do 
								// {
									// _unit = _vehicleGroup createUnit ["O_A_soldier_F", _spawnPos, [], 0, "FORM"];
									// _unit moveInAny _vehicleObj; // Add unit to the vehicle
									// _unit addMPEventHandler ["MPKILLED",  
									// {
										// _this spawn
										// {
											// params ["_unit", "_killer", "_instigator"];
											// _group = group _unit;
											// if (isNull _killer || {isNull _instigator}) exitWith {};
											// ["FD_CP_Clear_F"] remoteExec ["playSound",_instigator];
											// if (_instigator isKindOf "Exile_Unit_Player") then
											// {
												// _msg = format[
													// "%1 killed %2 (AI) with %3 at %4 meters!",
													// name _instigator, 
													// name _unit, 
													// getText(configFile >> "CfgWeapons" >> currentWeapon _instigator >> "displayName"), 
													// _unit distance _instigator
												// ];
												// [_msg] remoteExec["systemChat",-2];
											// };
										// };
									// }];
									// // removeAllWeapons _unit;
									// // removeBackpack _unit;
									// // removeVest _unit;
									// // removeHeadgear _unit;
									// // removeGoggles _unit;
									// _unit forceAddUniform selectRandom _uniforms;
									// _money = ceil((_AImoneyMin) + random((_AImoneyMax) - (_AImoneyMin)));
									// _unit setVariable ["ExileMoney",_money ,true]; // Add some money
								// };
								
								// // Spawn marker
								// _vehicleMarker = createMarker [format ["%1_%2_%3_%4", "_convoyMarker", _vehicleClass, _spawnPos select 0, _spawnPos select 0], _spawnPos];
								// _vehicleGroup setVariable ["_vehicleMarker", _vehicleMarker];
								// if (_convoyMarker) then
								// {
									// _vehicleMarker setMarkerType _convoyMarkerType;
									// _vehicleMarker setMarkerColor _convoyMarkerColor;
									// _vehicleMarker setMarkerText _convoyMarkerText;
								// };
								
								// [_vehicleGroup, _convoyMarker, _vehicleMarker, _vehicleObj, _endWaypoint] spawn
								// {
									// params ["_vehicleGroup", "_convoyMarker", "_vehicleMarker", "_vehicleObj", "_endWaypoint"];
									// if (isNil "_vehicleGroup") exitWith {};
									
									// while {({alive _x } count(units _vehicleGroup)) > 0} do // While until group has no more AI
									// {
										// if (!alive _vehicleObj) exitWith{}; // vehicle destroyed
										// _currentPos = getPos _vehicleObj;
										// if ((_currentPos distance2D _endWaypoint) <= 100) exitWith{
											// diag_log format["%1 Convoy vehicle %2 reached the end. Cleaning it up now.", DGCM_MessageName, _vehicleObj];
											// {
												// _x setDamage 1;
												// deleteVehicle _x;
											// } forEach units _vehicleGroup;
											// deleteVehicleCrew _vehicleObj;
											// _vehicleObj setDamage 1;
											// deleteVehicle _vehicleObj;
										// }; // This group arrived at the waypoint
										
										// if(_convoyMarker)then
										// {
											// _pos = position _vehicleObj;
											// _vehicleMarker setMarkerPos _pos;
										// };
										
										// uiSleep 1;
									// };
									// deleteMarker _vehicleMarker; // Delete marker as this group is completed.
									// _vehicleGroup setVariable ["_groupCompleted", true];
								// };
								
								// if !(_endWaypoint isEqualTo []) then
								// {
									// _waypoint = _vehicleGroup addWaypoint [_endWaypoint, 50];
									// _waypoint setWaypointType "MOVE";
									// _waypoint setWaypointCombatMode "YELLOW";
									// _waypoint setWaypointSpeed "NORMAL";
									// _waypoint setWaypointBehaviour "SAFE";
									// _waypoint setWaypointFormation "STAG COLUMN";

									// _waypoint = _vehicleGroup addWaypoint [_endWaypoint, 50];
									// _waypoint setWaypointType "CYCLE";
									// _waypoint setWaypointCombatMode "YELLOW";
									// _waypoint setWaypointSpeed "NORMAL";
									// _waypoint setWaypointBehaviour "SAFE";
									// _waypoint setWaypointFormation "STAG COLUMN";
								// };
								// _groupArray pushBack _vehicleGroup;
							// } forEach _allConvoyVehicles;
							
							// // Anounce to clients
							// if (_alertConvoy) then
							// {
								// ["toastRequest", ["InfoTitleAndText", [_alertText, _alertBody]]] call ExileServer_system_network_send_broadcast;
							// }; 
							
							// while {true} do
							// {
								// _counter = 0;
								// {
									// _groupCompleted = _x getVariable "_groupCompleted";
									// if !(isNil "_groupCompleted") then
									// {
										// if (!_groupCompleted) then
										// {
											// _counter = _counter + 1; // This vehicle still has a marker etc... Not finished
										// };
									// };
								// }
								// forEach _groupArray;
								
								// uiSleep 5;
								
								// _finished = false;
								// if (_counter < 1) exitWith
								// {
									// _finished = true;
									// diag_log format["%1 Convoy of type [%2] is destroyed/captured or was cleaned up by the script.", DGCM_MessageName, _convoyType];
								// };
								// if (_finished) exitWith {};
							// };
							// DGCM_ConvoyQueue deleteAt ( DGCM_ConvoyQueue find _convoyType );
						// };
					// };
				// };
			// };
		// };
	// };
	// _reInitialize = true;
	
	// // Wait randomly until next iteration.
	// _waitTime =  (DGCM_MinSleepTime) + random((DGCM_MaxSleepTime) - (DGCM_MinSleepTime));
	// diag_log format ["%1 Active convoys [%2] = %3", DGCM_MessageName, count(DGCM_ConvoyQueue), DGCM_ConvoyQueue];
	// diag_log format ["%1 Waiting %2 seconds for next iteration", DGCM_MessageName, _waitTime];
	// uiSleep _waitTime;
// }