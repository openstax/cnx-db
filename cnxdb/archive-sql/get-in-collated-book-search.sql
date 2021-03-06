-- ###
-- Copyright (c) 2013, Rice University
-- This software is subject to the provisions of the GNU Affero General
-- Public License version 3 (AGPLv3).
-- See LICENCE.txt for details.
-- ###

-- arguments: uuid:string, version:string, search_term:string
WITH RECURSIVE t(node, title, path, docs, value, depth, corder) AS (
SELECT nodeid, title, ARRAY[nodeid], ARRAY[documentid], documentid, 1, ARRAY[childorder]
FROM
  trees tr,
  modules m
WHERE
  m.uuid::text = %(uuid)s AND
  module_version(m.major_version, m.minor_version) = %(version)s AND
  tr.documentid = m.module_ident AND
  tr.parent_id IS NULL AND
  is_collated = True
UNION ALL
SELECT c1.nodeid, c1.title, t.path || ARRAY[c1.nodeid], t.docs || ARRAY[c1.documentid], c1.documentid, t.depth+1, t.corder || ARRAY[c1.childorder]
FROM trees c1 JOIN t ON (c1.parent_id = t.node)
WHERE NOT nodeid = any (t.path)
)
SELECT
m.uuid,
m.major_version as version,
ts_headline(COALESCE(t.title, m.name),
plainto{combiner}_tsquery(%(search_term)s),
E'StartSel="<span class=""q-match"">", StopSel="</span>", MaxFragments=0, HighlightAll=TRUE'
) as title,
ts_headline(fulltext,
plainto{combiner}_tsquery(%(search_term)s),
E'StartSel="<span class=""q-match"">", StopSel="</span>", MaxFragments=1, MaxWords=20, MinWords=15,'
) as snippet,
count_collated_lexemes(cft.item, cft.context, %(search_term)s) as matches,
ts_rank_cd(cft.module_idx, plainto{combiner}_tsquery(%(search_term)s)) AS rank
FROM
 collated_fti cft join
 modules m on cft.item = m.module_ident join
 t on t.value = m.module_ident

WHERE
 cft.context = t.docs[1] AND
 cft.module_idx @@ plainto{combiner}_tsquery(%(search_term)s)
ORDER BY
 rank DESC,
 t.path
;
