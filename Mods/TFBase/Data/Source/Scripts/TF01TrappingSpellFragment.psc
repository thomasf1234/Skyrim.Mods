;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname TF01TrappingSpellFragment Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
Actor player = Game.GetPlayer()
if player.HasSpell(pSpell)
  if player.RemoveSpell(pSpell)
    Debug.MessageBox("You have forgotton the spell " + pSpellName)
    player.AddItem(pSoulGem)
  endIf
endIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
Spell Property pSpell Auto 

String Property pSpellName Auto 

MiscObject Property pSoulGem  Auto  
