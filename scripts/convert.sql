USE ITIS;

DROP DATABASE IF EXISTS coldp;
CREATE DATABASE coldp DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_general_ci;

# TODO: Provisional
# TODO: Extinct
# Taxon
DROP TABLE IF EXISTS coldp.Taxon;
CREATE TABLE coldp.Taxon (
    SELECT h.TSN AS ID,
           h.Parent_TSN AS parentID,
           h.TSN AS nameID,
           FALSE AS provisional,
           (SELECT DISTINCT GROUP_CONCAT(expert SEPARATOR ', ') FROM reference_links rl INNER JOIN experts ON rl.documentation_id=experts.expert_id AND rl.doc_id_prefix='EXP' WHERE rl.tsn=h.TSN) AS accordingTo,
           NULL AS accordingToID,
           tu.update_date AS accordingToDate,
           (SELECT DISTINCT GROUP_CONCAT(documentation_id SEPARATOR ', ') FROM reference_links rl WHERE rl.tsn=h.TSN AND doc_id_prefix='PUB') AS referenceID
    FROM hierarchy h LEFT JOIN taxonomic_units tu ON h.TSN = tu.tsn
);


#SELECT tsn, expert FROM experts INNER JOIN reference_links rl ON experts.expert_id = rl.documentation_id AND experts.expert_id_prefix = rl.doc_id_prefix GROUP BY tsn HAVING count(*) > 1;

#SELECT DISTINCT unaccept_reason FROM taxonomic_units;
#SELECT DISTINCT n_usage, kingdom_id FROM taxonomic_units;
#SELECT DISTINCT name_usage FROM taxonomic_units;

# TODO: Hybrid formulas
# TODO: Nom status
# TODO: Nom ref
# TODO: Nom original
# Name
DROP TABLE IF EXISTS coldp.Name;
CREATE TABLE coldp.Name (
    SELECT TSN AS ID,
           complete_name AS scientificName,
           tal.taxon_author AS authorship,
           LOWER(tut.rank_name) AS `rank`,
           NULL AS genus,
           NULL AS infragenericEpithet,
           NULL AS specificEpithet,
           NULL AS infraspeciesEpithet,
           CASE WHEN tu.kingdom_id=1 THEN 'bacterial' WHEN tu.kingdom_id=2 THEN 'zoological' WHEN tu.kingdom_id=3 THEN 'botanical' WHEN tu.kingdom_id=4 THEN 'botanical' WHEN tu.kingdom_id=5 THEN 'zoological' WHEN tu.kingdom_id=6 THEN 'botanical' WHEN tu.kingdom_id=7 THEN 'bacterial' END AS code,
           CONCAT('https://www.itis.gov/servlet/SingleRpt/SingleRpt?search_topic=TSN&search_value=', TSN) AS link
    FROM taxonomic_units tu
        LEFT JOIN taxon_authors_lkp tal ON tu.taxon_author_id = tal.taxon_author_id
        LEFT JOIN taxon_unit_types tut ON tu.rank_id = tut.rank_id AND tu.kingdom_id = tut.kingdom_id
    WHERE tu.rank_id < 220
    UNION ALL
    SELECT TSN AS ID,
           complete_name AS scientificName,
           tal.taxon_author AS authorship,
           LOWER(tut.rank_name) AS `rank`,
           unit_name1 AS genus,
           NULL       AS infragenericEpithet,
           unit_name2 AS specificEpithet,
           unit_name3 AS infraspeciesEpithet,
           CASE WHEN tu.kingdom_id=1 THEN 'bacterial' WHEN tu.kingdom_id=2 THEN 'zoological' WHEN tu.kingdom_id=3 THEN 'botanical' WHEN tu.kingdom_id=4 THEN 'botanical' WHEN tu.kingdom_id=5 THEN 'zoological' WHEN tu.kingdom_id=6 THEN 'botanical' WHEN tu.kingdom_id=7 THEN 'bacterial' END AS code,
           CONCAT('https://www.itis.gov/servlet/SingleRpt/SingleRpt?search_topic=TSN&search_value=', TSN) AS link
    FROM taxonomic_units tu
        LEFT JOIN taxon_authors_lkp tal ON tu.taxon_author_id = tal.taxon_author_id
        LEFT JOIN taxon_unit_types tut ON tu.rank_id = tut.rank_id AND tu.kingdom_id = tut.kingdom_id
    WHERE tu.rank_id >= 220 AND unit_name2 NOT LIKE '(%)'
    UNION ALL
    SELECT TSN AS ID,
           complete_name AS scientificName,
           tal.taxon_author AS authorship,
           LOWER(tut.rank_name) AS `rank`,
           unit_name1 AS genus,
           unit_name2 AS infragenericEpithet,
           unit_name3 AS specificEpithet,
           unit_name4 AS infraspeciesEpithet,
           CASE WHEN tu.kingdom_id=1 THEN 'bacterial' WHEN tu.kingdom_id=2 THEN 'zoological' WHEN tu.kingdom_id=3 THEN 'botanical' WHEN tu.kingdom_id=4 THEN 'botanical' WHEN tu.kingdom_id=5 THEN 'zoological' WHEN tu.kingdom_id=6 THEN 'botanical' WHEN tu.kingdom_id=7 THEN 'bacterial' END AS code,
           CONCAT('https://www.itis.gov/servlet/SingleRpt/SingleRpt?search_topic=TSN&search_value=', TSN) AS link
    FROM taxonomic_units tu
        LEFT JOIN taxon_authors_lkp tal ON tu.taxon_author_id = tal.taxon_author_id
        LEFT JOIN taxon_unit_types tut ON tu.rank_id = tut.rank_id AND tu.kingdom_id = tut.kingdom_id
    WHERE tu.rank_id >= 220 AND unit_name2 LIKE '(%)'
);

# TODO: Status
# Synonym
DROP TABLE IF EXISTS coldp.Synonym;
CREATE TABLE coldp.Synonym (
    SELECT CONCAT_WS('-', tsn_accepted, tsn) AS ID,
           tsn_accepted AS taxonID,
           tsn AS nameID,
           'synonym' AS status
FROM synonym_links sl
);


# Distribution
DROP TABLE IF EXISTS coldp.Distribution;
CREATE TABLE coldp.Distribution (
    SELECT
        tsn AS taxonID,
        geographic_value AS area,
        'text' AS gazetteer,
        NULL AS status,
        NULL AS referenceID
    FROM geographic_div
);

# VernacularNames
DROP TABLE IF EXISTS coldp.VernacularName;
CREATE TABLE coldp.VernacularName (
    SELECT
        v.tsn AS taxonID,
        vernacular_name AS name,
        NULL AS transliteration,
        language,
        NULL AS country,
        NULL AS area,
        NULL AS sex,
        IF(vrl.doc_id_prefix='PUB', vrl.documentation_id, NULL) AS referenceID
    FROM vernaculars v
    LEFT JOIN vern_ref_links vrl ON v.vern_id = vrl.vern_id
);


# References
DROP TABLE IF EXISTS coldp.Reference;
CREATE TABLE coldp.Reference (
    SELECT
        publication_id AS ID,
        NULL AS citation,
        reference_author AS author,
        title,
        YEAR(actual_pub_date) AS year,
        publication_name AS source,
        NULL As details,
        pub_comment AS remarks
    FROM publications
);