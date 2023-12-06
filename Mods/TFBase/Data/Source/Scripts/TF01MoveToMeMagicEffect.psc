ScriptName TF01MoveToMeMagicEffect extends activeMagicEffect
{Moves the target to player}

;======================================================================================;
;  PROPERTIES  /
;=============/

Actor Property SummonRef Auto ;

;======================================================================================;
;  LOCAL VARIABLES  /
;=============/

Event OnEffectStart(Actor akTarget, Actor akCaster)
	SummonRef.Disable(true)
	SummonRef.MoveTo(akCaster)
	SummonRef.Enable()
EndEVENT
