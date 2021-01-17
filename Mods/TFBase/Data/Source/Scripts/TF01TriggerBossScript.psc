Scriptname TF01TriggerBossScript extends ObjectReference  

Int InTrigger = 0
Actor Property Boss Auto
ObjectReference Property EntranceDoor Auto
ObjectReference Property CenterLight Auto

Event OnTriggerEnter(ObjectReference akTriggerRef)
	if (InTrigger == 0)
		if akTriggerRef == Game.GetPlayer()	
			InTrigger += 1
			Actor player = akTriggerRef as Actor
			int LOCK_REQUIRES_KEY = 255
			EntranceDoor.SetLockLevel(LOCK_REQUIRES_KEY)
			EntranceDoor.Lock(true)
			CenterLight.Disable()
			Boss.StartCombat(player)
		endif
	endif
EndEvent