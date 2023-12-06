Scriptname TF01Utility Hidden

; Compares the passed version against the installed SKSE version
; 0 if the passed version is the installed SKSE version 
; 1 if the passed version is later than the installed SKSE version
; -1 if the passed version is earlier than the installed SKSE version, or if SKSE is not installed
int Function SKSEVersionCompare(int majorVersion, int minorVersion, int betaVersion) global
	int installedMajorVersion = SKSE.GetVersion()
	int installedMinorVersion = SKSE.GetVersionMinor()
	int installedBetaVersion = SKSE.GetVersionBeta()

    int numericVersion = majorVersion * 10000 + minorVersion * 100 + betaVersion
	int installedNumericVersion = installedMajorVersion * 10000 + installedMinorVersion * 100 + installedBetaVersion

    If installedNumericVersion == 0 
        return -1
    ElseIf installedNumericVersion == numericVersion
        return 0
    ElseIf installedNumericVersion > numericVersion
        return 1
    Else
        return -1
    EndIf
EndFunction
