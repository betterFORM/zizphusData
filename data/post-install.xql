xquery version "3.0";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

(: The following external variables are set by the repo:deploy function :)
(: file path pointing to the exist installation directory :)
declare variable $home external;
(: the target collection into which the app is deployed :)
declare variable $target external;

declare variable $log-level := "INFO";

util:log($log-level, "Script: Running post-install script ..."),

util:log($log-level, "Cleaning up ...")
,xmldb:remove($target || '/resources')
,xmldb:remove($target || '/system')


,util:log($log-level, "...DONE")
