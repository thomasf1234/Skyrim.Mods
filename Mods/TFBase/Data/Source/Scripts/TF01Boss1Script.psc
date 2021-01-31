scriptName TF01Boss1Script extends Actor
{Attempt at a generic script for a Boss}

import game
import utility

;======================================================================================;
;  PROPERTIES  /
;=============/

float Property HitCoolDownSeconds = 2.0 Auto

MusicType Property MUSCombatBoss  Auto 

Activator property teleportBase auto
{Base object to search for as a teleport point}

ImageSpaceModifier Property pImageSpaceModifier Auto

Activator property pTeleportFX Auto
float property pTeleportMinWaitTimeUntilExit = 0.0 Auto
float property pTeleportMaxWaitTimeUntilExit = 1.0 Auto
float property pTeleportChanceOnHit = 0.0 Auto

Spell[] Property pMediumHealthSpells Auto

int Property pSpecial1Index Auto
int Property pSpecial2Index Auto
int Property pSpecial3Index Auto
int Property pSpecialSummon1Index Auto

bool RunInDebugMode = false
;bool Property RunInDebugMode = false Auto
;{OPTIONAL: runs this script in debug mode - defaults to false}

float Property pMediumHealthThreshold = 0.7 Auto
{OPTIONAL: Health percentage before the actor will transition into the MediumHealth state.  DEFAULT = 0.7}

float Property pLowHealthThreshold = 0.2 Auto
{OPTIONAL: Health percentage before the actor will transition into the LowHealth state.  DEFAULT = 0.2}


