// Static objects and item pickups
class ClassicDecoration : Actor
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations
		//$NotAngled

		+SOLID		//Combining 'Solid' with a Height of 0 lets actors
		Radius 32;	// walk over these seamlessly if the actor has the
		Height 0;	// CANPASS flag...  Otherwise they are blocked.
	}

	States
	{
		Spawn:
			UNKN A -1;
			Stop;
	}
}

class Score : StackableInventory
{
	int lifeamount;

	Property LifeAmount:lifeamount;

	Default
	{
		+Inventory.UNCLEARABLE
		Inventory.MaxAmount 0x7FFFFFFF;
		Score.LifeAmount 40000;
	}

	override void Tick()
	{
		if (owner && amount >= lifeamount)
		{
			lifeamount += Default.lifeamount;
			LifeHandler.GiveLife(owner);
		}

		Super.Tick();
	}
}

class PoolofWater : ClassicDecoration
{
	Default
	{
		//$Title Pool of Water
		-SOLID
	}

	States
	{
		Spawn:
			POL1 A -1;
			Stop;
	}
} 

class OilDrum : ClassicDecoration
{
	Default
	{
		//$Title Barrel (Oil Drum)
		Height 30;
	}

	States
	{
		Spawn:
			BARL C -1;
			Stop;
	}
}

class ExplosiveOilDrum : ExplosiveBarrel
{
	Default
	{
		//$Category Wolfenstein 3D/Items
		//$NotAngled
		//$Title Barrel (Oil Drum, Explosive)

		Height 50;
		DeathSound "missile/hit";
		Obituary "";
	}

	States
	{
		Spawn:
			WBXP A -1;
			Stop;
		Death:
			WBXP B 5 Bright A_Scream();
			WBXP C 5 Bright A_Explode();
			WBXP D 10 Bright;
			TNT1 A 1050 Bright A_BarrelDestroy();
			TNT1 A 5 A_Respawn();
			Wait;
	}
}

class TableandChairs : ClassicDecoration
{
	Default
	{
		//$Title Table and Chairs
		Height 32;
	}

	States
	{
		Spawn:
			TAB1 A -1;
			Stop;
	}
} 

class FloorLamp : ClassicDecoration
{
	Default
	{
		//$Title Floor Lamp
		Height 32;
	}

	States
	{
		Spawn:
			LIT1 A -1 Bright;
			Stop;
	}
} 

class HangingChandelier : ClassicDecoration
{
	Default
	{
		//$Title Hanging Chandelier
		-SOLID
		+SPAWNCEILING
		+NOGRAVITY
		Height 64;
	}

	States
	{
		Spawn:
			LIT3 A -1 Bright;
			Stop;
	}
} 

class HangingSkeleton : ClassicDecoration
{
	Default
	{
		//$Title Hanging Skeleton
		+SPAWNCEILING
		+NOGRAVITY
		Height 64;
	}

	States
	{
		Spawn:
			HNG1 A -1;
			Stop;
	}
} 

class DogFood : Health
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health
		//$Title Dog Food
		//$Color 1
		//$NotAngled

		+Inventory.AUTOACTIVATE
		Inventory.Amount 4;
		Inventory.MaxAmount 100;
		Inventory.PickupSound "pickups/food";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			HLTH C -1;
			Loop;
	}
}

class StoneColumn : ClassicDecoration
{
	Default
	{
		//$Title Column (Stone)
		Height 64;
	}

	States
	{
		Spawn:
			COLW A -1;
			Stop;
	}
}

Class BreakableColumn : StoneColumn
{
	Default
	{
		//$Category Wolfenstein 3D/Items
		//$Title Column (Stone, Breakable)
		Health 75;
		+DONTTHRUST
		+SHOOTABLE
		+NOBLOOD
		DamageFactor "WolfNazi", 0.0;
		DamageFactor "Fire", 0.0;
	}

	States
	{
		Spawn:
			COLB A 1;
			Wait;
		Death:
			COLB B 10 A_StartSound("missile/hit");
			COLB C 5 A_UnSetSolid();
			COLB D 3 A_UnSetShootable();
			COLB E -1;
			Stop;
	}
}

class Plant : ClassicDecoration
{
	Default
	{
		Height 40;
	}

	States
	{
		Spawn:
			PLT1 A -1;
			Stop;
	}
} 

class Skeleton : ClassicDecoration
{
	Default
	{
		-SOLID
	}

