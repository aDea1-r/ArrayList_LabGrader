<#
    aDea1's Array List lab grader.
    Prerequisites: Create  subdirectory for each student, and place their lab files inside. 
    The program will compile the student's labs, move the compiled runner files into each subdirectory, execute the runner files, and display the file path of
    any labs which do not output the exact same data as the included output files. 

    Please manually validate each grade, no results are guarenteed, and my sample size of 1 set of labs is too small to predict the accuracy of this program.

    This program assumes you already have environmental variables set, namely JAVA_HOME, PATH, and CLASSPATH. It also assumes group policy has already been set. 
    This program assumes that Adeel's labs are all done correctly, as they have been used to generate output logs. Any other java file that produces identical 
    ouput will be marked correct. 
#>

$debugMode = $false
$ver = "1.0"
$Host.UI.RawUI.WindowTitle = "aDea1's ArrayList Lab Grader v$ver"

Push-Location $PSScriptRoot

Function txtequals{ #Compares two text files, for equality. Takes txt1 as first argument, and txt2 as second argument. Note: Returns false if txts are both empty
    $stuff0 = Get-Content $args[0]
    $stuff1  =Get-Content $args[1]
    if ($stuff0 -and $stuff1) {
        $output = -not (Compare-Object -ReferenceObject $stuff0 -DifferenceObject $stuff1) #returns a String of chars that appear in both files
    } else {
        $output = $false
    }
    return $output
}
Function unzip { #accepts arg0 as zip name, with full file path, and file extension
	$folderName = (Split-Path -Path $args[0] -Leaf -Resolve)
    $folderName = $folderName.Remove($folderName.Length-4,4)
	mkdir $folderName | Out-Null
	Expand-Archive -Path $args[0] -DestinationPath ".\$folderName"
    Remove-Item –path $args[0]
}

###### Start Main Method #######

if ($debugMode) { #Used to hide java compiler errors, and runtime errors from output, as script is handled to deal with them already
    $ErrorActionPreference = 'Continue'
} else {
    $ErrorActionPreference = "SilentlyContinue"
}

$zipList = Get-ChildItem -Path ".\*.zip" #Create array of zips in folder, and unzip them. 
$zipList | ForEach-Object -Process {
    unzip $_
}

$folderlist = Get-ChildItem -Directory #creates array of folders in root, and loops through them. 
$folderlist | ForEach-Object -Process {
    if (($_ -inotmatch "runners") -and ($_ -inotmatch "solutions") -and ($_ -inotmatch "nullLabs")) { #exclude script folders from student folders lists
        $studentName = $_
       
        
        $lablist = Get-ChildItem -Path "$_\*.java" #Create array containing all student-submitted labs
		$lablist | ForEach-Object -Process { #Compile all student-submitted labs
            javac $_ 
        }

        #Checks if all labs are present. If a lab is missing, the script will copy in a null class file, and will be marked as incorrect later.
        $nullLabList = Get-ChildItem -Path "$PSScriptRoot\nullLabs\*"
        $nullLabList | ForEach-Object -Process {
            $labName = (Split-Path -Path $_ -Leaf -Resolve)
            $isPresent = Test-Path "$studentName\$labName"
            if(-not $isPresent) {
                Copy-Item -Path $_ -Destination $studentName
            }
        }
        
        Copy-Item -Path "$PSScriptRoot\runners\*" -Filter *.class -Destination $_ -Recurse -Container -Force #Copy runner files

        $runnerlist = Get-ChildItem -Path "$_\*Runner.class"
        $runnerlist | ForEach-Object -Process { #Executes each runner file, and logs output to individual text files
            
            #Get name of runner file
            $RunnerName = (Split-Path -Path $_ -Leaf -Resolve)
            $RunnerName = $RunnerName.Remove($RunnerName.Length-6,6)
            
            #runs class file, and logs output to txt files
            $runnerrunner = Start-Process ".\RunnerRunner.bat" -ArgumentList "$RunnerName $studentName" -PassThru -WindowStyle Hidden
            Wait-Process -id $runnerrunner.ID -timeout 1
            if (-not $runnerrunner.hasExited) {
                taskkill /T /F /PID $runnerrunner.ID | Out-Null
            }

            #Validate Accuracy of Lab Output
            $txtSample = "$studentName\$RunnerName.txt"
            $txtSolution = "solutions\$RunnerName.txt"
            $doesMatch = txtequals $txtSample $txtSolution
            if (-not $doesMatch) { #produce output if error is found in lab
                Write-Host "$studentName $RunnerName is not correct."
            }
        }
    }
}

<# 
    Errors Successfully Tested: 
    Runtime
    Syntax
    Logic
    Incomplete
    Trolls (Terminates programs after 1 second)
#>