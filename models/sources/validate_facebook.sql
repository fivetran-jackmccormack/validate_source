{# /* Golden Tables Schema ends with */ #}
{% set goldenSchema = 'ft_golden' %}
{# /* Pattern to search for schemas / tables, exclude golden tables */ #}
{% set tablePattern = '%' %}
{# /* Find all _golden sources to create a list of source wildcards */ #}
{% set sourcePattern = "facebook_ads_%" %}
{# /* Specific schemas to exclude */ #}
{% set excludeSchemas = ["facebook_ads_revenuerollinc","facebook_ads_trainingmaskinc","facebook_ads_orgnametest","facebook_ads_mossventuresllc"] %}
{# /* Specific tables to exclude */ #}
{% set excludeTables = ["fivetran_audit"] %}
{# /* Refresh golden tables, false = use existing golden schema, true = rebuild by unioning tables detected in source patterns */ #}
{% set refreshGolden = false %}
{# /* executionMode false = looking at the logs to see what queries would run, true = actually execute queries */ #}
{% set executionMode = false %}
{# /* call the validation macro */ #}
{{ validate_tables(goldenSchema, tablePattern, sourcePattern, excludeSchemas, excludeTables, refreshGolden, executionMode) }}

{# /* All of the tables that have been validated across the sources */ #}
select table_name, table_schema from `{{sourcePattern[:-1]}}{{goldenSchema}}`.`INFORMATION_SCHEMA`.`TABLES`