	States
	{
		Spawn:
			BONC A -1;
			Stop;
	}
} 

class Sink : ClassicDecoration
{
	Default
	{
		Height 40;
	}

	States
	{
		Spawn:
			SINK A -1;
			Stop;
	}
} 

class PlantinVase : ClassicDecoration
{
	Default
	{
		//$Title Vase (with plant)
		Height 50;
	}

	States
	{
		Spawn:
			PLT2 A -1;
			Stop;
	}
} 

class Vase : ClassicDecoration
{
	Default
	{
		Height 30;
	}

	States
	{
		Spawn:
			VASE C -1;
			Stop;
	}
} 

class Table : ClassicDecoration
{
	Default
	{
		Height 30;
	}

	States
	{
		Spawn:
			TAB2 A -1;
			Stop;
	}
} 

class GreenCeilingLight : ClassicDecoration
{
	Default
	{
		//$Title Ceiling Light (Green)
		-SOLID
		+SPAWNCEILING
		+NOGRAVITY
		Height 64;
	}

	States
	{
		Spawn:
			LIT5 A -1 Bright;
			Stop;
	}
}

class KitchenUtensils : ClassicDecoration
{
	Default
	{
		//$Title Kitchen Utensils
		-SOLID
		+SPAWNCEILING
		+NOGRAVITY
		Height 64;
	}

	States
	{
		Spawn:
			POT1 A -1;
			Stop;
	}
} 

class SuitofArmor : ClassicDecoration
{
	Default
	{
		//$Title Suit of Armor
		Height 64;
	}

	States
	{
		Spawn:
			KNIG A -1;
			Stop;
	}
} 

class EmptyCage : ClassicDecoration
{
	Default
	{
		//$Title Cage (Empty)
		+SPAWNCEILING
		+NOGRAVITY
		Height 64;
	}

	States
	{
		Spawn:
			CAG1 A -1;
			Stop;
	}
} 

class Cage : ClassicDecoration
{
	Default
	{
		//$Title Cage (with skeleton)
		+SPAWNCEILING
		+NOGRAVITY
		Height 64;
	}

	States
	{
		Spawn:
			CAG2 A -1;
			Stop;
	}
} 

class Bones : ClassicDecoration
{
	Default
	{
		//$Title Pile of Bones
		-SOLID
	}

	States
	{
		Spawn:
			POB1 A -1;
			Stop;
	}
} 

class YellowKey : Key
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Keys
		//$Title Key (Gold)
		Inventory.AltHUDIcon "I_YKEY";
		Inventory.Icon "I_YKEY_T";
		Inventory.PickupSound "pickups/key";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			KEYS A -1;
			Stop;
	}
}

class BlueKey : Key
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Keys
		//$Title Key (Silver)
		Inventory.AltHUDIcon "I_BKEY";
		Inventory.Icon "I_BKEY_T";
		Inventory.PickupSound "pickups/key";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			KEYS B -1;
			Stop;
	}
}

class Bed : ClassicDecoration
{
	Default
	{
		Height 30;
	}

	States
	{
		Spawn:
			BED1 A -1;
			Stop;
	}
} 

class Basket : ClassicDecoration
{
	Default
	{
		-SOLID
	}

	States
	{
		Spawn:
			BASK A -1;
			Stop;
	}
}

class PlateofFood : Health
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health
		//$Title Plate of Food
		//$Color 1
		//$NotAngled

		+Inventory.AUTOACTIVATE
		Inventory.Amount 10;
		Inventory.MaxAmount 100;
		Inventory.PickupSound "pickups/food";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			HLTH D -1;
			Loop;
	}
}

class FirstAidKit : Health
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health
		//$Title First Aid Kit
		//$Color 1
		//$NotAngled

		+Inventory.AUTOACTIVATE
		Inventory.Amount 25;
		Inventory.MaxAmount 100;
		Inventory.PickupSound "pickups/medkit";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			HLTH E -1;
			Loop;
	}
}

class WolfBerserk : Berserk
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health
		//$Title Berserk Pack
		//$Color 1
		//$NotAngled

		+Inventory.AUTOACTIVATE
		Inventory.Amount 25;
		Inventory.MaxAmount 100;
		Inventory.PickupSound "pickups/medkit";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			WSTR A -1;
			Loop;
	}	
}

class JeweledCross : Score
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Treasure
		//$Title Jeweled Cross
		//$Color 14
		//$NotAngled

		+COUNTITEM
		Inventory.Amount 100;
		Inventory.PickupSound "pickups/cross";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			TREC A -1;
			Stop;
	}
}

