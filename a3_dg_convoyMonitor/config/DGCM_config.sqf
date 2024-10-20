
DGCM_MessageName = "DG ConvoyMonitor";

if (!isServer) exitWith {
	["Failed to load configuration data, as this code is not being executed by the server!", DGCM_MessageName] call DGCore_fnc_log;
};

/****************************************************************************************************/
/********************************  CONFIG PART. EDIT AS YOU LIKE!!  ************************************/
/****************************************************************************************************/

// Generic
DGCM_DebugMode			= false; 	// Only for creator. Leave it on false
DGCM_MinAmountPlayers	= 1; 		// Amount of players required to start the missions spawning. Set to 0 to have no wait time for players
DGCM_MinSleepTime		= 30;		// Minimum amount of seconds to sleep until new initialization starts.
DGCM_MaxSleepTime		= 300; 		// Maximum amount of seconds to sleep until new initialization starts.
DGCM_MaxConvoys			= 3; 		// Amount of convoys to be active at the same time.
DGCM_MaxTravelDistance	= -1;		// Maximum distance a convoy will travel from their starting position. Use -1 to use DGCore settings

/*Exile Toasts Notification Settings*/
DGCM_ExileToasts_Title_Size		= 23;						// Size for Client Exile Toasts  mission titles.
DGCM_ExileToasts_Title_Font		= "puristaMedium";			// Font for Client Exile Toasts  mission titles.
DGCM_ExileToasts_Message_Color	= "#FFFFFF";				// Exile Toasts color for "ExileToast" client notification type.
DGCM_ExileToasts_Message_Size	= 19;						// Exile Toasts size for "ExileToast" client notification type.
DGCM_ExileToasts_Message_Font	= "PuristaLight";			// Exile Toasts font for "ExileToast" client notification type.
/*Exile Toasts Notification Settings*/

// Convoy Config
DGCM_ConvoyConfigs =
[
	[
		"ArmedConvoy",
		true,
		"Armed Patrol",
		"An Armed Patrol has been spotted moving through the area", // No period, comma etc at the end! 
		[
			DGCore_ArmedConvoy,
			-1,
			250,					// Radius in which the vehicles will randomly spawn.  
			DGCore_Side,
			50,
			true,
			[
				[], // Items
				[], // Backpacks
				[] // Weapons
			],
			"calculate",
			DGCore_AIWeapons,
			false,
			[true, "loc_car", "ColorOrange", 0.8, "Convoy"]
		]
	],

	[
		"ArmedTroopConvoy",
		false,
		"Troop Convoy",
		"Armed Troop Convoy operations have been reported in the region", // No period, comma etc at the end! 
		[
			DGCore_ArmedTroopConvoy,
			-1,
			250,					// Radius in which the vehicles will randomly spawn.  
			DGCore_Side,
			50,
			true,
			[
				// Items
				[ 
					DGCore_CountItemVehicle,
					[	
						"HandGrenade","HandGrenade","APERSBoundingMine_Range_Mag","optic_Nightstalker"
					]
				],
				[], // Backpacks
				[] // Weapons
			],
			"calculate",
			DGCore_AIWeapons,
			false,
			[true, "loc_Truck", "ColorRed", 0.8, "Convoy"]
		]
	],
	
	[
		"ArmedTankConvoy",
		false,
		"Heavily Armed Patrol",
		"A Heavily Armed Patrol has been spotted moving through the area", // No period, comma etc at the end! 
		[
			DGCore_ArmedTankConvoy,
			-1,
			250,					// Radius in which the vehicles will randomly spawn.  
			DGCore_Side,
			50,
			true,
			[
				// Items
				[ 
					DGCore_CountItemVehicle,
					[	
						"HandGrenade","HandGrenade","APERSBoundingMine_Range_Mag","optic_Nightstalker"
					]
				],
				[], // Backpacks
				[] // Weapons
			],
			"calculate",
			DGCore_AIWeapons,
			false,
			[true, "loc_Attack", "ColorBlack", 0.8, "Convoy"]
		]
	]	
	
	// [
		// "HeloPatrol",
		// [
			// true, 			// 0 - Player Can Get In = TRUE - Allow players to board vehicles. FALSE- Players will be kicked out of AI vehicles
			// true, 			// 1 - Convoy Marker - Vehicle = TRUE - Display the convoy marker on the map. FALSE - do not display on the map.  
			// "ColorBlue", 	// 2 - Vehicle Marker Color = The color of the marker on the map. Available colors ColorGrey, ColorBlack, ColorRed, ColorBrown, ColorOrange, ColorYellow, ColorKhaki, ColorGreen, ColorBlue, ColorPink, ColorWhite 
			// "Convoy", 		// 3 - Vehicle Marker Text = The name displayed next to the marker. You can just leave blank if you want
			// "loc_heli",	// 4 - Marker type - Map marker to use for convoy vehicle
			// true, 			// 5 - Convoy Alert = TRUE - Display a message that a convoy appeared. FALSE - do not display. 
							// // 6 - Convoy Alert Title = Alert title
			// "Helicopter Patrol Reported", 
							// // 7 -  Convoy Alert Body = Alert message text
			// "A helicopter patrol been reported in the region.", 
			// 100, 			//  8 - Convoy Speed Limit = The speed limit of the entire convoy. If you have a different vehicle classes, this will ensure they all go the same speed
			// EAST,			//  9 - Side of convoy
			// ["U_B_CombatUniform_vest_mcam_wdl_f","U_B_CombatUniform_mcam_wdl_f","U_B_CombatUniform_tshirt_mcam_wdL_f"],			
							// //	10 - Array of uniforms to put on soldiers and drivers
			// 50, 			//  11 - Exile Vehicle Money Min = The minimum amount of poptabs in the vehicle 
			// 100, 			//  12 - Exile Vehicle Money Max = The maximum amount of poptabs in the vehicle 
			// 0, 				//  13 - Exile Bot Money Min = We set the minimum value of poptabs for AI 
			// 10, 			//  14 - Exile Bot Money Max = We set the max value of poptabs for AI 
			// true,			//  15 - Vehicle Dynamic Loot = Add dynamic loot from defined loot arrays. true/false
			// [				// 	16 - _allConvoyVehicles = Vehicle List for convoy
				// [			// Vehicle 0 
					// ["B_Heli_Light_01_armed_F", "CUP_B_CH47F_GB"], // 0 - Vehicle class 
					// 4, 		// The number of bots in the vehicle
					// [],		// See first entry of convoy script to see how to use this field
					// 200		// object height. If this is a helicopter, it will appear in the air at the height indicated in this parameter. Write in meters.
				// ],
				// [			// Vehicle 1
					// ["B_Heli_Light_01_armed_F", "CUP_B_CH47F_GB"], // Vehicle class        
					// 4, 		// The number of bots in the car
					// [],		// See first entry of convoy script to see how to use this field
					// 200 	// Object height. If this is a helicopter, it will appear in the air at the height indicated in this parameter. Write in meters.
				// ]
			// ]
		// ]
	// ]
];

DGCM_Configured = true;
["Configuration loaded", DGCM_MessageName] call DGCore_fnc_log;


