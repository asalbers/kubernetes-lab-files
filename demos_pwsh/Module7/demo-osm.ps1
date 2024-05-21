function CleanUp ([string] $done) {
    StartCleanUp $done
    helm uninstall chained-osm
    helm uninstall chained-original
    Rename-Item -Path ./mt3chained/templates/ingress -NewName _ingress    
    Rename-Item -Path ./mt3chained/templates/traffic-policy -NewName _traffic-policy    
    Rename-Item -Path ./mt3chained/templates/traffic-split -NewName _traffic-split
    Rename-Item -Path ./mt3chained/templates/_no-traffic-split -NewName no-traffic-split
    kubectl patch meshconfig osm-mesh-config -n osm-system --patch-file .\patch-enablePermissiveTraffic.yaml --type=merge
    kubectl delete ns chained-osm
    kubectl delete ns chained-original
    ExitScript
}

# Change to the demo folder
Set-Location OSM
. "..\..\CISendMessage.ps1"

# Default Application Insights IKeys
$ai1 = "71a02f24-dffe-4cf2-a4f3-fe47f992bc42"
$ai2 = "3e90427e-d9cf-4738-afc5-b971489adb35"

StartScript
DisplayStep "Before you continue with this script, please ensure you have completed the following setup steps"
DisplayStep "1. Install OSM into your cluster.  See: https://release-v1-1.docs.openservicemesh.io/docs/getting_started/setup_osm/"
DisplayStep "2. Create two Application Insights instances, one for each instance"
$aioriginal = read-host "3. Enter the mt3chained-original-ai Instrumentation Key ($($ai1))" 
if ([string]::IsNullOrWhiteSpace($aioriginal)) { $aioriginal = $ai1 }
$aiosm  = read-host "4. Enter the mt3chained-osm-ai Instrumentation Key ($($ai2))" 
if ([string]::IsNullOrWhiteSpace($aiosm)) { $aiosm = $ai2 }

DisplayStep "Navigate to the Settings page"
DisplayStep "Turn OFF Micro/Macro Pods (show full-size pods)"
DisplayStep "Navigate to the Namespace page"

DisplayStep "Next Step - Create chained-original namespace and install the Helm chart"
kubectl create ns chained-original
helm upgrade -i chained-original mt3chained --set namespace=chained-original --set ikey=$aioriginal
DisplayStep "Open a browser and navigate to the Ingress Controller IP address and chained-original path"
DisplayStep "For example: http://20.118.16.163/chained-original/"
DisplayStep "Observe that the site comes up properly and works.  Click the 'Autopilot' checkbox."
DisplayStep "Open to the Azure Portal and open the 'Live Metrics' blade of the Application Insights instance for this app"

DisplayStep "Next Step - Create chained-osm namespace and enable OSM in that namespace"
kubectl create ns chained-osm
osm namespace add chained-osm
DisplayStep "Next Step - Install the Helm Chart again into the chained-osm namespace"
helm upgrade -i chained-osm mt3chained --set namespace=chained-osm --set ikey=$aiosm
kubectl patch meshconfig osm-mesh-config -n osm-system --patch-file .\patch-enablePermissiveTraffic.yaml --type=merge

DisplayStep "Navigate to the Services page and observe that the web service is a ClusterIP, so the site can't be reached externally"
DisplayStep "Navigate to the Ingresses page and observe the chained-osm path"
DisplayStep "Open a browser and navigate to the Ingress Controller IP address and chained-osm path."
DisplayStep "Observe the 502 Bad Gateway error (not 404).  This path is not allowed"
DisplayStep "Next Step - Deploy the IngressBackend resource"
Rename-Item -Path ./mt3chained/templates/_ingress -NewName ingress 
helm upgrade chained-osm mt3chained

DisplayStep "Navigate to the Ingresses page and observe the chained-osm path"
DisplayStep "Open a browser and navigate to the Ingress Controller IP address and chained-osm path."
DisplayStep "Confirm that the site comes up."
DisplayStep "Click the Start button.  Confirm app is working correctly"

DisplayStep "Next Step - Turn off enablePermissiveTrafficPolicyMode"
kubectl patch meshconfig osm-mesh-config -n osm-system --patch-file .\patch-disablePermissiveTraffic.yaml --type=merge

DisplayStep "Click the Start button.  Confirm app is no longer working"
DisplayStep "Next Step - Deploy the Traffic Policy."

Rename-Item -Path ./mt3chained/templates/_traffic-policy -NewName traffic-policy 
helm upgrade chained-osm mt3chained

DisplayStep "Click the Start button.  Confirm app is working correctly.  Click the 'Autopilot' checkbox"
DisplayStep "Open to the Azure Portal and open the 'Live Metrics' blade of the Application Insights for the osm app"
DisplayStep "Confirm that traffic is flowing"

DisplayStep "Next Step - Deploy the Traffic Split."
Rename-Item -Path ./mt3chained/templates/_traffic-split -NewName traffic-split
Rename-Item -Path ./mt3chained/templates/no-traffic-split -NewName _no-traffic-split
helm upgrade chained-osm mt3chained

DisplayStep "Observe that the NodeJS service is being called about 50% of the time"
DisplayStep "Wait a few minutes and confirm in Application Insights that traffic is being split across two microservices"

DisplayStep "Next Step - Clean up."
CleanUp