class Chalice : Score
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Treasure
		//$Color 14
		//$NotAngled

		+COUNTITEM
		Inventory.Amount 500;
		Inventory.PickupSound "pickups/cup";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			TREC C -1;
			Stop;
	}
}

class Chest : Score
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Treasure
		//$Color 14
		//$NotAngled

		+COUNTITEM
		Inventory.Amount 1000;
		Inventory.PickupSound "pickups/chest";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			TREC D -1;
			Stop;
	}
}

class Crown : Score
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Treasure
		//$Color 14
		//$NotAngled

		+COUNTITEM
		Inventory.Amount 5000;
		Inventory.PickupSound "pickups/crown";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			TREC B -1;
			Stop;
	}
}

class Life : CustomInventory
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health
		//$Color 1
		//$NotAngled

		+COUNTITEM
		+Inventory.AUTOACTIVATE
		Inventory.Amount 1;
		Inventory.MaxAmount 0;
		Inventory.PickupSound "pickups/life";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			LIFE A -1;
			Loop;
		Pickup:
			LIFE A 0 {
				A_GiveInventory("Health", 100);
				A_GiveInventory("WolfClip", 25);

				LifeHandler.GiveLife(self);

				return true;
			}
			Stop;
	}
}

class BoneswithBlood : Health
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health
		//$Title Pool of Blood (with bones)
		//$Color 1
		//$NotAngled

		+Inventory.AUTOACTIVATE
		Inventory.Amount 1;
		Inventory.MaxAmount 11;
		Inventory.PickupSound "slurpie";
		Inventory.PickupMessage "";
	}
	States
	{
		Spawn:
			HLTH B -1;
			Loop;
	}
}

class WoodBarrel : ClassicDecoration
{
	Default
	{
		//$Title Barrel (Wooden)
		Height 30;
	}

	States
	{
		Spawn:
			BAR2 A -1;
			Stop;
	}
} 

class WellwithWater : ClassicDecoration
{
	Default
	{
		//$Title Well (with water)
		Height 30;
	}

	States
	{
		Spawn:
			WEL1 A -1;
			Stop;
	}
} 

class DryWell : ClassicDecoration
{
	Default
	{
		//$Title Well (dry)
		Height 30;
	}

	States
	{
		Spawn:
			WEL2 A -1;
			Stop;
	}
} 

class PoolofBlood : BonesWithBlood
{
	Default
	{
		//$Title Pool of Blood
	}

	States
	{
		Spawn:
			HLTH A -1;
			Loop;
	}
}

class NaziFlag : ClassicDecoration
{
	Default
	{
		//$Title Flag (Nazi)
		Height 64;
	}

	States
	{
		Spawn:
			FLAC A -1;
			Stop;
	}
}

class AardwolfSign : ClassicDecoration
{
	Default
	{
		//$Title Sign (Aardwolf)
		Height 64;
	}

	States
	{
		Spawn:
			AARD A -1;
			Stop;
	}
}

class CrushedBones1 : ClassicDecoration
{
	Default
	{
		//$Title Crushed Bones 1
		-SOLID
	}

	States
	{
		Spawn:
			POB2 C -1;
			Stop;
	}
} 

class CrushedBones2 : ClassicDecoration
{
	Default
	{
		//$Title Crushed Bones 2
		-SOLID
	}

	States
	{
		Spawn:
			POB3 A -1;
			Stop;
	}
} 

class CrushedBody : ClassicDecoration
{
	Default
	{
		//$Title Crushed Bones 3
		-SOLID
	}

	States
	{
		Spawn:
			POB4 A -1;
			Stop;
	}
} 

class HangingUtensils : ClassicDecoration
{
	Default
	{
		//$Title Hanging Pots and Pans
		-SOLID
		+SPAWNCEILING
		+NOGRAVITY
		Height 64;
	}

	States
	{
		Spawn:
			POT2 A -1;
			Stop;
	}
} 

class Stove : ClassicDecoration
{
	Default
	{
		Height 64;
	}

	States
	{
		Spawn:
			STOV A -1;
			Stop;
	}
} 

class SpearRack : ClassicDecoration
{
	Default
	{
		//$Title Spear Rack
		Height 64;
	}

	States
	{
		Spawn:
			SPEC A -1;
			Stop;
	}
} 

