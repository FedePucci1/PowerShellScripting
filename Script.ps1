<#
.SYNOPSIS
    Esta es la seccion de ayuda proporcionada para el script.
    Este script simula un sistema de integracion continua, para ello, monitoriza un directorio
    y realiza ciertas acciones al detectar un cambio en el mismo.
    Si el directorio a monitorear tiene dentro subdirectorios, tambien seran monitoreados.
.DESCRIPTION
    -“listar”: muestra por pantalla los nombres de los archivos que sufrieron
    cambios (archivos creados, modificados, renombrados, borrados).
    -“peso”: muestra por pantalla el peso de los archivos que sufrieron cambios.
    -“compilar”: compila los archivos dentro de “c”, una ruta pasada por parametro
    y los guarda en una carpeta llamada “bin”, ubicada en el directorio donde se ejecuto el script.
    -“publicar”: copia el archivo compilado (el generado con la opción “compilar”) a un directorio pasado como parámetro “-s”.
    Cabe resaltar, que no se puede “publicar” sin “compilar”.
.PARAMETER -a 
    -a, seguido por una o mas acciones.
.PARAMETER -c  
    -c, seguido por una ruta.
.PARAMETER -s  
    -s, seguido por una ruta.
.EXAMPLE
    A continuacion se detallan ejemplos de ejecucion: 
    ./Script.ps1 -c ./Carpeta -a listar,peso
    ./Script.ps1 -c “./Con espacio” -a listar,peso
    ./Script.ps1 -c ./Carpeta -a listar,compilar,publicar -s ./Salidas/Publicar
    ./Script.ps1 -c ./Carpeta -a listar,compilar,publicar -s “./Salidas con espacio/Publicar”
    ./Script.ps1 -c “./Con espacio” -a listar,compilar,publicar -s ./Salidas/Publicar
    ./Script.ps1 -c “./Con espacio” -a listar,compilar,publicar -s “./Salidas con espacio/Publicar”
    Get-Help ./Script.ps1
#>

#Validacion de parametros
Param(
     [Parameter(Mandatory=$true)]
     [String] $codigo,
 
     [Parameter(Mandatory=$true)]
      $acciones,

     [Parameter()]
     [String] $salida
 )

$accionesArray=New-Object System.Collections.ArrayList;
$publicar=$false;
$compilar=$false;

#Validacion de las acciones
foreach ($i in $acciones) {
    if($i -eq "listar" -or $i -eq "peso" -or $i -eq "publicar" -or $i -eq "compilar"){
            $accionesArray.Add($i) | out-null;
    }else{
        Write-Host ""
        Write-Host "ERROR: la accion $i no esta permitida. Revise la ayuda del script para mas detalles."
        Write-Host ""
        exit
    }
}

#Validacion de la ruta de entrada
if(-not (Test-Path -Path "$codigo")){
    Write-Host ""
    Write-Host "ERROR: No existe el directorio a monitorear."
    Write-Host ""
    exit
} 

#Ver si estan compilar y publicar para las validaciones posteriores
foreach ($i in $accionesArray) {
    if($i -eq "publicar"){
            $publicar=$true
    }    
    if($i -eq "compilar"){
            $compilar=$true
    }    
    if($i -eq "listar"){
            $listar=$true
    }    
    if($i -eq "peso"){
            $peso=$true
    }
}

#Si no esta compilar, no se puede publicar
if($compilar -eq $false -and $publicar -eq $true){
    Write-Host ""
    Write-Host "ERROR: No se puede publicar sin previamente compilar. Revise la ayuda del script para mas detalles."
    Write-Host ""
    exit
}

#Validacion de la ruta de salida
if($compilar -eq $true -and $publicar -eq $true){

    if($salida -eq ''){
        Write-Host ""
        Write-Host "ERROR: No fue enviada la ruta de salida. Revise la ayuda del script para mas detalles."
        Write-Host ""
        exit
    }    
    if(-not (Test-Path -Path "$salida")){
        Write-Host ""
        Write-Host "ERROR: No existe el directorio de salida."
        Write-Host ""
        exit
    }
}

$global:Array=$accionesArray
$global:codigoArray=New-Object System.Collections.ArrayList;   
$global:salida=$salida
$global:publicar=$publicar
$global:codigo=Resolve-Path -Path $codigo


# Revisar permisos para monitorear la carpeta
# $permisos = $true
# $usuario = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# foreach ($p in (Get-Acl $global:codigo).access ){
# 	if ($p.IdentityReference.Value -eq $usuario -And $p.AccessControlType -eq "Deny") {		
# 		foreach ($noPuede in $p.FileSystemRights -split "," -replace " ","" ) {
# 			if (($noPuede -eq "Read") -or ($noPuede -eq "Write"))  {
# 				$permisos = $false
# 				break permisos
# 			} 			
# 		}		
# 	}
# }

# if($permisos -eq $false){
#     Write-Host ""
#     Write-Host "ERROR: No posee los permisos necesarios para monitorear la carpeta enviada por parametro."
#     Write-Host ""
#     exit
# }


#Monitor
$watcher=New-Object System.IO.FileSystemWatcher
$watcher.Path=$global:codigo
$watcher.IncludeSubdirectories= $true;
$watcher.EnableRaisingEvents = $true;

$action=
{
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    $path = $Event.SourceEventArgs.FullPath
    $pathOld = $Event.SourceEventArgs.OldFullPath

    Write-Host "Se ha producido un cambio en: $name"

    foreach($i in $global:Array){
        switch ($i) {
            'peso' {             
                $size=(Get-Item "$global:codigo/$name").length
                Write-Host ""
                Write-Host "Peso: $size Bytes" 
                Write-Host ""
            }
            'listar' {             
                $global:a = (Get-ChildItem -path $global:codigo)
                Write-Host ""
                Write-Host "Lista de archivos: "
                Write-Host ""
                Write-Host $global:a
            }
            'compilar' { 
                Write-Host ""
                Write-Host "Compilando..."
                Write-Host ""
                if (-not (Test-Path "./bin")){
                    New-Item "./bin" -itemType Directory
                }                
                if (-not (Test-Path "./bin/ArchivoCompilado.txt")){
                    New-Item "./ArchivoCompilado.txt" -itemType File
                }
                clear-content "./bin/ArchivoCompilado.txt"
                $global:codigoArray=New-Object System.Collections.ArrayList;    
                foreach($x in Get-ChildItem -Recurse -Path $global:codigo ){
					$global:codigoArray.Add( (Get-Content -Path $x.fullname) )
				}
                Set-Content -Path "./bin/ArchivoCompilado.txt" -Value $global:codigoArray
                Write-Host ""
                Write-Host "Compilacion finalizada con exito."
                Write-Host ""
                if ($global:publicar){
                    Write-Host ""
                    Write-Host "Publicando..."
                    Write-Host ""
                    Copy-Item -Path "./bin/ArchivoCompilado.txt" -Destination $global:salida
                    Write-Host ""
                    Write-Host "Publicacion finalizada con exito."
                    Write-Host ""
                }
            }
            Default {}
        }
    }
}

Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action -SourceIdentifier FSCreate-$codigo
Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action -SourceIdentifier FSChange-$codigo
Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action -SourceIdentifier FSDelete-$codigo
Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action -SourceIdentifier FSRename-$codigo
