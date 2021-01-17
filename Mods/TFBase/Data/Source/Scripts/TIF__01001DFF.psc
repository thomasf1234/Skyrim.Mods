;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 2
Scriptname TIF__01001DFF Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_1
Function Fragment_1(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
DialogueFollower.SetFollower(akSpeakerRef)
;END CODE
EndFunction
;END FRAGMENT

DialogueFollowerScript Property DialogueFollower  Auto

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
