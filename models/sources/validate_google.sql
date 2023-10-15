{# /* Golden Tables Schema ends with */ #}
{% set goldenSchema = 'jmc_golden' %}
{# /* Pattern to search for schemas / tables, exclude golden tables */ #}
{% set tablePattern = '%' %}
{# /* Find all _golden sources to create a list of source wildcards */ #}
{% set sourcePattern = "jmc_bq_%" %}
{# /* Specific schemas to exclude */ #}
{% set excludeSchemas = ["google_ads_trainingmaskinc","google_ads_orgnametest","google_ads_revenuerollinc"] %}
{# /* Specific tables to exclude */ #}
{% set excludeTables = ["fivetran_audit"] %}
{# /* Refresh golden tables, false = use existing golden schema, true = rebuild by unioning tables detected in source patterns */ #}
{% set refreshGolden = false %}
{# /* executionMode false = looking at the logs to see what queries would run, true = actually execute queries */ #}
{% set executionMode = true %}
{# /* goldenData false = only take the structure of the tables for the golden tables, true = actually take the data from the tables also into the golden table*/ #}
{% set goldenData = false %}
{# /* call the validation macro */ #}
{{ validate_tables(goldenSchema, tablePattern, sourcePattern, excludeSchemas, excludeTables, refreshGolden, executionMode, goldenData) }}

{# /* All of the tables that have been validated across the sources */ #}
select table_name, table_schema from `{{sourcePattern[:-1]}}{{goldenSchema}}`.`INFORMATION_SCHEMA`.`TABLES`




