scriptName TF01Boss1Script extends Actor
{Attempt at a generic script for a Boss}

import game
import utility

;Summon parameters
activator property teleportBase auto
{Base object to search for as a teleport point}
float property fSearchRadius = 1600.0 auto
{How far near me to search for teleport points? DEFAULT = 768u}
int property iMinToCounter = 2 auto
{Min # of hits I'll take before countering.  DEFAULT = 2}
int property iMaxToCounter = 4 auto
{Max # of hits I'll take before countering.  DEFAULT = 4}

; state 1 params
int property iSummons = 1 auto
Activator Property BasePoint Auto
ObjectReference basePointRef
EffectShader property specialFX auto

Spell Property Special1Spell Auto
Spell Property SpecialSummonSpell Auto
ActorBase Property pSpecialSummon Auto

Activator property SummonFX Auto
effectShader property reanimateFx Auto
effectShader property fadeOutFX auto

;Internal variables.
bool combatStarted
int hitCount
ObjectReference teleportGoal 
actor caster
objectReference casterRef
bool inBleedout

; http://www.cipscis.com/skyrim/tutorials/states.aspx

; Todo make spell of corruption 
; TODO : Allow boss to clone themselves
;======================================================================================;
;  PROPERTIES  /
;=============/

float Property HitCoolDownSeconds = 2.0 Auto

ImageSpaceModifier Property pImageSpaceModifier Auto

Activator property pTeleportFX Auto
float property pTeleportMinWaitTimeUntilExit = 0.0 Auto
float property pTeleportMaxWaitTimeUntilExit = 1.0 Auto
float property pTeleportChanceOnHit = 0.0 Auto

Spell[] Property pMediumHealthSpells Auto

int Property pSpecial1Index Auto
Spell[] Property pSpecial1Spells Auto
EffectShader property pSpecial1Shader = None auto

int Property pSpecial2Index Auto
Spell[] Property pSpecial2Spells Auto
EffectShader property pSpecial2Shader = None auto

int Property pSpecial3Index Auto
Spell[] Property pSpecial3Spells Auto
EffectShader property pSpecial3Shader = None auto

bool Property RunInDebugMode = false Auto
{OPTIONAL: runs this script in debug mode - defaults to false}

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
string ACTOR_VALUE_STATE = "Variable06"

string STATE_EMPTY = ""
string STATE_INITIALIZING = "Initializing"
string STATE_INITIALIZED = "Initialized"
string STATE_BUSY = "Busy"

string STATE_HIGH_HEALTH = "HighHealth"
string STATE_MEDIUM_HEALTH = "MediumHealth"
string STATE_LOW_HEALTH = "LowHealth"

string STATE_SPECIAL_1 = "Special1"
string STATE_SPECIAL_2 = "Special2"
string STATE_SPECIAL_3 = "Special3"

int DEBUG_SEVERITY_WARNING = 1
int DEBUG_SEVERITY_ERROR = 2

float UPDATE_INTERVAL_SECONDS = 1.0

;======================================================================================;
;  LOCAL VARIABLES  /
;=============/

float battleStartTimeSeconds
float lastRecordedHitSeconds
int _hitCounter
int _hitsUntilSpecialThreshold
float secondsUntilSpecialThreshold
bool isDying
bool isInitialized 
string[] States
ObjectReference[] teleportPoints
Spell[] currentSpells
string nextState
float prevHealthPercentage

;======================================================================================;
;  EMPTY STATE  /
;=============/

; This is within the "empty" state
; Event called when the script has been created and all its properties have been initialized. Until OnInit has finished running, your script
; will not receive any events, and other scripts that try to call functions or access properties on your script will be paused until the event finishes.
; Event OnInit() ; This event will run once, when the script is initialized
; 	Debug.Trace("Entered OnInit")
; 	Initialize()
; 	Debug.Trace("About to change state to HighHealth")
; 	GotoState("HighHealth") ; GotoState doesn't return until the OnEndState event of the current state and the OnBeginState event of the new state finish running. (And the events won't overlap)
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
		EnsureInitialized()
	EndIf
EndEvent

Event OnDying(Actor akKiller)
	isDying = true
EndEvent

;Every second or OnHit, we evaluate the state.
Function OnUpdate()
	Debug.Trace("Entered OnUpdate")
	If (isInitialized)
		If (IsAlive(self))
			ProcessOnUpdateOROnHitEvent()
	
			; Register for another update scheduled in UPDATE_INTERVAL_SECONDS second
			RegisterForSingleUpdate(UPDATE_INTERVAL_SECONDS)
		EndIf
	EndIf
EndFunction

Event OnHit(ObjectReference akAggressor, Form weap, Projectile proj, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	Actor opponent = akAggressor as Actor
	Debug.Trace("Entered OnHit")

	If (isInitialized)
		If (IsAlive(self))
			bool isValidHit = RecordHitIfValid()
			ProcessOnUpdateOROnHitEvent()
		EndIf
	EndIf
EndEvent

; Need to change these to OnCombatHitThreshold?
; Custom event
Event OnHitRecord()
	If (IsDebug())
		Debug.MessageBox("Hit has been recorded")
	EndIf	
EndEvent

Event OnHitThreshold()
	If (IsDebug())
		Debug.MessageBox("Hit threshold reached! " + _hitsUntilSpecialThreshold)
	EndIf	
EndEvent

; Custom event
Event OnTeleportExit()
	If (IsDebug())
		Debug.MessageBox("Just returned from teleporting")
	EndIf	
EndEvent

Event OnMediumHealth()
	If (IsDebug())
		Debug.MessageBox("Medium health threshold reached! " + pMediumHealthThreshold)
	EndIf	
EndEvent

; Custom event
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

Function InitializeStates()
	; Overridden within 'Initializing' state
EndFunction

Function InitializeTeleportPoints()
	; Overridden within 'Initializing' state
EndFunction

; Event OnPackageStart(Package akNewPackage)
; 	Debug.Trace("We just started running the " + akNewPackage + " package")
; EndEvent

; Event OnPackageChange(Package akOldPackage)
; 	Debug.Trace("We just switched away from running the " + akOldPackage + " package")
; EndEvent

; TODO - Recognise when player is viewing us
; Function SomeFunction()
; 	RegisterForSingleLOSLost(Game.GetPlayer(), Kettle) ; Before we can use OnLostLOS we must register.
;   EndFunction

; Event OnLostLOS(Actor akViewer, ObjectReference akTarget)
; 	;/ If other registrations had been done, we would want to check the viewer and target
; 	   But since we only registered for one we know what it is
; 	   Since we only did single los lost, we'll only get this once /;
; 	Debug.Trace("Player just looked away from the kettle, so boil it!")
; endEvent

; Formally sets the state on the actor, must be called instead of GotoState()
Function SetState(string asNewState)
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

		; TODO - must revert to a default state index as a way to disable stateIndex before calling GotoState because OnEndState may make changes necessary to maintain the current state AI packages
		GotoState(asNewState) ; GotoState doesn't return until the OnEndState event of the current state and the OnBeginState event of the new state finish running. (And the events won't overlap)
		; Note that stateIndex is only applied after the state has returned from OnBeginState

		; Need to set the actor value that is used when determining AI packages that are attached to our actor
		SetActorValue(ACTOR_VALUE_STATE, stateIndex)
	EndIf
EndFunction

; TODO : Change this implementation (Called OnEnd of AI packages)
Function FinishedTempState()
	SetState(STATE_INITIALIZED)
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

bool Function RecordHitIfValid()
	float currentSeconds = Utility.GetCurrentRealTime()
	float secondsSinceLastRecordedHit = currentSeconds - lastRecordedHitSeconds
	; Only record a hit if we're outside of the cool down period and the actor is not in an invulnerable state
	if (secondsSinceLastRecordedHit > HitCoolDownSeconds && !GetActorBase().IsInvulnerable())
		_hitCounter += 1
		lastRecordedHitSeconds = currentSeconds
		Debug.Trace("Recorded a hit at " + currentSeconds)

		if (IsDebug())
			Debug.MessageBox("Recorded HitCount is " + _hitCounter)
		EndIf		

		return true
	else
		Debug.Trace("Skipping recording hit - too frequent")
		return false
	endIf
EndFunction

Function ResetHitCounter()
	_hitCounter = 0
	_hitsUntilSpecialThreshold = RandomInt(pMinHitsUntilSpecialThreshold, pMaxHitsUntilSpecialThreshold)
	if (IsDebug())
		Debug.MessageBox("Reset HitCounter to 0 with next threshold set at " + _hitsUntilSpecialThreshold)
	EndIf	
EndFunction

Function EvaluateHitThreshold()
	If (_hitCounter >= _hitsUntilSpecialThreshold)
		OnHitThreshold()
		ResetHitCounter()
	EndIf
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

bool isProcessingOnUpdateOROnHitEvent = false
Function ProcessOnUpdateOROnHitEvent()
	; Only needed to avoid asynchronous concurrent evaluation threads
	If (!isProcessingOnUpdateOROnHitEvent)
		; Lock
		isProcessingOnUpdateOROnHitEvent = true 
		
		; Store existing state
		string oldState = GetState()

		; Calculate whether or not we need to change state
		EvaluateHealth()

		; Check if we have reached our hit threshold
		EvaluateHitThreshold()

		; Check if state has been updated
		string newState = GetState()

		; Evaluate the packages to ensure any state changes that trigger an AI package are picked up immediately
		If (newState != oldState)
			EvaluatePackage()
		EndIf

		; Unlock
		isProcessingOnUpdateOROnHitEvent = false
	EndIf
EndFunction

State Initialized
	Function OnBeginState()
		isInitialized = true
		SetState(STATE_HIGH_HEALTH)
		EvaluatePackage()
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
		lastHealthPercentage = GetAVPercentage("Health")
		battleStartTimeSeconds = Utility.GetCurrentRealTime()
		ResetHitCounter()
		Debug.Trace("Adding music")
		MUSCombatBoss.Add()		
		InitializeTeleportPoints()

		; Now we can take damage
		SetGhost(false)
		
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

	Function ProcessOnUpdateOROnHitEvent()
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

		; States 20+ are special states
		; States[20] = STATE_SPECIAL_1
		; States[21] = STATE_SPECIAL_2
		; States[22] = STATE_SPECIAL_3

		States[pSpecial1Index] = STATE_SPECIAL_1
		States[pSpecial2Index] = STATE_SPECIAL_2
		States[pSpecial3Index] = STATE_SPECIAL_3
	EndFunction

	Function InitializeTeleportPoints()
		teleportPoints = new ObjectReference[11]
	
		int foundIndex = 0
		int attempts = 0
	
		While (attempts < 50 && foundIndex < teleportPoints.Length)
		  ObjectReference teleportPointRef = FindRandomReferenceOfTypeFromRef(teleportBase, self, fSearchRadius)
		  If (teleportPoints.RFind(teleportPointRef, foundIndex) < 0)
			;Debug.MessageBox("foundIndex = " + foundIndex)
			teleportPoints[foundIndex] = teleportPointRef
			foundIndex += 1
		  EndIf
	
		  attempts += 1
		EndWhile
	
		Debug.MessageBox("foundIndex = " + foundIndex + "Attempts = " + attempts)
	EndFunction
EndState

; See here for list https://www.creationkit.com/index.php?title=Animation_Events
; Event OnAnimationEvent(ObjectReference akSource, string asEventName)
; 	; Override
; endEvent

State HighHealth
	; Event OnAnimationEvent(ObjectReference akSource, string asEventName)
	; 	;Debug.MessageBox("Received event " + asEventName)
	; 	if (akSource == Game.GetPlayer()) && (asEventName == "CastOkStart")
	; 		SetGhost(true)
	; 		Disable()
	; 		;TeleportEnter()
	; 		Utility.Wait(3)
	; 		SetGhost(false)
	; 		Enable()
	; 	endIf
	; EndEvent

	Event OnBeginState()
		; Debug.MessageBox("Registering for animation events")	
		; If (!RegisterForAnimationEvent(Game.GetPlayer(), "weaponSwing"))
		; 	Debug.MessageBox("Failed to register for event weaponSwing")
		; EndIf

		; If (!RegisterForAnimationEvent(Game.GetPlayer(), "CastOkStart"))
		; 	Debug.MessageBox("Failed to register for event CastOkStart")
		; EndIf

		; If (!RegisterForAnimationEvent(Game.GetPlayer(), "AttackWinStart"))
		; 	Debug.MessageBox("Failed to register for event AttackWinStart")
		; EndIf

		; If (!RegisterForAnimationEvent(Game.GetPlayer(), "BeginCastRight"))
		; 	Debug.MessageBox("Failed to register for event BeginCastRight")
		; EndIf	
	EndEvent

	Event OnMediumHealth()
		SetState(STATE_SPECIAL_3)
	EndEvent

	Event OnHitThreshold()
		SetState(STATE_SPECIAL_1)
	EndEvent

	; string Function EvaluateState()
	; 	Debug.Trace(GetState() +" - EvaluateState")

	; 	float healthPercentage = GetAVPercentage("Health")

	; 	;Teleport(RandomFloat(0.0, 3.0))

	; 	If (healthPercentage < pMediumHealthThreshold)
	; 		return STATE_MEDIUM_HEALTH
	; 	ElseIf (_hitCounter > 1)
	; 		ResetHitCounter()
	; 		return STATE_SPECIAL_1			
	; 	EndIf

	; 	; Default 
	; 	return STATE_HIGH_HEALTH
	; EndFunction
EndState

State Special1
	Event OnBeginState()
		; Additional changes
		; DispelAllSpells()
		GetActorBase().SetInvulnerable(true)
		If (pSpecial1Shader != None)
			pSpecial1Shader.Play(self)
		EndIf
		
		SetSpells(pSpecial1Spells)
	EndEvent

	Event OnEndState()			
		; Additional changes
		If (pSpecial1Shader != None)
			pSpecial1Shader.Stop(self)
		EndIf
		GetActorBase().SetInvulnerable(false)
		;UnequipSpell(GetEquippedSpell(0), 0) ; Move to on package end fragment
	EndEvent
EndState

State Special2
	Event OnBeginState()
		; Additional changes
		; DispelAllSpells()
		GetActorBase().SetInvulnerable(true)
		If (pSpecial2Shader != None)
			pSpecial2Shader.Play(self)
		EndIf
		SetSpells(pSpecial2Spells)
	EndEvent

	Event OnEndState()			
		; Additional changes
		If (pSpecial2Shader != None)
			pSpecial2Shader.Stop(self)
		EndIf
		GetActorBase().SetInvulnerable(false)
	EndEvent

	Function ProcessOnUpdateOROnHitEvent()
		; Do nothing while we're busy
	EndFunction
EndState

State Special3
	Event OnBeginState()
		; Additional changes
		; DispelAllSpells()
		GetActorBase().SetInvulnerable(true)
		If (pSpecial3Shader != None)
			pSpecial3Shader.Play(self)
		EndIf
		
		SetSpells(pSpecial3Spells)
	EndEvent

	Event OnEndState()			
		; Additional changes
		If (pSpecial3Shader != None)
			pSpecial3Shader.Stop(self)
		EndIf
		GetActorBase().SetInvulnerable(false)
	EndEvent

	Function ProcessOnUpdateOROnHitEvent()
		; Do nothing while we're busy
	EndFunction
EndState

State MediumHealth
	Event OnBeginState()
		; Additional changes
		SetSpells(pMediumHealthSpells)
	EndEvent

	Event OnEndState()			
		; Additional changes
	EndEvent

	; string Function EvaluateState()
	; 	Debug.Trace(GetState() + " - EvaluateState")

	; 	float healthPercentage = GetAVPercentage("Health")

	; 	If (healthPercentage < pLowHealthThreshold)
	; 		SetState(STATE_LOW_HEALTH) 
	; 	ElseIf (_hitCounter > _hitsUntilSpecialThreshold && RandomInt() < 25)
	; 		ResetHitCounter()
	; 		return STATE_SPECIAL_2
	; 	ElseIf (RandomInt() < 5)
	; 		Teleport() 
	; 		return STATE_MEDIUM_HEALTH
	; 	ElseIf (GetDistance(Game.GetPlayer()) < 200 && _hitCounter > _hitsUntilSpecialThreshold); && RandomFloat() < 0.25)
	; 		ResetHitCounter()
	; 		return STATE_SPECIAL_1
	; 	EndIf

	; 	; Default 
	; 	return STATE_MEDIUM_HEALTH
	; EndFunction
