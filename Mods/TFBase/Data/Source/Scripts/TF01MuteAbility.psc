ScriptName TF01MuteAbility extends ActiveMagicEffect
{Increases the rate of stamina recovery but disables shouts}

;======================================================================================;
;  PROPERTIES  /
;=============/

float Property pStaminaRateMod = 2.5 Auto
string Property pEffectStartMessage = "You have lost the ability to shout" Auto
string Property pEffectFinishMessage = "You have regained the ability to shout" Auto

;======================================================================================;
;  LOCAL VARIABLES  /
;=============/

Actor caster
float voiceRecoveryTime

;======================================================================================;
;  CONSTANTS  /
;=============/

;  https://www.creationkit.com/index.php?title=Actorvalue
string ACTOR_VALUE_STAMINA_RATE = "StaminaRate"
float INFINITY_SECONDS = 3153600000.0

;======================================================================================;
;  EVENTS  /
;=============/

Event OnEffectStart(Actor akTarget, Actor akCaster)
	caster = akCaster
	caster.ModActorValue(ACTOR_VALUE_STAMINA_RATE, pStaminaRateMod)
	voiceRecoveryTime = caster.GetVoiceRecoveryTime()
	caster.SetVoiceRecoveryTime(INFINITY_SECONDS)
	Debug.Notification(pEffectStartMessage)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	caster.ModActorValue(ACTOR_VALUE_STAMINA_RATE, -pStaminaRateMod)
	caster.SetVoiceRecoveryTime(voiceRecoveryTime)
	Debug.Notification(pEffectFinishMessage)
endEVENT
