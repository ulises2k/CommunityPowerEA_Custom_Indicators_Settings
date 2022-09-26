# Script for CommunityPower EA >= 2.49. Convert Indicator Set to Comma Separated
#
# Autor: Ulises Cune (@Ulises2k)
#
#RUN, open "cmd.exe" and write this:
#powershell -ExecutionPolicy Bypass -File "CommunityPowerEA_MyDefault.ps1"
#
#
Function Get-IniFile {
    Param(
        [string]$FilePath
    )
    $ini = [ordered]@{}
    switch -regex -file $FilePath {
        "^\s*(.+?)\s*=\s*(.*)$" {
            $name, $value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";"))) {
                if ($value.Contains('||') ) {
                    $ini[$name] = $value.Split('||')[0]
                    continue
                }
                else {
                    $ini[$name] = $value
                    continue
                }
            }
        }
    }
    $ini
}

function Set-OrAddIniValue {
    Param(
        [string]$FilePath,
        [hashtable]$keyValueList
    )
    $content = Get-Content $FilePath
    $keyValueList.GetEnumerator() | ForEach-Object {
        if ($content -match "^$($_.Key)\s*=") {
            $content = $content -replace "^$($_.Key)\s*=(.*)", "$($_.Key)=$($_.Value)"
        }
        else {
            $content += "$($_.Key)=$($_.Value)"
        }
    }
    $content | Set-Content $FilePath
}

Function ButtonConvertIndicator {
    Param(
        [string]$FilePath
    )
    $mivalue = ''
    switch -regex -file $FilePath {
        "^\s*(.+?)\s*=\s*(.*)$" {
            $name, $value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";"))) {
                if ($value.Contains('||') ) {
                    $value = $value.Split('||')[0]
                }
                #Number
                if ($value -match "^[\d\.]+$") {
                    $value = $value
                }
                else {
                    #Bool
                    if ($value -eq 'true' ) {
                        $value = '1'
                    }
                    #Bool
                    if ($value -eq 'false' ) {
                        $value = '0'
                    }
                    #String
                    if (($value -ne '1') -and ($value -ne '0' )) {
                        $value = "'" + $value + "'"
                    }
                }
                #First value
                if ( $mivalue -eq '') {
                    $mivalue = $value
                }
                else {
                    $mivalue = $mivalue + "," + $value
                }
                continue
            }
        }
    }
    return $mivalue
}

#######################GUI################################################################
### API Windows Forms ###
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

### Create form ###
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Convert Indicator Set to Comma Separated - CommunityPower EA'
$form.Size = '700,300'
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = $form.Size
$form.MaximizeBox = $False
$form.Topmost = $True

### Define controls ###
# Button
$button = New-Object System.Windows.Forms.Button
$button.Location = '5,10'
$button.Size = '300,20'
$button.Text = 'Convert Indicator Set to Comma Separated'

# Button
$button2 = New-Object System.Windows.Forms.Button
$button2.Location = '5,40'
$button2.Size = '300,20'
$button2.Text = 'Clear'

# Label
$label = New-Object System.Windows.Forms.Label
$label.Location = '5,100'
$label.AutoSize = $True
$label.Text = 'Drag and Drop Indicator file (*.set) here:'

# Label
$label2 = New-Object System.Windows.Forms.Label
$label2.Location = '5,180'
$label2.AutoSize = $True
$label2.Text = 'Indicator parameters (comma separated):'

# Listbox
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = '5,120'
$listBox.Size = '600,50'
$listBox.Anchor = ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top)
$listBox.IntegralHeight = $False
$listBox.AllowDrop = $True

# TextBox
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = '5,200'
$textBox.Size = '600,40'
$textbox.Multiline = $true

# StatusBar
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = 'Ready'

## Add controls to form ###
$form.SuspendLayout()
$form.Controls.Add($button)
$form.Controls.Add($button2)
$form.Controls.Add($label)
$form.Controls.Add($label2)
$form.Controls.Add($listBox)
$form.Controls.Add($textBox)
$form.Controls.Add($statusBar)
$form.ResumeLayout()

### Write event handlers ###
# ConvertIndicator
$button_Click = {
    foreach ($item in $listBox.Items) {
        $i = Get-Item -LiteralPath $item
        if (!($i -is [System.IO.DirectoryInfo])) {
            $textBox.Text = ButtonConvertIndicator -filePath $item
            $statusBar.Text = ("Converted Set File Comma Separated")
        }
    }
}

# Clear ListBox
$button2_Click = {
    $listBox.Items.Clear()
}

# Drag And Drop Custom Indicator Set File
$listBox_DragOver = [System.Windows.Forms.DragEventHandler] {
    if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $_.Effect = 'Copy'
    }
    else {
        $_.Effect = 'None'
    }
}

# Drag And Drop Custom Indicator Set File
$listBox_DragDrop = [System.Windows.Forms.DragEventHandler] {
    foreach ($filename in $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)) {
        $listBox.Items.Add($filename)
    }
}

### Wire up events ###
$button.Add_Click($button_Click)
$button2.Add_Click($button2_Click)
$listBox.Add_DragOver($listBox_DragOver)
$listBox.Add_DragDrop($listBox_DragDrop)

#### Show form ###
[void] $form.ShowDialog()
