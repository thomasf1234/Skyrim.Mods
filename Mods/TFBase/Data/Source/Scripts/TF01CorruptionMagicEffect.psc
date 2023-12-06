ScriptName TF01CorruptionMagicEffect extends activeMagicEffect
{Summons a corrupted clone of the target}

;======================================================================================;
;  CONSTANTS  /
;=============/

int ENEMY_RELATIONSHIP_RANK = -3
string ACTOR_VALUE_AGGRESSION = "Aggression"
float ACTOR_VALUE_AGGRESSION_FRENZIED = 3.0

string ACTOR_VALUE_CONFIDENCE = "Confidence"
float ACTOR_VALUE_CONFIDENCE_FOOLHARDY = 4.0

;======================================================================================;
;  PROPERTIES  /
;=============/

Activator Property CorruptPortalFX Auto
EffectShader Property CorruptFXS Auto

;======================================================================================;
;  LOCAL VARIABLES  /
;=============/

float modelLoadtimeoutSeconds = 5.0
Actor clonedActor

Event OnEffectStart(Actor akTarget, Actor akCaster)
	clonedActor = akTarget.PlaceAtMe(akTarget.GetActorBase(), 1, false, true) as Actor
	ObjectReference portal = clonedActor.PlaceAtMe(CorruptPortalFX)
	clonedActor.Enable(true)
	clonedActor.MoveTo(portal)

	float t0 = Utility.GetCurrentRealTime()
	float timeElasped = 0

	; break out after modelLoadtimeoutSeconds if model is not going to load
	While (!clonedActor.Is3DLoaded() && timeElasped < modelLoadtimeoutSeconds)
	  Utility.Wait(0.05)
	  timeElasped = Utility.GetCurrentRealTime() - t0
	EndWhile

	CorruptFXS.Play(clonedActor)	
	clonedActor.BlockActivation()
	clonedActor.RemoveFromAllFactions()
	clonedActor.SetRelationshipRank(akTarget, ENEMY_RELATIONSHIP_RANK)
	clonedActor.SetActorValue(ACTOR_VALUE_AGGRESSION, ACTOR_VALUE_AGGRESSION_FRENZIED)
	clonedActor.SetActorValue(ACTOR_VALUE_CONFIDENCE, ACTOR_VALUE_CONFIDENCE_FOOLHARDY)	
	clonedActor.StartCombat(akTarget)
EndEVENT

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	If (!clonedActor.IsDisabled())
		clonedActor.Disable(true)
		CorruptFXS.Stop(clonedActor)
	EndIf
endEVENT
