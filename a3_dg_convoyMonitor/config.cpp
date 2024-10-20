class CfgPatches {
	class a3_dg_convoyMonitor {
		units[] = {};
		weapons[] = {};
		requiredVersion = 0.1;
		requiredAddons[] = {};
	};
};
class CfgFunctions {
	class DGConvoyMonitor {
		tag = "DGConvoyMonitor";
		class Main {
			file = "\x\addons\a3_dg_convoyMonitor\init";
			class init {
				postInit = 1;
			};
		};
	};
};

