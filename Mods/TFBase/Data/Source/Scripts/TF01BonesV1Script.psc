Scriptname TF01BonesV1Script Extends Actor

import Game
import Utility
import TF01Utility

;======================================================================================;
;  PROPERTIES  /
;=============/

Actor Property PlayerRef Auto ; Least 'costly' way to refer to the player
{MANDATORY: The player reference}

Idle property BleedOutStart auto
{MANDATORY: The animation to play when Bones goes down}

Idle property BleedOutStop auto
{MANDATORY: The animation to play when Bones gets up}

int Property pMaxCarryWeight = 300 Auto
{OPTIONAL: Maximum carry weight before over encumbered. DEFAULT = 300}

int Property pLevelAbovePlayer = 0 Auto
{OPTIONAL: Level above player (positive) or below the player (negative). DEFAULT = 0}

bool Property pIgnoreFriendlyHits = true Auto
{OPTIONAL: Boolean to determine if Bones should ignore friendly hits. DEFAULT = true}

float Property pIncapacitateEnterHealthPercentage = 0.1 Auto
{OPTIONAL: Health percentage to enter the incapcitated state. DEFAULT = 0.1}

float Property pIncapacitateExitHealthPercentage = 0.5 Auto
{OPTIONAL: Health percentage to exit the incapcitated state. DEFAULT = 0.5}

;======================================================================================;
;  LOCAL VARIABLES  /
;=============/

int currentLevel
bool isOverencumbered
bool isIncapacitated

;======================================================================================;
;  CONSTANTS  /
;=============/

;  https://www.creationkit.com/index.php?title=Actorvalue
string ACTOR_VALUE_HEALTH = "Health"
string ACTOR_VALUE_STAMINA = "Stamina"
string ACTOR_VALUE_ONE_HANDED = "OneHanded"
string ACTOR_VALUE_TWO_HANDED = "TwoHanded"
string ACTOR_VALUE_HEAVY_ARMOR = "HeavyArmor"
string ACTOR_VALUE_BLOCK = "Block"
string ACTOR_VALUE_SNEAK = "Sneak"

int ACTOR_VALUE_MAX_SKILL = 100

float UPDATE_INTERVAL_SECONDS = 0.5

;======================================================================================;
;  FUNCTIONS  /
;=============/

int Function GetTotalWeight()
	return Math.Ceiling((self as ObjectReference).GetTotalItemWeight())
EndFunction

Function SetOverencumbered(bool abOverencumbered)
	self.SetDontMove(abOverencumbered)
	isOverencumbered = abOverencumbered
EndFunction

Function SetIncapacitated(bool abIncapacitated)
	If abIncapacitated
		self.SetNoBleedoutRecovery(true)
		self.PlayIdle(BleedOutStart)
	    isIncapacitated = true
	Else
		self.SetNoBleedoutRecovery(false)
		self.PlayIdle(BleedOutStop)
	    isIncapacitated = false
	EndIf
EndFunction

;======================================================================================;
;  EVENTS  /
;=============/

; This is within the "empty" state
Event OnInit() ; This event will run once, when the script is initialized
	self.IgnoreFriendlyHits(pIgnoreFriendlyHits)
	currentLevel = self.GetLevel()
	isOverencumbered = false
	isIncapacitated = false

	self.AllowBleedoutDialogue(true)
	self.SetNotShowOnStealthMeter(true)
EndEvent

Event OnUpdate()
	; Periodically check if we need to exit the incapacitated state
	If isIncapacitated 
		float healthPercentage = self.GetActorValuePercentage(ACTOR_VALUE_HEALTH)

		if healthPercentage > pIncapacitateExitHealthPercentage
			SetIncapacitated(false)

			; We no longer want any update events
			UnregisterForUpdate()
		EndIf

		; Check again after delay
		RegisterForSingleUpdate(UPDATE_INTERVAL_SECONDS) ; OnUpdate will be called one more time.
	EndIf 
EndEvent

