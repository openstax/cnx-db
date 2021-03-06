-- ###
-- Copyright (c) 2013, Rice University
-- This software is subject to the provisions of the GNU Affero General
-- Public License version 3 (AGPLv3).
-- See LICENCE.txt for details.
-- ###

-- arguments: objid:string, objver:string
SELECT
m.uuid, module_version(m.major_version, m.minor_version)
FROM modules m
WHERE m.moduleid = %(objid)s and m.version = %(objver)s
ORDER BY m.revised DESC limit 1
