Besten Dank für den Update.

Habe spot.tapp soeben auf den gPlug in Burgistein kopiert und zuerst dies hier erhalten:

see not-found.png

Nachdem ich dann über einen ssh Tunnel via localhost:50081 auf den gPlug verbunden habe, ist dann das webUI korrekt angezeigt worden:

see ok.png

Es ist also noch eine überraschende Abhängigkeit in der Tapp drin, über welche URL man auf den gPlug gelangt. Beim Fehler oben bin ich über die private URL auf den gPlugK in Burgistein gelangt: http://bgst.gantrisch-energie.ch/gPlugK/, die dann via SSH Tunnel und einem URL Mapping auf den gPlugK weiter geleitet wird.
