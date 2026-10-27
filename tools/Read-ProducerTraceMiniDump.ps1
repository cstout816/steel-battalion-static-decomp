[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DumpPath,
    [Parameter(Mandatory = $true)]
    [string]$MapPath
)

$ErrorActionPreference = 'Stop'
$bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $DumpPath).Path)
$mapLines = Get-Content -LiteralPath $MapPath
function U32([int]$o) { [BitConverter]::ToUInt32($bytes, $o) }
function U64([int]$o) { [BitConverter]::ToUInt64($bytes, $o) }
function MapString([uint32]$rva) {
    $length = U32 ([int]$rva)
    if ($length -gt 32768 -or ($rva + 4 + $length) -gt $bytes.Length) { return '' }
    [Text.Encoding]::Unicode.GetString($bytes, [int]$rva + 4, [int]$length)
}
function Resolve-Address([uint64]$address, $symbols) {
    $lo=0; $hi=$symbols.Count-1; $best=-1
    while($lo -le $hi){$mid=[int](($lo+$hi)/2); if($symbols[$mid].Address -le $address){$best=$mid;$lo=$mid+1}else{$hi=$mid-1}}
    if($best -lt 0){return '?'}
    $entry=$symbols[$best]
    if(($address-$entry.Address) -gt 0x10000){return '?'}
    return ('{0}+0x{1:X}' -f $entry.Name,($address-$entry.Address))
}

$streamCount = U32 8
$dirRva = U32 12
$streams = @{}
for($i=0;$i -lt $streamCount;$i++){
    $o=[int]$dirRva+($i*12)
    $streams[(U32 $o)] = [pscustomobject]@{Size=(U32 ($o+4));Rva=(U32 ($o+8))}
}
if(-not $streams.ContainsKey([uint32]3) -or -not $streams.ContainsKey([uint32]4)){throw 'Dump lacks thread or module list streams.'}

$modules=@()
$modStream=$streams[[uint32]4]
$moduleCount=U32 ([int]$modStream.Rva)
for($i=0;$i -lt $moduleCount;$i++){
    $o=[int]$modStream.Rva+4+($i*108)
    $modules += [pscustomobject]@{Base=(U64 $o);Size=(U32 ($o+8));Name=(MapString (U32 ($o+20)))}
}
$exe=$modules|Where-Object {$_.Name -match 'your_game_recomp(?:_producer_trace)?\.exe$'}|Select-Object -First 1
if(-not $exe){throw 'ProducerTrace image was not found in the dump module list.'}
$symbols=@()
$preferredBase=[uint64]0x140000000
foreach($line in $mapLines){
    $parts=$line.Trim() -split '\s+'
    if($parts.Count -ge 3 -and $parts[0] -match '^[0-9A-Fa-f]{4}:[0-9A-Fa-f]{8}$' -and $parts[2] -match '^[0-9A-Fa-f]{16}$'){
        $preferredAddress=[Convert]::ToUInt64($parts[2],16)
        $symbols += [pscustomobject]@{Address=($preferredAddress-$preferredBase+$exe.Base);Name=$parts[1]}
    }
}
$symbols=@($symbols|Sort-Object Address)

$threadStream=$streams[[uint32]3]
$threadCount=U32 ([int]$threadStream.Rva)
"Dump: $DumpPath"
"Image base: 0x{0:X} size 0x{1:X}; threads: {2}" -f $exe.Base,$exe.Size,$threadCount
for($i=0;$i -lt $threadCount;$i++){
    $o=[int]$threadStream.Rva+4+($i*48)
    $id=U32 $o
    $stackStart=U64 ($o+24); $stackSize=U32 ($o+32); $stackRva=U32 ($o+36)
    $ctxSize=U32 ($o+40); $ctxRva=U32 ($o+44)
    if($ctxSize -lt 256 -or ($ctxRva+256) -gt $bytes.Length){continue}
    $rsp=U64 ([int]$ctxRva+152); $rip=U64 ([int]$ctxRva+248)
    $ripModule=$modules|Where-Object {$rip -ge $_.Base -and $rip -lt ($_.Base+$_.Size)}|Select-Object -First 1
    $ripLabel=if($ripModule){'{0}+0x{1:X}' -f [IO.Path]::GetFileName($ripModule.Name),($rip-$ripModule.Base)}else{'outside listed image'}
    $ripSymbol=Resolve-Address $rip $symbols
    "`nTID {0}: RIP=0x{1:X} ({2}; {3}) RSP=0x{4:X} stackBytes={5}" -f $id,$rip,$ripLabel,$ripSymbol,$rsp,$stackSize
    if($stackRva -and $stackSize -ge 8 -and ($stackRva+$stackSize) -le $bytes.Length){
        $seen=@{}
        for($j=0;$j+8 -le $stackSize;$j+=8){
            $candidate=U64 ([int]$stackRva+$j)
            if($candidate -ge $exe.Base -and $candidate -lt ($exe.Base+$exe.Size)){
                $label=Resolve-Address $candidate $symbols
                if(-not $seen.ContainsKey($label)){$seen[$label]=$true;"  +0x{0:X}: 0x{1:X} {2}" -f $j,$candidate,$label}
                if($seen.Count -ge 16){break}
            }
        }
    }
}
