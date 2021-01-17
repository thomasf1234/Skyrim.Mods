ScriptName TF01TimeTravelMagicEffect extends activeMagicEffect
{Advances the actor into the future}

EffectShader Property TimeFadeOut01FXS Auto
EffectShader Property TimeFadeIn01FXS Auto
;======================================================================================;
;  PROPERTIES  /
;=============/

Event OnEffectStart(Actor akTarget, Actor akCaster)
	if (akTarget != Game.GetPlayer())
		TimeFadeOut01FXS.Play(akTarget)
		akTarget.setGhost(true)
		akTarget.EnableAI(false)
		akTarget.SetDontMove(true)
		Utility.Wait(2.0)
		akTarget.SetAlpha(0.0, true)	
		akTarget.SetPosition(akTarget.GetPositionX(), akTarget.GetPositionY(), akTarget.GetPositionZ() + 1000)
		TimeFadeOut01FXS.Stop(akTarget)
	endIf
EndEVENT

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	if (akTarget != Game.GetPlayer())
		akTarget.SetPosition(akTarget.GetPositionX(), akTarget.GetPositionY(), akTarget.GetPositionZ() - 1000)
		TimeFadeIn01FXS.Play(akTarget)
		akTarget.SetAlpha(1.0, true)
		Utility.Wait(2.0)
		akTarget.SetDontMove(false)
		akTarget.EnableAI(true)
		akTarget.setGhost(false)
		TimeFadeIn01FXS.Stop(akTarget)
	endIf
endEVENT