class HangingVines : ClassicDecoration
{
	Default
	{
		//$Title Hanging Vines
		-SOLID
		+SPAWNCEILING
		+NOGRAVITY
	}

	States
	{
		Spawn:
			VINE A -1;
			Stop;
	}
}

class DeadGuard : ClassicDecoration
{
	Default
	{
		//$Title Dead Guard
		Scale 1.0;
	}

	States
	{
		Spawn:
			WBRN N -1;
			Stop;
	}
}

class SkullsonStick : ClassicDecoration
{
	Default
	{
		//$Title Stick (with skulls)
		Height 64;
	}

	States
	{
		Spawn:
			HEL3 A -1;
			Stop;
	}
} 

class BloodyCage : ClassicDecoration
{
	Default
	{
		//$Title Cage (Bloody)
		Height 64;
	}

	States
	{
		Spawn:
			HEL4 A -1;
			Stop;
	}
} 

class CageofSkulls : ClassicDecoration
{
	Default
	{
		//$Title Cage (with skulls)
		Height 64;
	}

	States
	{
		Spawn:
			HEL2 A -1;
			Stop;
	}
} 

class RedCeilingLight : ClassicDecoration
{
	Default
	{
		//$Title Ceiling Light (Red)
		-SOLID
	}

	States
	{
		Spawn:
			LITR A -1;
			Stop;
	}
} 

class BullHeadonStick : ClassicDecoration
{
	Default
	{
		//$Title Stick (with bull head)
		Height 64;
	}

	States
	{
		Spawn:
			HEL1 A -1;
			Stop;
	}
} 

class BloodyWell : ClassicDecoration
{
	Default
	{
		//$Title Well (bloody)
		Height 64;
	}

	States
	{
		Spawn:
			HEL5 A -1;
			Stop;
	}
}

class AngelofDeathStatue : ClassicDecoration
{
	Default
	{
		//$Title Statue (Angel of Death)
		Height 64;
	}

	States
	{
		Spawn:
			ADTH A -1;
			Stop;
	}
} 

class BrownColumn : ClassicDecoration
{
	Default
	{
		//$Title Column (Brown)
		Height 64;
	}

	States
	{
		Spawn:
			COL2 A -1;
			Stop;
	}
}

class Truck : ClassicDecoration
{
	Default
	{
		Height 64;
		Radius 32;
		+SOLID
		+FLOORCLIP
		+SHOOTABLE
		+INVULNERABLE
		+NODAMAGETHRUST
	}

	States
	{
		Spawn:
			WTRK A -1 NoDelay A_StartSound("truck/idle", CHAN_AUTO, CHANF_LOOP);
			Stop;
	}
}

class SpearofDestiny : Inventory
{
	int actiontime;

	Default
	{
		//$Category Wolfenstein 3D/Items
		//$Title Spear of Destiny
		Inventory.Amount 1;
		Inventory.PickupSound "spear/pickup";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			SOFD A -1;
			Loop;
	}

	override void Tick()
	{
		Super.Tick();

		if (owner)
		{
			if (!actiontime && Game.IsSoD() && level.levelnum % 100 == 18)
			{
				actiontime = level.time + 70;
				InterHubAmount = 0;
			}
			if (level.time == actiontime) { level.ExitLevel(0, true); }
		}
	}
}

class PoolofWaterLost : PoolofWater
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Pool of Water (Lost)
	}

	States
	{
		Spawn:
			POL2 A -1;
			Stop;
	}
} 

class OilDrumLost : OilDrum
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Barrel (Oil Drum, Lost)
	}

	States
	{
		Spawn:
			BAR3 A -1;
			Stop;
	}
} 

class TableandChairsLost : TableandChairs
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Table and Chairs (Lost)
	}

	States
	{
		Spawn:
			TAB3 A -1;
			Stop;
	}
} 

class FloorLampLost : FloorLamp
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Floor Lamp (Lost)
	}

	States
	{
		Spawn:
			LIT2 A -1 Bright;
			Stop;
	}
} 

class HangingChandelierLost : HangingChandelier
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Hanging Chandelier (Lost)
	}

	States
	{
		Spawn:
			LIT4 A -1 Bright;
			Stop;
	}
} 

class HangingSkeletonLost : HangingSkeleton
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Hanging Skeleton (Lost)
	}

	States
	{
		Spawn:
			HNG2 A -1;
			Stop;
	}
} 

class DogFoodLost : DogFood
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Dog Food (Lost)
	}

	States
	{
		Spawn:
			HLTH H -1;
			Loop;
	}
}

