xquery version "3.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

declare variable $target external;
(: cleanup and reindex :)
 xmldb:remove($target || "/priyapaul"), xmldb:reindex("/db")