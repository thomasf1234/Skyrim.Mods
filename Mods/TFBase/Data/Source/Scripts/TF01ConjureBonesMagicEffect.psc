ScriptName TF01ConjureBonesMagicEffect extends activeMagicEffect
{Moves Bones to the player}

;======================================================================================;
;  PROPERTIES  /
;=============/

Actor Property SummonRef auto
{MANDATORY: Object placed at the start of the spell effect}

Activator Property SummonFX auto
{MANDATORY: Object placed at the start of the spell effect}

;======================================================================================;
;  EVENTS  /
;=============/

Event OnEffectStart(Actor akTarget, Actor akCaster)
	Conjure(SummonRef, akCaster)
endEVENT

Function Conjure(Actor akTarget, Actor akCaster)
	ObjectReference summonPortal

	akTarget.Disable(true)
	akTarget.MoveTo(akCaster)
	akTarget.Enable(true)
	akTarget.SetAlpha(0, false)
	summonPortal = akTarget.PlaceAtMe(SummonFX)
	akTarget.SetAlpha(1, true)
	
	Utility.wait(4)
		
	summonPortal.disable()
	summonPortal.delete()
EndFunction

