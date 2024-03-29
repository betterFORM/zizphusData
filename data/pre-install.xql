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

declare variable $pp-dir := "/resources/commons/Priya Paul Collection";
declare variable $pp-collection := "/db" || $pp-dir;

declare variable $collection-permissions as xs:integer := util:base-to-integer(0755, 8);
declare variable $resource-permissions as xs:integer := util:base-to-integer(0600, 8);

(: START helper function :)
declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection(xmldb:encode($collection), xmldb:encode($components[1])),
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
declare function local:set-collection-resource-permissions($collection as xs:string, $owner as xs:string, $group as xs:string) {
    if(xmldb:collection-available($collection))
    then (
        let $resources :=
            for $resource in xmldb:get-child-resources(xmldb:encode($collection))
                return
                    xmldb:set-resource-permissions(xmldb:encode($collection), $resource, $owner, $group, $resource-permissions)
        let $collections :=
            for $child-collection in  xmldb:get-child-collections($collection)
                         let $permission := xmldb:set-collection-permissions(xmldb:encode($collection || "/" || $child-collection), $owner, $group, $collection-permissions)
                         return 
                                 local:set-collection-resource-permissions(xmldb:encode($collection || "/" || $child-collection), $owner, $group)
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
util:log($log-level, "Security: Done."),

util:log($log-level, "Creating common collections ..."),
local:mkcol('/db/', $pp-dir || '/VRA_images'),
local:mkcol('/db/system/config/db', 'resources/commons'),
util:log($log-level, "...DONE"),


util:log($log-level, "Storing files ..." || xmldb:encode($pp-collection) || ":" ||$dir || $pp-dir),
xmldb:store-files-from-pattern(xmldb:encode($pp-collection), $dir || $pp-dir, "w_*.xml"),
xmldb:store-files-from-pattern(xmldb:encode($pp-collection || '/VRA_images'), $dir || $pp-dir || '/VRA_images', "i_*.xml"),
xmldb:store-files-from-pattern('/db/system/config/db/resources/commons', $dir || '/system/config/db/resources/commons', '*.xconf'),
util:log($log-level, "...DONE"),

util:log($log-level, "Permissions: Set permissions for record  data..."),
local:set-collection-resource-permissions('/db/resources/commons/Priya Paul Collection', $biblio-admin-user, $biblio-users-group),
util:log($log-level, "...DONE"),

util:log($log-level, "... ALL DONE")

