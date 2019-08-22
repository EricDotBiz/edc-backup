$helpText="[B] to backup now. [D] to print directories. [P] to pause. [R] to reset timer. [N] to pause after next backup. [S] to set variables. [Q] to quit."

$wrkdir="./"
$bkupdirs=@()
$bkupindex=0
$timeout=0
$pauseonbackup=$false
$logPath="./"
$logName="bkup-$(get-date -f yyyy-MM-dd).txt"

$Bkey=66
$Dkey=68
$Hkey=72
$Nkey=78
$Pkey=80
$Qkey=81
$Rkey=82
$Skey=83

function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
}

function setLogDir (){
	while($true){
		$logPath = Read-Host -Prompt 'Enter the log directory. Leave blank for current directory'
		
		if($logPath -eq "") {
			$script:logPath = Resolve-Path $script:logpath
			return 
		}
		
		if($logPath -eq "exit") { exit 0 }
		
		if (!(test-path $logPath -PathType Container)) {
			write-error "Error! Invalid 'logPath' path."
		}else{ 
			$script:logPath = Resolve-Path $logPath
			return 
		}
	}
}

function setWrkdir (){
	while($true){
		$wrkdir = Read-Host -Prompt 'Enter the work directory. Leave blank for current directory'
	
		if($wrkdir -eq "") {
			$script:wrkdir = Resolve-Path $script:wrkdir
			return 
		}
		
		if($wrkdir -eq "exit") { exit 0 }
		
		if (!(test-path $wrkdir -PathType Container)) {
			write-error "Error! Invalid 'wrkdir' path."
		}else{ 
			$script:wrkdir = Resolve-Path $wrkdir
			return 
		}
	}
}

function setBkupdir (){
	while($true){
		$bkupdir = Read-Host -Prompt 'Enter the backup directories. Enter "done" when done'
		
		if($bkupdir -eq "done") { 
			if($script:bkupdirs.Length -eq 0){ 
				write-error "Error! You need at least one backup directory."
			} else { 
				return
			} 
		}
		if($bkupdir -eq "exit") { exit 0 }
		
		if ( !(test-path $bkupdir -PathType Container)) {
			write-error "Error! Invalid 'bkupdir' path."
		}else{ 
			$script:bkupdirs += Resolve-Path $bkupdir
		}
	}
}

function printBkupdirst (){
	Write-Host "Backup directories:"
	for($i=0; $i -lt $script:bkupdirs.Length; $i++){
		if($i -eq $script:bkupindex){ Write-Host "*[$i] $($bkupdirs[$i])"  }
		else { Write-Host "[$i] $($bkupdirs[$i])" }
	}
}

function setBkupindex (){
	printBkupdirst
	
	while($true){
		$bkupindex = Read-Host -Prompt 'Use which backup first?'
		
		if($bkupindex -eq "exit") { exit 0 }
		
		if (!(isNumeric($bkupindex))){
			write-error "Error! Please input a number."
		}else { 
			$script:bkupindex=[int]$bkupindex
			if($script:bkupindex -lt 0){ $script:bkupindex=0 }
			if($script:bkupindex -ge $script:bkupdirs.Length){ $script:bkupindex=$script:bkupdirs.Length-1 }
			return
		}
	}
}

function setTimer (){
	while($true){
		$timeout = Read-Host -Prompt 'How many minutes between backups?'
		
		if($timeout -eq "exit") { exit 0 }
		
		if (!(isNumeric($timeout))){
			write-error "Error! Please input a number."
		}else { 
			$script:timeout=[int]$timeout*60
			if($timeout -lt 0){ $script:timeout=0 }
			return
		}
	}
}

function setVars (){
	Write-Host "Settings variables..."
	setLogDir
	setWrkdir
	setBkupdir
	setBkupindex
	setTimer
}

function printVars (){
	Write-Host "***** INFORMATION *****"
	Write-Host "Logs will be printed to: $logPath\$logName"
	Write-Host "Working directory is: $wrkdir"
	printBkupdirst
	Write-Host "Next backup directory is: $($bkupdirs[$bkupindex])"
	Write-Host "Pause before next backup: $pauseonbackup"
	Write-Host "Minutes between backups: $($script:timeout/60)"
}

function timeout (){
	for (; $timeout -gt 0; $timeout--){
		write-progress -Activity "Waiting for backup" -SecondsRemaining $timeout -CurrentOperation $helpText
		
		while ($host.ui.RawUi.KeyAvailable){
			$key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp") 
			
			switch ($key.VirtualKeyCode) {
				$Bkey { 
					if(bkupPrompt -eq 1){ backup; 
						if(resetTimerPrompt -eq 1){ $timeout = $script:timeout } 
					}
					break 
				}
				$Dkey {
					printVars
					break
				}
				$Hkey {
					Write-Host $helpText
					break
				}
				$Nkey { 
					$script:pauseonbackup = !$pauseonbackup
					Write-Host "Pause on backup? $pauseonbackup"
					break
				}
				$Pkey { Write-Host "Script is paused."; pause; break }
				$Qkey { exit 0; break }
				$Rkey { if(resetTimerPrompt -eq 1){ $timeout = $script:timeout }; break }
				$Skey { 
					setVars; 
					if(resetTimerPrompt -eq 1){ $timeout = $script:timeout }
					break 
				}
			}
		}
		
		start-sleep 1
	}
}

function bkupPrompt (){
	$prompt = Read-Host -Prompt "Enter 'y' to backup now"
	if($prompt -like "y*"){ return 1 }
	else { return 0 }
}

function resetTimerPrompt (){
	Write-Host "Time between backups is currently set to $($script:timeout/60) minutes."
	$prompt = Read-Host -Prompt "Enter 'y' to reset timer"
	if($prompt -like "y*"){ 
		Write-Host "Resetting timer."
		return 1 
	}
	return 0
}

function backup (){
	Write-Output "($(get-date -f HH:mm-dd/MM/yyyy))  Backing up to $($bkupdirs[$bkupindex])" | Tee-Object -file $logPath/$logName -append
	$bkupdir = $bkupdirs[$bkupindex]
	Xcopy "$wrkdir" "$bkupdir" /s /f /y /c /d | Tee-Object -file $logPath/$logName -append
	$script:bkupindex++
	if($bkupindex -ge $bkupdirs.Length) { $script:bkupindex = 0 }
	Write-Output "Back up complete. Next back up directory set to $($bkupdirs[$bkupindex])"
	
	if($pauseonbackup){ 
		Write-Host "Script is paused."
		pause 
	}
}

setVars
if(bkupPrompt -eq 1){ backup }

while($true){
	timeout
	backup
}
