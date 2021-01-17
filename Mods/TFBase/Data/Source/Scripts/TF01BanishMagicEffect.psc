ScriptName TF01BanishMagicEffect extends activeMagicEffect
{Disables the target actor}

;======================================================================================;
;  PROPERTIES  /
;=============/

Activator Property EffectSummonBanishFX auto
{MANDATORY: Object placed at the start of the spell effect}

ImageSpaceModifier property MAGBanishImod auto
{OPTIONAL: IsMod applied at the start of the spell effect}

Int Property SecondsBeforeDelete = 4 auto


Event OnEffectStart(Actor akTarget, Actor akCaster)
	Banish(akTarget, akCaster)
endEVENT

Function Banish(Actor akTarget, Actor akCaster)
	ObjectReference placedEffect

	placedEffect = akTarget.PlaceAtMe(EffectSummonBanishFX)
	placedEffect.moveTo(akTarget)

	MAGBanishImod.apply()

	if (akTarget == Game.GetPlayer())
		;akTarget.SetActorValue("Health", 1) sets maximum health to one so must find alternative solution
	else
		akTarget.setGhost(TRUE)
		akTarget.EnableAI(false)
		akTarget.SetDontMove(true)
		akTarget.KillEssential(akCaster)
		akTarget.Disable(true)
	endIf

	Utility.wait(SecondsBeforeDelete)
		
	placedEffect.disable()
	placedEffect.delete()
EndFunction