int Property pMinHitsUntilSpecialThreshold = 2 Auto
{OPTIONAL: Minimum number of hits I'll take before entering a special state.  DEFAULT = 2}
int Property pMaxHitsUntilSpecialThreshold = 10 Auto
{OPTIONAL: Maximum number of hits I'll take before entering a special state.  DEFAULT = 10}


int Property pMinSecondsUntilSpecialThreshold = 10 Auto
{OPTIONAL: Minimum number of seconds that will elapse before entering a special state.  DEFAULT = 10}
int Property pMaxSecondsUntilSpecialThreshold = 60 Auto
{OPTIONAL: Maximum number of seconds that will elapse before entering a special state.  DEFAULT = 60}

; FormList Property AIIPackageList Auto
; Package[] Property Packages Auto
; Use emptyActivator alongside the boss that follows the opponents position, for use when targeting magic
;======================================================================================;
;  CONSTANTS  /
;=============/

;  https://www.creationkit.com/index.php?title=Actorvalue
;  Variable06 is used as a package condition to control his combat state. It will be used here and set to the state index
string ACTOR_VALUE_COMBAT_STATE = "Variable06"

string STATE_EMPTY = ""
string STATE_INITIALIZING = "Initializing"
string STATE_INITIALIZED = "Initialized"

string STATE_HIGH_HEALTH = "HighHealth"
string STATE_MEDIUM_HEALTH = "MediumHealth"
string STATE_LOW_HEALTH = "LowHealth"

; Temporary states
string STATE_CASTING = "Casting"

; Combat state indexes
int COMBAT_STATE_INDEX_DEFAULT = 0

int DEBUG_SEVERITY_WARNING = 1
int DEBUG_SEVERITY_ERROR = 2

float UPDATE_INTERVAL_SECONDS = 1.0

;======================================================================================;
;  LOCAL VARIABLES  /
;=============/

Actor _opponent

float battleStartTimeSeconds
float lastRecordedHitSeconds
int _hitCounter
int _hitsUntilSpecialThreshold
float _nextSummondThresholdSeconds
float secondsUntilSpecialThreshold
bool isDying
bool inBleedout
bool isInitialized 
string[] States
ObjectReference[] teleportPoints
Spell[] currentSpells
string prevState
float prevHealthPercentage

bool isProcessingOnUpdateOROnHitEvent = false

; OnHit variables
ObjectReference _prevOnHitAggressor
Form _prevOnHitWeap 
Projectile _prevOnHitProj
bool _prevOnHitPowerAttack
bool _prevOnHitSneakAttack
bool _prevOnHitBashAttack
bool _prevOnHitHitBlocked

;======================================================================================;
;  EMPTY STATE  /
;=============/

; This is within the "empty" state
; Event called when the script has been created and all its properties have been initialized. Until OnInit has finished running, your script
; will not receive any events, and other scripts that try to call functions or access properties on your script will be paused until the event finishes.
; Event OnInit() ; This event will run once, when the script is initialized
; 	Debug.Trace("Entered OnInit")
; EndEvent

;======================================================================================;
;  EVENTS  /
;=============/

; Initial trigger, starts the boss fight
; aeCombatState: The combat state we just entered, which will be one of the following:
; 0: Not in combat
; 1: In combat
; 2: Searching
Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	Debug.Trace("Entered OnCombatStateChanged")

	int IN_COMBAT = 1
	If (aeCombatState == IN_COMBAT)
		_opponent = akTarget
		EnsureInitialized()
	Else
		; TODO revoke _opponent when not in combat
	EndIf
EndEvent

;Every second or OnHit, we evaluate the state.
Function OnUpdate()
	Debug.Trace("Entered OnUpdate")
	If (isInitialized)
		If (IsAlive(self))
			bool isOnHit = false
			ProcessOnUpdateOROnHitEvent(isOnHit)
	
			; Register for another update scheduled in UPDATE_INTERVAL_SECONDS second
			RegisterForSingleUpdate(UPDATE_INTERVAL_SECONDS)
		EndIf
	EndIf
EndFunction

Event OnHit(ObjectReference akAggressor, Form weap, Projectile proj, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	Debug.Trace("Entered OnHit")

	If (isInitialized)
		If (IsAlive(self))
			; Set OnHit variables so they're available for later evaluation
			SetOnHitVariables(akAggressor, weap, proj, abPowerAttack, abSneakAttack, abBashAttack, abHitBlocked)
	
			bool isOnHit = true
			ProcessOnUpdateOROnHitEvent(isOnHit)
		EndIf
	EndIf
EndEvent

Event onEnterBleedout()
	inBleedout = TRUE
	; For now never reset this boolean.  Considering it part of the flow that bleeding out turns the ability off
EndEvent

Event OnDying(Actor akKiller)
	isDying = true
EndEvent

Event OnDeath(Actor akKiller)
	isDying = false
	Debug.Notification("Removing music")
	MUSCombatBoss.Remove()
EndEvent

;======================================================================================;
;  CUSTOM EVENTS  /
;=============/

; Note : These events are called manually and are therefore SYNCHRONOUS

Event OnEvaluationStart(bool abIsOnHit)
	; Called at the start of the regular state evaulation, before updates are applied
EndEvent

Event OnEvaluationEnd(bool abIsOnHit)
	; Called at the end to the regular state evaulation, after updates have been applied
EndEvent

Event OnHitRecord(bool abHitThresholdReached, int aiHitThreshold, int aiHitCounter)
	If (IsDebug())
		Debug.MessageBox("Hit has been recorded. We are at " + aiHitCounter + " hits, but the threshold is set at " + aiHitThreshold)
	EndIf	
EndEvent

Event OnTeleportEnter()
	If (IsDebug())
		Debug.MessageBox("Just entered a teleportation portal")
	EndIf	
EndEvent

Event OnTeleportExit()
	If (IsDebug())
		Debug.MessageBox("Just exited a teleportation portal")
	EndIf	
EndEvent

Event OnMediumHealth()
	If (IsDebug())
		Debug.MessageBox("Medium health threshold reached! " + pMediumHealthThreshold)
	EndIf	
EndEvent

Event OnLowHealth()
	If (IsDebug())
		Debug.MessageBox("Low health threshold reached! " + pLowHealthThreshold)
	EndIf	
EndEvent

;======================================================================================;
;  FUNCTIONS  /
;=============/

bool Function IsDebug()
	return RunInDebugMode
EndFunction

Function EnsureInitialized()
	if (!isInitialized && !isInitializing())
		GotoState(STATE_INITIALIZING)
	endIf
EndFunction

bool Function isInitializing()
	return GetState() == STATE_INITIALIZING
EndFunction

Function SetOnHitVariables(ObjectReference akAggressor, Form weap, Projectile proj, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	_prevOnHitAggressor = akAggressor
	_prevOnHitWeap = weap
	_prevOnHitProj= proj
	_prevOnHitPowerAttack = abPowerAttack
	_prevOnHitSneakAttack = abSneakAttack
	_prevOnHitBashAttack = abBashAttack
	_prevOnHitHitBlocked = abHitBlocked
EndFunction

Function InitializeStates()
	; Overridden within 'Initializing' state
EndFunction

Function InitializeTeleportPoints()
	; Overridden within 'Initializing' state
EndFunction

; Formally sets the state on the actor, must be called instead of GotoState()
Function SetState(string asNewState, int combatStateIndex = 0)
	string currentState = GetState()
	int stateIndex = States.Find(asNewState)

	If (stateIndex < 0)
		string errorMessage = "State <" + asNewState + "> not found."
		Debug.Trace(errorMessage, DEBUG_SEVERITY_WARNING)
		If (IsDebug())
			Debug.MessageBox(errorMessage)
		EndIf
	ElseIf (asNewState == currentState)
		string skipMessage = "Already in state " + asNewState
		Debug.Trace(skipMessage)
	Else
		string transitionMessage = "Transitioning state from <" + GetState() + "> to <" + asNewState + ">"
		Debug.Trace(transitionMessage)
		If (IsDebug())
			Debug.MessageBox(transitionMessage)
		EndIf

		; Record current state as previous state
		prevState = currentState

		; TODO - must revert to a default state index as a way to disable stateIndex before calling GotoState because OnEndState may make changes necessary to maintain the current state AI packages
		GotoState(asNewState) ; GotoState doesn't return until the OnEndState event of the current state and the OnBeginState event of the new state finish running. (And the events won't overlap)
		; Note that stateIndex is only applied after the state has returned from OnBeginState

		; Need to set the actor value that is used when determining AI packages that are attached to our actor
		SetActorValue(ACTOR_VALUE_COMBAT_STATE, combatStateIndex)

		; Evaluate AI package stack for any changes that are now in effect
		EvaluatePackage()
	EndIf
EndFunction

; TODO : Change this implementation (Called OnEnd of AI packages)
Function FinishedTempState()
	SetState(prevState)
EndFunction

Function PackageFinishedSummoning(float aDurationSeconds)
	_nextSummondThresholdSeconds =  Utility.GetCurrentRealTime() + aDurationSeconds
	SetState(prevState)
EndFunction

bool Function IsAlive(Actor akActor)
	return !IsDying && !IsDead()
EndFunction

Function SetSpells(Spell[] akSpells)
	int i

	i = 0
	; First try removing spells not in our new list
	While (i < currentSpells.Length)
	  Spell s = currentSpells[i]

	  ; If we can't find the spell but we know it, then unlearn it
	  If (akSpells.Find(s) < 0 && HasSpell(s))
		RemoveSpell(s)
	  EndIf
	  
	  i += 1
	EndWhile

	; Set currentSpells to akSpells
	currentSpells = akSpells

	i = 0
	While (i < currentSpells.Length)
	  Spell s = currentSpells[i]

	  ; If we don't know the spell, then learn it
	  If (!HasSpell(s))
		AddSpell(s)
	  EndIf
	  
	  i += 1
	EndWhile
EndFunction

Function ResetHitCounter()
	_hitCounter = 0
	_hitsUntilSpecialThreshold = RandomInt(pMinHitsUntilSpecialThreshold, pMaxHitsUntilSpecialThreshold)
	if (IsDebug())
		Debug.MessageBox("Reset HitCounter to 0 with next threshold set at " + _hitsUntilSpecialThreshold)
	EndIf	
EndFunction

Function EvaluateHit()
	float currentSeconds = Utility.GetCurrentRealTime()
	float secondsSinceLastRecordedHit = currentSeconds - lastRecordedHitSeconds
	; Only record a hit if we're outside of the cool down period and the actor is not in an invulnerable state
	if (secondsSinceLastRecordedHit > HitCoolDownSeconds && !GetActorBase().IsInvulnerable())
		_hitCounter += 1
		lastRecordedHitSeconds = currentSeconds	

		; Check if we reached the threshold
		bool reachedHitThreshold = _hitCounter >= _hitsUntilSpecialThreshold

		; Trigger synchronous OnHitRecord
		OnHitRecord(reachedHitThreshold, _hitsUntilSpecialThreshold, _hitCounter)

		; Reset hit counter if we have reached the threshold
		If (reachedHitThreshold)
			ResetHitCounter()
		EndIf
	else
		Debug.Trace("Skipping recording hit - too frequent")
	endIf
EndFunction	

Function EvaluateHealth()
	float currentHealthPercentage = GetAVPercentage("Health")
	
	; TODO add interval logic for return to higher state through healing health
	If (prevHealthPercentage > pMediumHealthThreshold && currentHealthPercentage <= pMediumHealthThreshold)
		OnMediumHealth()		
	ElseIf (prevHealthPercentage > pLowHealthThreshold && currentHealthPercentage <= pLowHealthThreshold)
		OnLowHealth()
	EndIf

	prevHealthPercentage = currentHealthPercentage
	; Override
EndFunction	

Function EvaluateTeleport()
	ObjectReference teleportPoint
		
	If (GetDistance(_opponent) < 300)
		; If opponent is close then try teleporting away
		teleportPoint = FindTeleportPointAwayFromActor(_opponent)
	Else
		; If opponent is not close and we've been hit it could be a projectile
		teleportPoint = _opponent
	EndIf	

	If (teleportPoint != None)
		Teleport(teleportPoint, RandomFloat(0.0, 2.0))
	EndIf	
EndFunction

Function ProcessOnUpdateOROnHitEvent(bool abIsOnHit)
	; Only needed to avoid asynchronous concurrent evaluation threads
	If (!isProcessingOnUpdateOROnHitEvent)
		; Lock
		isProcessingOnUpdateOROnHitEvent = true 

		; Trigger OnEvaluationStart so state specific logic can run before evaluation 
		OnEvaluationStart(abIsOnHit)

		; Calculate whether or not we need to change state
		EvaluateHealth()

		If (abIsOnHit)
			; Evaluate our hit 
		    EvaluateHit()
		EndIf

		; Trigger OnEvaluationEnd so state specific logic can run after evaluation 
		OnEvaluationEnd(abIsOnHit)
	
		; Unlock
		isProcessingOnUpdateOROnHitEvent = false
	EndIf
EndFunction

Function UnequipSpells(Actor akActor)
	; Unequip spells
	int equippedSpellIndex = 0
	While (equippedSpellIndex < 3)
		Spell equippedSpell = GetEquippedSpell(equippedSpellIndex)
		If (equippedSpell != None)
			UnequipSpell(equippedSpell, equippedSpellIndex) ; Move to on package end fragment
		EndIf

		equippedSpellIndex += 1
	EndWhile
EndFunction

; TODO - Add a Teleporting state to prevent AI advancement during teleportation
Function TeleportEnter(float afPortalEnterSeconds = 0.5)
	; Create the portal
	PlaceAtMe(pTeleportFX)

	; Hide the teleporting actor
	SetGhost(true)
	SetAlpha(0, false)
	EnableAI(false)
	SetDontMove(true)

	; Simulate duration to enter the portal
	If (afPortalEnterSeconds > 0)
		Utility.Wait(afPortalEnterSeconds)
	EndIf

	; Simulate event trigger
	OnTeleportEnter()
EndFunction

Function TeleportExit(ObjectReference akLocation, float afPortalExitSeconds = 0.5)
	; Create the new portal
	ObjectReference targetLocation = akLocation.PlaceAtMe(pTeleportFX)
	
	; Simulate duration to exit the portal
	If (afPortalExitSeconds > 0)
		Utility.Wait(afPortalExitSeconds)
	EndIf

	; Make sure the teleporting actor is moved to the location of the portal
	MoveTo(targetLocation)
	
    ; Show the teleporting actor
	EnableAI(true)
	SetDontMove(false)
	SetAlpha(1, false)
	SetGhost(false)

	; Simulate event trigger
	OnTeleportExit()
EndFunction


ObjectReference Function FindTeleportPointAwayFromActor(Actor akActor, float afMaxSearchTime = 2.0, float afSearchRadius = 1500.0)
	; Start searching
	float t0 = Utility.GetCurrentRealTime()
	float secondsElapsed = 0
	ObjectReference teleportPointRef 
	bool bBreak = false
	While (!bBreak && secondsElapsed < afMaxSearchTime)
	  teleportPointRef = FindRandomReferenceOfTypeFromRef(teleportBase, self, afSearchRadius)

	  ; If we found a teleport point
	  If (teleportPointRef != None)

		; Check if preferred
		If (akActor.hasLoS(teleportPointRef) == FALSE || akActor.getDistance(teleportPointRef) > 512)
			bBreak = true
		EndIf
	  EndIf

	  ; increment secondsElapsed
	  secondsElapsed = Utility.GetCurrentRealTime() - t0
	EndWhile

	return teleportPointRef
EndFunction

Function Teleport(ObjectReference akToLocation, float afWaitTimeUntilExit = 0.0)
	If (akToLocation != None)
		TeleportEnter()

		; Wait until reappearing
		If (afWaitTimeUntilExit > 0)
			Utility.Wait(afWaitTimeUntilExit)
		EndIf
		
		TeleportExit(akToLocation)
	EndIf
EndFunction


;======================================================================================;
;  STATES  /
;=============/

State Initialized
	Function OnBeginState()
		isInitialized = true
		SetState(STATE_HIGH_HEALTH)
	EndFunction	
EndState

State Initializing 
	Function OnBeginState()
		if (IsDebug())
			Debug.MessageBox("Initializing")
		EndIf

		InitializeStates() ; TODO : Set stateIndex to STATE_INITIALIZING at this point
		UnregisterForUpdate() 
		isDying = false
		prevHealthPercentage = GetAVPercentage("Health")
		battleStartTimeSeconds = Utility.GetCurrentRealTime()
		ResetHitCounter()
		Debug.Trace("Adding music")
		MUSCombatBoss.Add()		

		; Now we can take damage
		SetGhost(false) ; NOTE : Boss ActorBase must be set to Ghost in creation kit 
		
		; Ensures only called once
		isInitialized = true

		SetState(STATE_INITIALIZED) ; TODO must change this to an Initialized state that takes over the EMPTY state evaluation
		RegisterForSingleUpdate(UPDATE_INTERVAL_SECONDS)
	EndFunction

	Function OnUpdate()
		; Do nothing while we're initializing
	EndFunction

	Event OnHit(ObjectReference akAggressor, Form weap, Projectile proj, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
		; Do nothing while we're initializing
	EndEvent

	Function ProcessOnUpdateOROnHitEvent(bool abIsOnHit)
		; Do nothing while we're busy
	EndFunction

	Function InitializeStates()
		States = new String[100]
	
		; States 0-9 are reserved for setup states
		States[0] = STATE_EMPTY
		States[1] = STATE_INITIALIZING
		States[2] = STATE_INITIALIZED

		; States 10-19 are main states
		States[10] = STATE_HIGH_HEALTH
		States[11] = STATE_MEDIUM_HEALTH
		States[12] = STATE_LOW_HEALTH

		; States 20+ are temporary states
		States[20] = STATE_CASTING
	EndFunction
EndState

State HighHealth
	Event OnMediumHealth()
		SetState(STATE_MEDIUM_HEALTH)
	EndEvent

	Event OnHitRecord(bool abHitThresholdReached, int aiHitThreshold, int aiHitCounter)
		float now =  Utility.GetCurrentRealTime()
		If (abHitThresholdReached)
			SetState(STATE_CASTING, pSpecial1Index)
		ElseIf (now > _nextSummondThresholdSeconds + 30) ; TODO revert
			SetState(STATE_CASTING, pSpecialSummon1Index)
		EndIf	
	EndEvent
EndState

State MediumHealth
	Event OnBeginState()
		; Additional changes
		SetSpells(pMediumHealthSpells)
	EndEvent

	Event OnLowHealth()
		SetState(STATE_LOW_HEALTH)
	EndEvent

	Event OnHitRecord(bool abHitThresholdReached, int aiHitThreshold, int aiHitCounter)
		If (abHitThresholdReached)
			; Teleport to opponent and unleash our special
			Teleport(_opponent)
			SetState(STATE_CASTING, pSpecial1Index)
		ElseIf (RandomFloat() < 0.25) 
			; Random chance to teleport
			EvaluateTeleport()
		EndIf	
	EndEvent
EndState

State LowHealth
	Event OnBeginState()	
		;pImageSpaceModifier.Apply()
	EndEvent

	Event OnEndState()			
		; Additional changes
		;pImageSpaceModifier.Remove()
	EndEvent

	Event OnEvaluationStart(bool abIsOnHit)
		If (!abIsOnHit && RandomFloat() < 0.50)
			RampRumble(0.75, 2, 1600)
	        Game.ShakeCamera(self, 1, 2)
		EndIf
	EndEvent

	Event OnHitRecord(bool abHitThresholdReached, int aiHitThreshold, int aiHitCounter)
		If (abHitThresholdReached)
			SetState(STATE_CASTING, pSpecial3Index)
		ElseIf (RandomFloat() < 0.65) 
			; Higher chance to teleport
			EvaluateTeleport()
		EndIf	
	EndEvent
EndState


;======================================================================================;
;  TEMPORARY STATES  /
;=============/

State Casting
	Event OnBeginState()
		; Ensure we can't be hurt
		GetActorBase().SetInvulnerable(true)
	EndEvent

	Event OnEndState()			
		GetActorBase().SetInvulnerable(false)

		; Spells can stay equipped so need to remove
		UnequipSpells(self)
	EndEvent

	Function ProcessOnUpdateOROnHitEvent(bool abIsOnHit)
		; Do nothing while we're busy
	EndFunction
EndState


