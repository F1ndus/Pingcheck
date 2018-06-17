
$user = "dslf-config"
$pw = "" #Router Password
$euw_ip = "104.160.141.3"
$ip = "" #Router IP

function WriteXmlToScreen ([xml]$xml)
{
    $StringWriter = New-Object System.IO.StringWriter;
    $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter;
    $XmlWriter.Formatting = "indented";
    $xml.WriteTo($XmlWriter);
    $XmlWriter.Flush();
    $StringWriter.Flush();
    Write-Output $StringWriter.ToString();
}

function PrintKB ([string]$string)
{
	$downstream = [double]$string.Split(",")[0]
	$outstr = " " +($downstream / 1000)
	return $outstr
}

function PrintPing([string]$ip)
{
	$ping = Test-Connection $ip
	$durchschnitt = 0.0
	foreach($p in $ping)
	{
		if($p.ResponseTime -gt 3)
		{
			$durchschnitt = $durchschnitt + $p.ResponseTime
			#$p.Address + ": " + $p.ResponseTime +"ms"
		}
	}
	"["+$ip+"] Durchschnitt: " + ($durchschnitt / 4) + "ms"
}

	#MAX DL

# Erstmal einen WebClient erzeugen, der später mit der Box spricht
$w=New-Object System.Net.WebClient

# Das Encoding sollte immer UTF8 sein.
$w.Encoding=[System.Text.Encoding]::UTF8

# Eine erste Abfrage ohne SSL
# Auch im http-Header muss stehen, dass die Kommunikation per UTF-8 kodiert ist
$w.Headers.Set("Content-Type", 'text/xml; charset="utf-8"')

# Der Funktionsaufruf kommt in den Header SOAPACTION
$w.Headers.Set("SOAPACTION", 'urn:dslforum-org:service:DeviceInfo:1#GetSecurityPort')

# Der SOAP-Aufruf wird in XML verpackt, und zwar...
# ... beginnt er mit einem immer gleichen Header.
$query='<?xml version="1.0"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
        s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <s:Body> ' +
        # Dann kommt nochmal der Aufruf, diesmal steht der Funktionsname vorne
        '<u:GetSecurityPort xmlns:u="urn:dslforum-org:service:DeviceInfo:1">
        </u:GetSecurityPort>' +
        # Und das Ende ist auch immer gleich
        '</s:Body>
        </s:Envelope>'

# Diese XML-Abfrage schickt der Web-Client mit der Funktion UploadString an die Box.
# Der genaue URL gehört zum Service (siehe Artikel)
# Die Typ-Umwandlung im XML macht aus der Antwort gleich eine Baumstruktur, ...
$str = "http://" + $ip + ":49000/upnp/control/deviceinfo"
$r = [xml]$w.UploadString($str,$query)

# ... in der sich die gesuchte Information über ihren Namen ansprechen lässt.
# In diesem Falle ist das der Port, auf dem die Box einen SSL-gesicherten Zugang für SOAP bietet.
$port=$r.Envelope.Body.GetSecurityPortResponse.NewSecurityPort

# Der WebClient enthält die Antowrt-Header aus der vorigen Abfrage. Daher diese neu setzen:
$w.Headers.Set("Content-Type", 'text/xml; charset="utf-8"')

# Ein anderer Service, eine andere Action
$w.Headers.Set("SOAPACTION", 'urn:dslforum-org:service:WANDSLInterfaceConfig:1#GetInfo')

$query='<?xml version="1.0"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
        s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <s:Body> ' +
        # Auch hier gehören der andere Service und die andere Action hin
        '<u:GetInfo xmlns:u="urn:dslforum-org:service:WANDSLInterfaceConfig:1">
        </u:GetInfo>' +
        # Und das Ende ist auch immer gleich
        '</s:Body>
        </s:Envelope>'

# Der WebClient braucht nur die Zugangsdaten, dann wickelt er das Login ganz allein ab.
# dslf-config ist der im TR-64-Standard definierte Name.
$w.Credentials=New-Object System.Net.NetworkCredential($user,$pw)

