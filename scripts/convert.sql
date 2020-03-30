USE ITIS;

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
           NULL AS accordingTo,
           NULL AS accordingToID,
           tu.update_date AS accordingToDate,
           (SELECT DISTINCT GROUP_CONCAT(documentation_id SEPARATOR ', ') FROM reference_links rl WHERE rl.tsn=h.TSN AND doc_id_prefix='PUB') AS referenceID
    FROM hierarchy h LEFT JOIN taxonomic_units tu ON h.TSN = tu.tsn
);

SELECT DISTINCT unaccept_reason FROM taxonomic_units;


# TODO: Hybrid formulas
# TODO: Nom code
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