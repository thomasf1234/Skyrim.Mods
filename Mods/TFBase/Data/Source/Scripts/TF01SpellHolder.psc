Scriptname TF01SpellHolder extends ObjectReference Hidden

Spell Property pSpellToAdd Auto

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
  Actor player = Game.GetPlayer()
  bool hasNewContainer = akNewContainer && akOldContainer != akNewContainer
  
  if hasNewContainer
    Debug.Trace("Try removing spell from current actor first")

    if akOldContainer
      Actor oldActor = akOldContainer as Actor 
      if oldActor != player
        if oldActor.HasSpell(pSpellToAdd)
          oldActor.RemoveSpell(pSpellToAdd)
        endIf
      endIf
    endIf

    Actor newActor = akNewContainer as Actor
    if newActor && newActor != player
      if !newActor.HasSpell(pSpellToAdd)
        newActor.AddSpell(pSpellToAdd) 
      endIf    
    endIf 
  endIf
endEvent
