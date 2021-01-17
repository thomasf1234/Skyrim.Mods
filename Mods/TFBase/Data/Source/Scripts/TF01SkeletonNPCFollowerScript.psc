Scriptname TF01SkeletonNPCFollowerScript extends ObjectReference  

DialogueFollowerScript Property DialogueFollower Auto
GlobalVariable Property PlayerFollowerCount Auto
Message Property FollowingMessage Auto

auto state Waiting
event onActivate(objectReference AkActivator)
	If PlayerFollowerCount.GetValueInt() == 0
		;(DialogueFollower as DialogueFollowerScript).SetFollower(self)
             ; FollowingMessage.Show()
	EndIF
endEvent
endState

state done
endstate