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
		Height 30;
	}

	States
	{
		Spawn:
			BARL C -1;
			Stop;
	}
} 

class TableandChairs : ClassicDecoration
{
	Default
	{
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
		//$Category Wolfenstein 3D/Health
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
		Height 64;
	}

	States
	{
		Spawn:
			COLW A -1;
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
		//$Category Wolfenstein 3D/Health
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
		//$Category Wolfenstein 3D/Health
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

class JeweledCross : Score
{
	Default
	{
		//$Category Wolfenstein 3D/Treasure
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
		//$Category Wolfenstein 3D/Treasure
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
		//$Category Wolfenstein 3D/Treasure
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
		//$Category Wolfenstein 3D/Treasure
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
		//$Category Wolfenstein 3D/Health
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
		//$Category Wolfenstein 3D/Health
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
			if (!actiontime && Game.isSOD() && level.levelnum % 100 == 18)
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
	States
	{
		Spawn:
			POL2 A -1;
			Stop;
	}
} 

class OilDrumLost : OilDrum
{
	States
	{
		Spawn:
			BAR3 A -1;
			Stop;
	}
} 

class TableandChairsLost : TableandChairs
{
	States
	{
		Spawn:
			TAB3 A -1;
			Stop;
	}
} 

class FloorLampLost : FloorLamp
{
	States
	{
		Spawn:
			LIT2 A -1 Bright;
			Stop;
	}
} 

class HangingChandelierLost : HangingChandelier
{
	States
	{
		Spawn:
			LIT4 A -1 Bright;
			Stop;
	}
} 

class HangingSkeletonLost : HangingSkeleton
{
	States
	{
		Spawn:
			HNG2 A -1;
			Stop;
	}
} 

class DogFoodLost : DogFood
{
	States
	{
		Spawn:
			HLTH H -1;
			Loop;
	}
}

class StoneColumnLost : StoneColumn
{
	States
	{
		Spawn:
			PILW A -1;
			Stop;
	}
}

class PlantLost : Plant
{
	States
	{
		Spawn:
			PLT3 A -1;
			Stop;
	}
} 

class SkeletonLost : Skeleton
{
	States
	{
		Spawn:
			BONE B -1;
			Stop;
	}
} 

class PileofSkullsLost : Sink
{
	States
	{
		Spawn:
			POSK A -1;
			Stop;
	}
} 

class BrownPlantLost : PlantinVase
{
	States
	{
		Spawn:
			PLT4 A -1;
			Stop;
	}
} 

class VaseLost : Vase
{
	States
	{
		Spawn:
			VAS2 A -1;
			Stop;
	}
} 

class TableLost : Table
{
	States
	{
		Spawn:
			TAB4 A -1;
			Stop;
	}
} 

class GreenCeilingLightLost : GreenCeilingLight
{
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
	States
	{
		Spawn:
			KNIG B -1;
			Stop;
	}
} 

class EmptyCageLost : EmptyCage
{
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
	States
	{
		Spawn:
			POB6 A -1;
			Stop;
	}
} 

class YellowKeyLost : YellowKey
{
	States
	{
		Spawn:
			KEYS C -1;
			Stop;
	}
}

class BlueKeyLost : BlueKey
{
	States
	{
		Spawn:
			KEYS D -1;
			Stop;
	}
}

class CageWithSkullsLost : Bed
{
	States
	{
		Spawn:
			CAG5 A -1;
			Stop;
	}
} 

class DeadRatLost : Basket
{
	States
	{
		Spawn:
			DRAT A -1;
			Stop;
	}
}

class PlateofFoodLost : PlateOfFood
{
	States
	{
		Spawn:
			HLTH I -1;
			Loop;
	}
}

class FirstAidKitLost : FirstAidKit
{
	States
	{
		Spawn:
			HLTH J -1;
			Loop;
	}
}

class RadioLost : JeweledCross
{
	States
	{
		Spawn:
			TREA E -1;
			Stop;
	}
}

class ShellLost : Chalice
{
	States
	{
		Spawn:
			TREA G -1;
			Stop;
	}
}

class TimerLost : Chest
{
	States
	{
		Spawn:
			TREA H -1;
			Stop;
	}
}

class BombLost : Crown
{

	States
	{
		Spawn:
			TREA F -1;
			Stop;
	}
}

class LifeLost : Life
{
	States
	{
		Spawn:
			LIFE B -1;
			Loop;
	}
}

class BoneswithBloodLost : BoneswithBlood
{
	States
	{
		Spawn:
			HLTH G -1;
			Loop;
	}
}

class WoodBarrelLost : WoodBarrel
{
	States
	{
		Spawn:
			BAR4 A -1;
			Stop;
	}
} 

class WellwithWaterLost : WellwithWater
{
	States
	{
		Spawn:
			WEL3 A -1;
			Stop;
	}
} 

class DryWellLost : DryWell
{
	States
	{
		Spawn:
			WEL4 A -1;
			Stop;
	}
} 

class PoolofBloodLost : PoolofBlood
{
	States
	{
		Spawn:
			HLTH F -1;
			Loop;
	}
}

class ElectrofieldLost : NaziFlag
{
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
	States
	{
		Spawn:
			POB7 A -1;
			Stop;
	}
} 

class LightBulbLost : CrushedBones2
{
	States
	{
		Spawn:
			LIT8 A -1;
			Stop;
	}
} 

class SlimeLost : CrushedBody
{
	States
	{
		Spawn:
			GGOO A -1;
			Stop;
	}
} 

class HLabTableLost : HangingUtensils
{
	States
	{
		Spawn:
			TAB5 A -1;
			Stop;
	}
} 

class RadioactiveBarrelLost  : Stove
{
	States
	{
		Spawn:
			BAR5 A -1;
			Stop;
	}
} 

class PipeLost : SpearRack
{
	States
	{
		Spawn:
			PIPE A -1;
			Stop;
	}
} 

class BubblesLost : HangingVines
{
	States
	{
		Spawn:
			BUBL A -1;
			Stop;
	}
}

class DeadGuardLost : DeadGuard
{
	States
	{
		Spawn:
			WGRN N -1;
			Stop;
	}
}

class DemonStatueLost: BrownColumn
{ 
	States
	{
		Spawn:
			DEVS A -1;
			Stop;
	}
}

class BJWasHereLost : Truck
{
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
		Inventory.PickupSound "spear/pickup2";
	}

	States
	{
		Spawn:
			SOFD B -1;
			Loop;
	}	
}