# Das SSL-Zertifikat der Box ist nicht so signiert, dass es der sehr genauen Prüfung im WebClient standhält.
# Daher würde keine Verbindung zu Stande kommen, wenn man nicht die  
# SSL-Zertifikatprüfung für diesen Prozess ausschaltet.
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Query abschicken. Diesmal sind drei Dinge anders:
# - https statt http
# - Der eben ermittelte Port statt 49000
# - Der URL zum Service (siehe Artikel)
$str = "https://" + $ip + ":"+$port+"/upnp/control/wandslifconfig1"
$r = [xml]$w.UploadString($str,$query)
$max_dl = $r.Envelope.Body.GetInfoResponse.NewDownstreamCurrRate
$max_ul = $r.Envelope.Body.GetInfoResponse.NewUpstreamCurrRate

"Max_dl " + ($max_dl / 8) + "KB/s"
"Max_ul " + ($max_ul / 8) + "KB/s"

#CURRENT DL AND PING

# Erstmal einen WebClient erzeugen, der später mit der Box spricht
$w=New-Object System.Net.WebClient

# Das Encoding sollte immer UTF8 sein.
$w.Encoding=[System.Text.Encoding]::UTF8

# Eine erste Abfrage ohne SSL
# Auch im http-Header muss stehen, dass die Kommunikation per UTF-8 kodiert ist
$w.Headers.Set("Content-Type", 'text/xml; charset="utf-8"')

# Der Funktionsaufruf kommt in den Header SOAPACTION
$w.Headers.Set("SOAPACTION", 'urn:dslforum-org:service:WANCommonInterfaceConfig:1#X_AVM-DE_GetOnlineMonitor')

# Der SOAP-Aufruf wird in XML verpackt, und zwar...
# ... beginnt er mit einem immer gleichen Header.
$query='<?xml version="1.0"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
        s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
        <s:Body> ' +
        # Dann kommt nochmal der Aufruf, diesmal steht der Funktionsname vorne
        '<u:X_AVM-DE_GetOnlineMonitor xmlns:u="urn:dslforum-org:service:WANDSLInterfaceConfig:1">
		<NewSyncGroupIndex></NewSyncGroupIndex>
        </u:X_AVM-DE_GetOnlineMonitor>' +
        # Und das Ende ist auch immer gleich
        '</s:Body>
        </s:Envelope>'
		
# Der WebClient braucht nur die Zugangsdaten, dann wickelt er das Login ganz allein ab.
# dslf-config ist der im TR-64-Standard definierte Name.
$w.Credentials=New-Object System.Net.NetworkCredential($user,$pw)

# Das SSL-Zertifikat der Box ist nicht so signiert, dass es der sehr genauen Prüfung im WebClient standhält.
# Daher würde keine Verbindung zu Stande kommen, wenn man nicht die  
# SSL-Zertifikatprüfung für diesen Prozess ausschaltet.
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Diese XML-Abfrage schickt der Web-Client mit der Funktion UploadString an die Box.
# Der genaue URL gehört zum Service (siehe Artikel)
# Die Typ-Umwandlung im XML macht aus der Antwort gleich eine Baumstruktur, ...
$str = 'http://' + $ip + ':49000/upnp/control/wancommonifconfig1'
$r = [xml]$w.UploadString($str,$query);

# Wieder steckt die gewünschte Information im XML-Baum.
#WriteXmlToScreen($r)
$down = $r.Envelope.Body."X_AVM-DE_GetOnlineMonitorResponse".Newds_current_bps
$mem = PrintKB($down)
"Down: " + $mem + " Kb/s("+([double]$mem / ([double]$max_dl / 8)) * 100+"%)"
$up = $r.Envelope.Body."X_AVM-DE_GetOnlineMonitorResponse".Newus_current_bps
$mem2 = PrintKB($up)
"UP: " + $mem2 + " Kb/s("+([double]$mem2 / ([double]$max_ul / 8)) * 100+"%)"
PrintPing($euw_ip)
PrintPing("google.de")