Event OnLoad()
	int playerLevel = PlayerRef.GetLevel()
	int newLevel = playerLevel + pLevelAbovePlayer

	If newLevel <= 0 
		newLevel = 1 ; Ensure 1 is the minimum level
	EndIf

	If (currentLevel < newLevel)
		float oldHealth = self.GetActorValue(ACTOR_VALUE_HEALTH)
		float oldStamina = self.GetActorValue(ACTOR_VALUE_STAMINA)
		float oldOneHanded = self.GetActorValue(ACTOR_VALUE_ONE_HANDED)
		float oldTwoHanded = self.GetActorValue(ACTOR_VALUE_TWO_HANDED)
		float oldHeavyArmor = self.GetActorValue(ACTOR_VALUE_HEAVY_ARMOR)
		float oldBlock = self.GetActorValue(ACTOR_VALUE_BLOCK)
		float oldSneak = self.GetActorValue(ACTOR_VALUE_SNEAK)

		int levelIncrease = playerLevel - currentLevel
		float healthIncrease = 10 * levelIncrease
		float staminaIncrease = 5 * levelIncrease 
		float oneHandedIncrease = 2 * levelIncrease
		float twoHandedIncrease = 2 * levelIncrease
		float heavyArmorIncrease = 1 * levelIncrease
		float blockIncrease = 1 * levelIncrease
		float sneakIncrease = 1 * levelIncrease

		float proposedHealth = oldHealth + healthIncrease
		float proposedStamina = oldStamina + staminaIncrease
		float proposedOneHanded = oldOneHanded + oneHandedIncrease
		float proposedTwoHanded = oldTwoHanded + twoHandedIncrease
		float proposedHeavyArmor = oldHeavyArmor + heavyArmorIncrease
		float proposedBlock = oldBlock + blockIncrease
		float proposedSneak = oldSneak + sneakIncrease
		
		;  Cater for max skill value		
		If (proposedOneHanded > ACTOR_VALUE_MAX_SKILL)
			oneHandedIncrease = ACTOR_VALUE_MAX_SKILL - oldOneHanded
		EndIf

		If (proposedTwoHanded > ACTOR_VALUE_MAX_SKILL)
			twoHandedIncrease = ACTOR_VALUE_MAX_SKILL - oldTwoHanded
		EndIf

		If (proposedHeavyArmor > ACTOR_VALUE_MAX_SKILL)
			heavyArmorIncrease = ACTOR_VALUE_MAX_SKILL - oldHeavyArmor
		EndIf

		If (proposedBlock > ACTOR_VALUE_MAX_SKILL)
			blockIncrease = ACTOR_VALUE_MAX_SKILL - oldBlock
		EndIf	

		If (proposedSneak > ACTOR_VALUE_MAX_SKILL)
			sneakIncrease = ACTOR_VALUE_MAX_SKILL - oldSneak
		EndIf	

		; Modify values unless max

		self.ModActorValue(ACTOR_VALUE_HEALTH, healthIncrease)
		self.ModActorValue(ACTOR_VALUE_STAMINA, staminaIncrease)

		If (oneHandedIncrease > 0)
			self.ModActorValue(ACTOR_VALUE_ONE_HANDED, oneHandedIncrease)
		EndIf

		If (twoHandedIncrease > 0)
			self.ModActorValue(ACTOR_VALUE_TWO_HANDED, twoHandedIncrease)
		EndIf

		If (heavyArmorIncrease > 0)
			self.ModActorValue(ACTOR_VALUE_HEAVY_ARMOR, heavyArmorIncrease)
		EndIf

		If (blockIncrease > 0)
			self.ModActorValue(ACTOR_VALUE_BLOCK, blockIncrease)
		EndIf

		If (sneakIncrease > 0)
			self.ModActorValue(ACTOR_VALUE_SNEAK, sneakIncrease)
		EndIf

		currentLevel = newLevel
	EndIf
EndEvent

Event OnHit(ObjectReference akAggressor, Form weap, Projectile proj, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	float healthPercentage = self.GetActorValuePercentage(ACTOR_VALUE_HEALTH)
	If healthPercentage < pIncapacitateEnterHealthPercentage && !isIncapacitated
		SetIncapacitated(true)
		Debug.Notification("Bones has been incapacitated")
		RegisterForSingleUpdate(UPDATE_INTERVAL_SECONDS) ; OnUpdate will be called once.
	EndIf
EndEvent

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	If SKSEVersionCompare(1, 7, 2) >= 0
		int carryWeight = GetTotalWeight()
	
		If carryWeight >= pMaxCarryWeight
			If !isOverencumbered
			    SetOverencumbered(true)
				Debug.Notification("Bones is overencumbered")
			EndIf		
		EndIf
	EndIf
EndEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	If SKSEVersionCompare(1, 7, 2) >= 0
		int carryWeight = GetTotalWeight()
	
		If carryWeight < pMaxCarryWeight
			If isOverencumbered
				SetOverencumbered(false)
				Debug.Notification("Bones is no longer overencumbered")
			EndIf	
		EndIf
	EndIf
EndEvent