class StoneColumnLost : StoneColumn
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Column (Stone, Lost)
	}

	States
	{
		Spawn:
			PILW A -1;
			Stop;
	}
}

class PlantLost : Plant
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Plant (Lost)
	}
	
	States
	{
		Spawn:
			PLT3 A -1;
			Stop;
	}
} 

class SkeletonLost : Skeleton
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Skeleton (Lost)
	}
	
	States
	{
		Spawn:
			BONE B -1;
			Stop;
	}
} 

class PileofSkullsLost : Sink
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Gore (Pile of Skulls, Lost)
	}
	
	States
	{
		Spawn:
			POSK A -1;
			Stop;
	}
} 

class BrownPlantLost : PlantinVase
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Plant (Brown, Lost)
	}
	
	States
	{
		Spawn:
			PLT4 A -1;
			Stop;
	}
} 

class VaseLost : Vase
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Vase (Lost)
	}
	
	States
	{
		Spawn:
			VAS2 A -1;
			Stop;
	}
} 

class TableLost : Table
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Table (Lost)
	}
	
	States
	{
		Spawn:
			TAB4 A -1;
			Stop;
	}
} 

class GreenCeilingLightLost : GreenCeilingLight
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Ceiling Light (Green, Lost)
	}
	
	States
	{
		Spawn:
			LIT6 A -1 Bright;
			Stop;
	}
}

class CagewithBloodLost : ClassicDecoration
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Cage (Blood, Lost)
	}
	
	Default
	{
		+SPAWNCEILING
		+NOGRAVITY
		Height 64;
	}

	States
	{
		Spawn:
			CAG6 A -1;
			Stop;
	}
} 

class SuitofArmorLost : SuitofArmor
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Suit of Armor (Lost)
	}
	
	States
	{
		Spawn:
			KNIG B -1;
			Stop;
	}
} 

class EmptyCageLost : EmptyCage
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Cage (Empty, Lost)
	}
	
	States
	{
		Spawn:
			CAG3 A -1;
			Stop;
	}
} 

class BrokenCageLost : Cage
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Cage (Broken, Lost)
	}
	
	Default
	{
		+SPAWNCEILING
		+NOGRAVITY
		Height 64;
	}

	States
	{
		Spawn:
			CAG4 A -1;
			Stop;
	}
} 

class Bones1Lost : Bones
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Crushed Bones 4 (Lost)
	}
	
	States
	{
		Spawn:
			POB6 A -1;
			Stop;
	}
} 

class YellowKeyLost : YellowKey
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Keys/Lost Episodes
		//$Title Key (Gold, Lost)
	}
	
	States
	{
		Spawn:
			KEYS C -1;
			Stop;
	}
}

class BlueKeyLost : BlueKey
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Keys/Lost Episodes
		//$Title Key (Silver, Lost)
	}
	
	States
	{
		Spawn:
			KEYS D -1;
			Stop;
	}
}

class CageWithSkullsLost : Bed
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Cage (with skulls, Lost)
	}
	
	States
	{
		Spawn:
			CAG5 A -1;
			Stop;
	}
} 

class DeadRatLost : Basket
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Dead Rat (Lost)
	}
	
	States
	{
		Spawn:
			DRAT A -1;
			Stop;
	}
}

class PlateofFoodLost : PlateOfFood
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health/Lost Episodes
		//$Title Plate of Food (Lost)
	}
	
	States
	{
		Spawn:
			HLTH I -1;
			Loop;
	}
}

class FirstAidKitLost : FirstAidKit
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health/Lost Episodes
		//$Title First Aid Kit (Lost)
	}
	
	States
	{
		Spawn:
			HLTH J -1;
			Loop;
	}
}

class RadioLost : JeweledCross
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Treasure/Lost Episodes
		//$Title Radio (Lost)
	}
	
	States
	{
		Spawn:
			TREA E -1;
			Stop;
	}
}

class ShellLost : Chalice
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Treasure/Lost Episodes
		//$Title Shell (Lost)
	}
	
	States
	{
		Spawn:
			TREA G -1;
			Stop;
	}
}

class TimerLost : Chest
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Treasure/Lost Episodes
		//$Title Timer (Lost)
	}
	
	States
	{
		Spawn:
			TREA H -1;
			Stop;
	}
}

class BombLost : Crown
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Treasure/Lost Episodes
		//$Title Bomb (Lost)
	}
	
	States
	{
		Spawn:
			TREA F -1;
			Stop;
	}
}