EndState

State LowHealth
	Event OnBeginState()	
		pImageSpaceModifier.Apply()
	EndEvent

	Event OnEndState()			
		; Additional changes
		pImageSpaceModifier.Remove()
	EndEvent

	; string Function EvaluateState()
	; 	Debug.Trace(GetState() + " - EvaluateState")

	; 	float healthPercentage = GetAVPercentage("Health")

	; 	If (_hitCounter > _hitsUntilSpecialThreshold && RandomInt() < 25)
	; 		ResetHitCounter()
	; 		return STATE_SPECIAL_3
	; 	ElseIf (RandomInt() < 10)
	; 		Teleport() 
	; 	EndIf

	; 	; Default
	; 	return STATE_LOW_HEALTH
	; EndFunction
EndState

















Spell property FlamesSpell Auto
Spell property FrostSpell auto

;Every 2 hits, the Caller teleports.
; Event OnHit(ObjectReference akAggressor, Form weap, Projectile proj, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
; 	Actor opponent = akAggressor as Actor

; 	float healthPercentage = GetAVPercentage("Health")

; 	if (healthPercentage <= 0)
; 		Debug.Notification("Killed by opponent")
; 		;EndDeferredKill()
; 		Kill(opponent)
; 	else
; 		int hitTolerance = RandomInt(iMinToCounter, iMaxToCounter)
; 		hitCount = hitCount + 1
; 		if (hitCount > hitTolerance && !IsDead())
; 			hitCount = 0
; 			if inBleedout == FALSE && isDead() == FALSE
; 				;Heal(0.15)
; 				;Banish(opponent)
				
; 				ExecuteSpecial2(opponent)
; 				;EquipSpell(FlamesSpell, 0)
; 				AddSpell(FrostSpell)
; 				;AddSpell(FlamesSpell)
; 			endif
; 		EndIf
; 	endIf
; EndEvent

; Event ExecuteSpecial1(Actor opponent)
; 	Debug.MessageBox("Entered Special1")
; 	basePointRef = FindRandomReferenceOfTypeFromRef(BasePoint, self, fSearchRadius)
; 	SetGhost(true)

; 	specialFX.Play(self)
; 	Special1Spell.Cast(self, opponent)
; 	;Utility.Wait(10)

; 	;EnableAi(false)
; 	;StopCombat()
; 	;bool successfulPath = PathToReference(basePointRef, 1)
; 	;PlayAnimation("IdlePray")
; 	;EnableAi(true)
; 	;if successfulPath
; 	;	SetGhost(false)
; 	;	StartCombat(opponent)
; 	;endIf

; 	SetGhost(false)
; 	specialFX.Stop(self);
; EndEvent



; ObjectReference Function FindValidTeleportPointFromActor(Actor akActor, float afValidDistance = 500.0, int aiSearches = 1)
; 	; tries determines how many times to look,, and then the best choice is made
; 	ObjectReference[] teleportPointsOrderedByPriorityDesc
	
; 	if (aiSearches < 2)
; 		teleportPointsOrderedByPriorityDesc = new ObjectReference[1]
; 	elseif (aiSearches == 2)
; 		teleportPointsOrderedByPriorityDesc = new ObjectReference[2]
; 	elseif (aiSearches == 3)
; 		teleportPointsOrderedByPriorityDesc = new ObjectReference[3]
; 	elseif (aiSearches == 4)
; 		teleportPointsOrderedByPriorityDesc = new ObjectReference[4]
; 	elseif (aiSearches >= 5)
; 		teleportPointsOrderedByPriorityDesc = new ObjectReference[5]
; 	endIf

; 	int count = teleportPointsOrderedByPriorityDesc.Length
; 	int i

; 	ObjectReference furthestTeleportPoint
; 	float furthestDistanceFromActor = 0

; 	int i = 0
; 	Debug.MessageBox("Searching to teleport")
; 	While (i < teleportPoints.Length && furthestDistanceFromActor < 500)
; 	  ObjectReference teleportPoint = teleportPoints[i]
; 	  float distanceFromActor = akActor.GetDistance(teleportPoint)

; 	  If (distanceFromActor > furthestDistanceFromActor)
; 		furthestTeleportPoint = teleportPoint
; 		furthestDistanceFromActor = distanceFromActor
; 	  EndIf
; 	  i += 1 
; 	EndWhile

; 	Debug.MessageBox("Furthest = " + furthestDistanceFromActor)

; 	return furthestTeleportPoint
; EndFunction

; Return the indexes of aaObjects in ascending order of distance from akTarget
Function SortByDistanceFromActorAsc(int[] indexes, ObjectReference[] aaObjects, ObjectReference akTarget)
	int n = aaObjects.Length
	float[] distancesFromActor= new float[100]

	int i = 0
	While (i < n)
	  ObjectReference objectRef = aaObjects[i]
	  distancesFromActor[i] = akTarget.GetDistance(objectRef)
	  indexes[i] = i
	  i += 1
	EndWhile

	; InsertSort algorithm
	i = 1
	While (i < n)
	  float value = distancesFromActor[i]
	  int j = i - 1

	  While(j >= 0 && distancesFromActor[j] > value)
	    distancesFromActor[j+1] = distancesFromActor[j]
        indexes[j+1] = indexes[j]
	    j -= 1
	  EndWhile

	  distancesFromActor[j+1] = value
	  indexes[j+1] = i
	  i += 1
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
EndFunction

Function Teleport(float waitTimeUntilExit = 0.0)
	TeleportEnter()
	int[] indexes = new int[5]
	int[] sampleIndexes = new int[5]
	ObjectReference[] randTeleportPointsSample = new ObjectReference[5]

	int sampleCount = sampleIndexes.Length
	int k = 0
	While (k < sampleCount)
		int randInt = RandomInt(0, sampleCount)

		If (sampleIndexes.Find(randInt) < 0)
		sampleIndexes[k] = randInt
		randTeleportPointsSample[k] = teleportPoints[randInt]
		EndIf

		k += 1
	EndWhile

	If (waitTimeUntilExit > 0)
		Utility.Wait(waitTimeUntilExit)
	EndIf

	Actor _player = Game.GetPlayer()
	SortByDistanceFromActorAsc(indexes, randTeleportPointsSample, _player)

	int i = indexes.Length
	bool foundValidTeleportPoint = false
	While (i >= 0 && foundValidTeleportPoint == false)
		ObjectReference teleportPoint = teleportPoints[indexes[i]]
		string _message = "index " + i + " distance from player " + _player.GetDistance(teleportPoint)
		Debug.trace(_message)

		If (_player.hasLoS(teleportPoint) == FALSE)
			foundValidTeleportPoint = true
			TeleportExit(teleportPoint)
		EndIf

		i -= 1
	EndWhile
EndFunction

; TODO - Remove in favour of TeleportEnter and TeleportExit
Function TeleportTo(ObjectReference akLocation, float afPortalInterval = 0.0, float afPortalEnterExitSeconds = 0.5)
	TeleportEnter(afPortalEnterExitSeconds)
	; Wait until it's time to re-appear
	If (afPortalInterval > 0)
		Utility.Wait(afPortalInterval)
	EndIf
	TeleportExit(akLocation, afPortalEnterExitSeconds)
EndFunction

; Special2 summons iSummons number of SpecialSummon for iDuration seconds
Event ExecuteSpecial2(Actor opponent)
	;Debug.MessageBox("Entered Special2")

	Actor[] summonRefs
	
	if (iSummons < 1)
		return
	endIf

	if (iSummons == 1)
		summonRefs = new Actor[1]
	elseif (iSummons == 2)
		summonRefs = new Actor[2]
	elseif (iSummons == 3)
		summonRefs = new Actor[3]
	elseif (iSummons == 4)
		summonRefs = new Actor[4]
	elseif (iSummons >= 5)
		summonRefs = new Actor[5]
	endIf

	int count = summonRefs.Length
	int ALLY_RELATIONSHIP_RANK = 3
	int ENEMY_RELATIONSHIP_RANK = -3
	int i

	; Create the actor references as disabled, with the self as ally, and opponent as enemy
	i = 0
	while (i < count)
	  Actor summonRef = opponent.placeAtMe(pSpecialSummon, 1, false, true) as Actor
	  summonRef.removeFromAllFactions()
	  summonRef.SetRelationshipRank(self, ALLY_RELATIONSHIP_RANK)
	  summonRef.SetRelationshipRank(opponent, ENEMY_RELATIONSHIP_RANK)
	  summonRefs[i] = summonRef
	  i += 1
	endWhile

	; Set sibling summons as allies
	i = 0
	while (i < count)
	  Actor summonRef = summonRefs[i]
	  
	  int j = 0
	  while (j < count)
		 Actor otherSummonRef = summonRefs[j]
		 
		if summonRef != otherSummonRef 
			summonRef.SetRelationshipRank(otherSummonRef, 3)
		endIf
	    
	    j += 1
	  endWhile
	  
	  i += 1
	endWhile

	; Ensure summons are attacking the opponent
	i = 0
	while (i < count)
	  Actor summonRef = summonRefs[i]
	  summonRef.StopCombat()
	  summonRef.StartCombat(opponent)
	  i += 1
	endWhile

	RampRumble(0.75, 2, 1600)
	Game.ShakeCamera(self, 1, 2)
	;PushActorAway(opponent, 10)
	; Dissappear
	PlaceAtMe(SummonFX)
    ;fadeOutFX.play(self)
	SetGhost(true)
	
	;SetAlpha(0, true)
	
	Disable()
	EnableAI(false)
	SetDontMove(true)
	Utility.Wait(0.5)

	i = 0
	ObjectReference portal = summonRefs[0].PlaceAtMe(SummonFX)
	portal.SetScale(count)
	Utility.Wait(0.5)
	while (i < count)
	  Actor summonRef = summonRefs[i]
	  summonRef.Enable()
	  i += 1
	endWhile

	int iDuration
	iDuration = 30
	int iWait = 1

	int secondsPassed
	bool bBreak
	secondsPassed = 0
	bBreak = false
	while (!bBreak && secondsPassed < iDuration)
	    bool anySummonsAlive = false
		i = 0
		while (i < count)
			Actor summonRef = summonRefs[i]
			if (!summonRef.IsDead())
			  anySummonsAlive = true
			endIf
			i += 1
		endWhile

		if (!anySummonsAlive)
			bBreak = true
		endIf
	  Utility.Wait(iWait)
	endWhile
	

	i = 0
	while (i < count)
	  Actor summonRef = summonRefs[i]
	  summonRef.Disable()
	  i += 1
	endWhile

	; Teleport back to center
	basePointRef = FindRandomReferenceOfTypeFromRef(BasePoint, self, fSearchRadius)
	basePointRef.PlaceAtMe(SummonFX)
	Utility.Wait(0.5)
	MoveTo(basePointRef);
	
	EnableAI(true)
	
	
	EvaluatePackage()
	
	SetDontMove(false)
	Enable(true)

	If (!IsInCombat())
		StartCombat(opponent)
	EndIf
	;SetAlpha(1, true)
	;fadeOutFX.stop(self)
	
	;specialFX.Play(self)
	;SetAlpha(0.3, true)

	SetGhost(false)
	
	;SetAlpha(1, true)
	;specialFX.Stop(self)
EndEvent

Event onEnterBleedout()
	inBleedout = TRUE
	; For now never reset this boolean.  Considering it part of the flow that bleeding out turns the ability off
EndEvent

EffectShader Property RestorationFx Auto
Sound Property RestorationSound Auto
Spell Property RestorationSpell Auto
Function Heal(float percentageOfHealth)
	; RestorationFx.Play(self)
	; RestorationSound.Play(self)
	; int totalHealth = GetBaseActorValue("Health") as int
	; int restoreAmount = ((totalHealth * percentageOfHealth) as int)
	; ;Debug.MessageBox("Restoring " + restoreAmount + "/" + totalHealth + " Health")
	; RestoreActorValue("health", restoreAmount)
	; Utility.Wait(2)
	; RestorationFx.Stop(self)
	RestorationSpell.Cast(self, self)
EndFunction

; https://www.youtube.com/watch?v=0wsU1aorY08
Spell Property BanishSpell Auto
Function BanishPlayerAlly()
	Actor nonPlayerOpponent
	int i = 0
	bool nonPlayerOpponentFound = false
	While (i < 10 && nonPlayerOpponentFound == false)
	  Actor randomActor = FindRandomActorFromRef(self, 500)

	  ; Note : Papyrus won't compile multiline conditions
	  If (randomActor != None && randomActor != Game.GetPlayer() && (self.IsHostileToActor(randomActor) || randomActor.IsHostileToActor(self)))
		  nonPlayerOpponent = randomActor
		  nonPlayerOpponentFound = true

		  If (IsDebug())
			Debug.MessageBox("BanishSpell found " + nonPlayerOpponent + " at try number " + i)
		  EndIf
	  Else
		i += 1
	  EndIf
	EndWhile

	If (nonPlayerOpponent != None)
		Debug.MessageBox("Casting BanishSpell against " + nonPlayerOpponent)
		BanishSpell.Cast(self, nonPlayerOpponent)
	EndIf
EndFunction


int Property MaxDeathCount = 1 auto
Int Property CurrentDeathCount Auto ;DO NOT Change
Idle Property testIdle Auto
Event OnDeath(Actor akKiller)
	; AddToCurrentDeathCount()
	; If (CurrentDeathCount <= MaxDeathCount) ;If Death count is lower than MaxDeathCount do the next bit of code
	; 	wait(2); Wait 2 Seconds real time
	; 	reanimateFX.Play(self);Place Summon FX at dead NPC
	; 	Self.Resurrect() ;Resurrect Dead NPC
	; else
	; 	MUSCombatBoss.Remove()	
	; EndIf
	isDying = false
	Debug.Notification("Removing music")
	MUSCombatBoss.Remove()

	;PlayIdle(testIdle)
	;Utility.Wait(10)	
EndEvent
 
Function AddToCurrentDeathCount()
    CurrentDeathCount += 1 
EndFunction

MusicType Property MUSCombatBoss  Auto 

Event OnLoad()
;	MUSCombatBoss.Remove()
EndEvent

Event OnUnload()
	;MUSCombatBoss.Remove()  
endEvent



Event OnCellDetach()
;	Debug.Notification("Removing music")
;	MUSCombatBoss.Remove()
endEvent

; Event OnActivate(ObjectReference akActionRef)
; 	Actor player = Game.GetPlayer()
; 	; I've been activated - see if was my trigger
; 	if (!IsDead() && akActionRef == player)
; 	   MUSCombatBoss.Add()		
; 	   StartCombat(player)
; 	EndIf
;  EndEvent 

	

;https://www.youtube.com/watch?v=kz-tA9Yl3T4  epic music
;https://www.youtube.com/watch?v=EJq5PBOTiqI  epic music organ
;https://www.creationkit.com/index.php?title=Complete_Example_Scripts#Resurrect_an_Enemy_on_Death_Script
; Actor Function SummonSpecial(ActorBase target, Actor subject, Actor opponent)	
; 	Actor tempNPC = opponent.placeAtMe(target, 1, false, true) as Actor
; 	tempNPC.removeFromAllFactions()

; 	int ALLY_RELATIONSHIP_RANK = 3
; 	int ENEMY_RELATIONSHIP_RANK = -3

; 	tempNPC.SetRelationshipRank(self, ALLY_RELATIONSHIP_RANK)
; 	tempNPC.SetRelationshipRank(opponent, ENEMY_RELATIONSHIP_RANK)

; 	return tempNPC
; ENDFunction

;https://www.creationkit.com/index.php?title=Complete_Example_Scripts#Resurrect_an_Enemy_on_Death_Script
; FUNCTION spawnGhostFriend(Actor targ)
	
; 	;targ.placeAtMe(visualExplosion)
	
; 	ACTOR tempNPC = (targ.placeAtMe(targ.getBaseObject()) as ACTOR)
; 	;tempNPC.addSpell(ghostSpell)
; 	tempNPC.removeFromAllFactions()
; 	tempNPC.setFactionRank(playerFaction, 5)
; 	tempNPC.setGhost(TRUE)
			
; 	utility.wait(10)
	
; 	;explosionMarker.setPosition(tempNPC.x, tempNPC.y, (tempNPC.z + 75))
; 	tempNPC.placeAtMe(visualExplosion)
	
; 	utility.wait(0.5)
	
; 	tempNPC.disable()

; ENDFUNCTION