ScriptName TF01DiminishLightMagicEffect extends activeMagicEffect
{Lowers the light}

;======================================================================================;
;  PROPERTIES  /
;=============/

ObjectReference Property pLight Auto

float Property PercentageOfScale = 0.1 auto
{MANDATORY: percentage of max health}

Event OnEffectStart(Actor akTarget, Actor akCaster)
	float currentScale = pLight.GetScale()
	float newScale = currentScale * PercentageOfScale
	pLight.SetScale(newScale)
	; RestoreHealthPercentage(akTarget, PercentageOfMaxHealth)
endEVENT

; Function RestoreHealthPercentage(Actor akTarget, float percentageOfMaxHealth)
; 	int totalHealth = akTarget.GetBaseActorValue("Health") as int
; 	int restoreAmount = ((totalHealth * percentageOfMaxHealth) as int)
; 	;Debug.MessageBox("Restoring " + restoreAmount + "/" + totalHealth + " Health")
; 	akTarget.RestoreActorValue(ACTOR_VALUE_HEALTH, restoreAmount)
; EndFunction