class LifeLost : Life
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health/Lost Episodes
		//$Title Life (Lost)
	}
	
	States
	{
		Spawn:
			LIFE B -1;
			Loop;
	}
}

class BoneswithBloodLost : BoneswithBlood
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health/Lost Episodes
		//$Title Pool of Blood (with bones, Lost)
	}
	
	States
	{
		Spawn:
			HLTH G -1;
			Loop;
	}
}

class WoodBarrelLost : WoodBarrel
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Barrel (Wooden, Lost)
	}
	
	States
	{
		Spawn:
			BAR4 A -1;
			Stop;
	}
} 

class WellwithWaterLost : WellwithWater
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Well (with water, Lost)
	}
	
	States
	{
		Spawn:
			WEL3 A -1;
			Stop;
	}
} 

class DryWellLost : DryWell
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Well (dry, Lost)
	}
	
	States
	{
		Spawn:
			WEL4 A -1;
			Stop;
	}
} 

class PoolofBloodLost : PoolofBlood
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health/Lost Episodes
		//$Title Pool of Blood (Lost)
	}
	
	States
	{
		Spawn:
			HLTH F -1;
			Loop;
	}
}

class ElectrofieldLost : NaziFlag
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Electro-Field (Lost)
	}
	
	States
	{
		Spawn:
			GZMO A -1;
			Stop;
	}
}

class RedCeilingLightLost : AardwolfSign
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Ceiling Light (Red, Lost)
	}
	
	Default
	{
		-SOLID
	}

	States
	{
		Spawn:
			LIT7 A -1 Bright;
			Stop;
	}
}

class Bones2Lost : CrushedBones1
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Crushed Bones 1 (Lost)
	}
	
	States
	{
		Spawn:
			POB7 A -1;
			Stop;
	}
} 

class LightBulbLost : CrushedBones2
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Lightbulb (Lost)
	}
	
	States
	{
		Spawn:
			LIT8 A -1;
			Stop;
	}
} 

class SlimeLost : CrushedBody
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Pool of Slime (Lost)
	}
	
	States
	{
		Spawn:
			GGOO A -1;
			Stop;
	}
} 

class HLabTableLost : HangingUtensils
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Lab Table (Lost)
	}
	
	States
	{
		Spawn:
			TAB5 A -1;
			Stop;
	}
} 

class RadioactiveBarrelLost  : Stove
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Barrel (Radioactive, Lost)
	}
	
	States
	{
		Spawn:
			BAR5 A -1;
			Stop;
	}
} 

class PipeLost : SpearRack
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Pip (Lost)
	}
	
	States
	{
		Spawn:
			PIPE A -1;
			Stop;
	}
} 

class BubblesLost : HangingVines
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Bubbles (Lost)
	}
	
	States
	{
		Spawn:
			BUBL A -1;
			Stop;
	}
}

class DeadGuardLost : DeadGuard
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Dead Guard (Lost)
	}
	
	States
	{
		Spawn:
			WGRN N -1;
			Stop;
	}
}

class DemonStatueLost: BrownColumn
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Statue (Demon, Lost)
	}
	
	States
	{
		Spawn:
			DEVS A -1;
			Stop;
	}
}

class BJWasHereLost : Truck
{
	Default
	{
		//$Category Wolfenstein 3D/Decorations/Lost Episodes
		//$Title Sign (BJ was here, Lost)
	}
	
	States
	{
		Spawn:
			BJWH A -1;
			Stop;
	}
}

class SpearofDestinyLost : SpearofDestiny
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Lost Episodes
		//$Title Spear of Destiny (Lost)
		Inventory.PickupSound "spear/pickup2";
	}

	States
	{
		Spawn:
			SOFD B -1;
			Loop;
	}	
}

// Placeholder assigned to obsolete thing IDs generated by map conversion utility
class CompatibilityPlaceholder : Actor
{
	States
	{
		Spawn:
			TNT1 A 1;
			Stop;
	}		
}

class MoldyCheese : Health
{
	Default
	{
		//$Category Wolfenstein 3D/Items/Health
		//$Title Moldy Cheese
		//$Color 1
		//$NotAngled

		+Inventory.AUTOACTIVATE
		Inventory.Amount 4;
		Inventory.MaxAmount 100;
		Inventory.PickupSound "pickups/food";
		Inventory.PickupMessage "";
	}

	States
	{
		Spawn:
			HLTH K -1;
			Loop;
	}
}