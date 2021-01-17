ScriptName TF01RestoreHealthPercentageMagicEffect extends activeMagicEffect
{Heals X percent of actors health}

;======================================================================================;
;  CONSTANTS  /
;=============/

string ACTOR_VALUE_HEALTH = "Health"

;======================================================================================;
;  PROPERTIES  /
;=============/

float Property PercentageOfMaxHealth = 0.1 auto
{MANDATORY: percentage of max health}

bool Property RunInDebugMode = false Auto
{OPTIONAL: runs this script in debug mode - defaults to false}

Event OnEffectStart(Actor akTarget, Actor akCaster)
	RestoreHealthPercentage(akTarget, PercentageOfMaxHealth)
endEVENT

Function RestoreHealthPercentage(Actor akTarget, float percentageOfMaxHealth)
	int totalHealth = akTarget.GetBaseActorValue("Health") as int
	int restoreAmount = ((totalHealth * percentageOfMaxHealth) as int)

	If (RunInDebugMode)
		Debug.MessageBox("Restoring " + restoreAmount + "/" + totalHealth + " Health")
	EndIf
	
	akTarget.RestoreActorValue(ACTOR_VALUE_HEALTH, restoreAmount)
EndFunction
