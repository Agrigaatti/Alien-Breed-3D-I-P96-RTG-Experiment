#
# bin2src source destination valuesperline linespergroup bytesize
# G:\Amiga\GIT\AB3DI\debug\bin2src G:\Amiga\GIT\AB3DI\data\math\constantfile G:\Amiga\GIT\AB3DI\data/rtg/math/constantfile.s 4 32 w
#
param ([Parameter(Mandatory)]$i, $o, $l, $g, $s)

[byte[]]$data = [System.IO.File]::ReadAllBytes($i) 
[string[]]$hex = [System.BitConverter]::ToString($data).split('-')
[string]$src = ""
[string]$sep = ""
[int]$lcounter = 0
[string]$data = ""

[int]$gcounter = $g
[string]$size = $s

foreach ($item in $hex) {
    if( $size -eq "w") {
        $data = $data +  $item 
        if( $data.length -lt 4) {
            continue
        }
        
        $item = $data
        $data = ""
    } elseif ($size -eq "l") {
        $data = $data +  $item 
        if( $data.length -lt 8) {
            continue
        }
        
        $item = $data
        $data = ""
    } else {
        $size = "b"
    }

    if($lcounter -eq 0) {
        if( $g -ne 0) {
            $gcounter -= 1
            if( $gcounter -lt 0) {
                $src += "`n"
                $gcounter = $g
            }     
        }
        $src += "`n dc." + $size + " "
        $sep = "" 
        $lcounter = $l
    } else {
        $sep = ","
    }
    $src += $sep + "$" + $item
    $lcounter -= 1
}
[System.IO.File]::WriteAllText($o, $src, [System.Text.Encoding]::ASCII)