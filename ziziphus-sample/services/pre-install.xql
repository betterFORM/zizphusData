xquery version "3.0";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

(: The following external variables are set by the repo:deploy function :)
(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;

declare variable $log-level := "INFO";

(:~ Biblio security - admin user and users group :)
declare variable $biblio-admin-user := "editor";
declare variable $biblio-users-group := "biblio.users";

declare variable $local-dir := '/resources/services/repositories/global';
declare variable $local-collection := '/db' || $local-dir;


(: START helper function :)
declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

(: Helper function manage resource permissions :)
declare function local:set-collection-resource-permissions($collection as xs:string, $owner as xs:string, $group as xs:string, $permissions as xs:int) {
    if(xmldb:collection-available($collection))
    then (
        let $resources :=
            for $resource in xmldb:get-child-resources($collection)
                return
                    xmldb:set-resource-permissions($collection, $resource, $owner, $group, $permissions)
        let $collections :=
            for $child-collection in  xmldb:get-child-collections($collection)
                let $permission := xmldb:set-collection-permissions($collection || "/" || $child-collection, $owner, $group, $permissions)
                return 
                    local:set-collection-resource-permissions($collection || "/" || $child-collection, $owner, $group, $permissions)
         return ()
    ) else ()
};

(: END helper function :)

util:log($log-level, "Script: Running pre-install script ..."),

(: Create users and groups :)
util:log($log-level, fn:concat("Security: Creating user '", $biblio-admin-user, "' and group '", $biblio-users-group, "' ...")),
    if (xmldb:group-exists($biblio-users-group)) then ()
    else xmldb:create-group($biblio-users-group),
    if (xmldb:exists-user($biblio-admin-user)) then ()
    else xmldb:create-user($biblio-admin-user, $biblio-admin-user, $biblio-users-group, ()),
util:log($log-level, "... DONE"),

util:log($log-level, "Creating services collections ..."),
local:mkcol('/db/', $local-dir || '/persons'),
local:mkcol('/db/', $local-dir || '/organisations'),
local:mkcol('/db/', $local-dir || '/subjects'),
local:mkcol('/db/', $local-dir || '/externalmirrors'),
local:mkcol('/db/', $local-dir || '/externalmirrors/getty/aat'),
local:mkcol('/db/', $local-dir || '/externalmirrors/viaf/xml'),
local:mkcol('/db/system/config/db', 'resources/services/repositories'),
util:log($log-level, "... DONE"),

util:log($log-level, "Storing files ..."),
xmldb:store-files-from-pattern($local-collection || '/persons', $dir || $local-dir || '/persons', "*.xml"),
xmldb:store-files-from-pattern($local-collection || '/organisations', $dir || $local-dir || '/organisations', "*.xml"),
xmldb:store-files-from-pattern($local-collection || '/subjects', $dir || $local-dir || '/subjects', "*.xml"),
xmldb:store-files-from-pattern('/db/system/config/db/resources/services/repositories', $dir || '/system/config/db/resources/services/repositories', "*.xconf"),
util:log($log-level, "... DONE"),

util:log($log-level, "Permissions: Set permissions for record  data..."),
local:set-collection-resource-permissions('/db/resources/services/repositories/local/', $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8)),
util:log($log-level, "... DONE"),

util:log($log-level, "... ALL DONE")