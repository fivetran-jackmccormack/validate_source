{% macro validate_tables(goldenSchema, tablePattern, sourcePattern, excludeSchemas, excludeTables, excludeColumns, refreshGolden, executionMode, goldenData) %}
    {{ log("start source: " ~ sourcePattern) }}
    {# /* Set the full golden schema, source pattern without the wildcard + golden schema */ #}
    {% set fullGoldenSchema = sourcePattern[:-1] + goldenSchema %}
    {# /* Find all tables for this source across all customers and store in a dictionary */ #}
    {% set allRelations = dbt_utils.get_relations_by_pattern(sourcePattern, tablePattern) %}
    {% set allDict = {} %}
    {% set schemaList = [] %}
    {% for allRelation in allRelations %}
        {% if (allRelation.schema.endswith(goldenSchema) or allRelation.schema in excludeSchemas or allRelation.table in excludeTables) %}
        {% else %}
            {# /* If no entry then default with empty array */ #}
            {% set allRelList = allDict.get(allRelation.table,[]) %}
            {# /* Append function returns 'none' which gets added to the SQL unless assigned to an unused variable */ #}
            {% set x = allRelList.append(allRelation) %}
            {% do allDict.update({allRelation.table: allRelList}) %}
            {# /* Create a list of schemas to verify tables that should exist against dict of relations that do */ #}
            {% if allRelation.schema not in schemaList %}
                {% set y = schemaList.append(allRelation.schema) %}
            {% else %}
            {% endif %}
        {% endif %}
    {% endfor %}

    {# /* Rebuild / Refresh golden tables */ #}
    {% if refreshGolden %}
        {# /* Key is table name, Value is the list of relations */ #}
        {% for tableName, relationsList in allDict.items() %}
            {# /* Check if schema already exists */ #}
            {% if loop.first %}
                {% do adapter.create_schema(api.Relation.create(database=target.database, schema=fullGoldenSchema)) %}
                {{ log("Creating schema : " ~ fullGoldenSchema) }}
            {% endif %}
            {# /* Create the union query by joining all relations for the specific table,
            if goldenData is true then no where clause, so data will be joined,
            if goldenData is false then add where clause which is always false to only take structure and not rows */ #}
            {% if goldenData %}
                {% set unionQuery = dbt_utils.union_relations(relations=relationsList) %}
            {% else %}
                {% set unionQuery = dbt_utils.union_relations(relations=relationsList, source_column_name=none, where="1=0") %}
            {% endif %}

            {# /* Create the golden table based on the superset of columns created above */ #}
            {% set query %}
                    CREATE OR REPLACE TABLE `{{fullGoldenSchema}}.{{tableName}}` AS SELECT * FROM {{unionQuery}};
            {% endset %}
            {% do run_query(query) %}
            {{ log("Running create golden table query: " ~ query)}}
        {% endfor %}
    {% endif %}

    {# /* Find all golden relations that were just created for this table and store in a dict */ #}
    {% set goldenRels = dbt_utils.get_relations_by_pattern(fullGoldenSchema, tablePattern) %}
    {% set goldDict = {} %}
    {% for goldenRelation in goldenRels %}
        {% do goldDict.update({goldenRelation.table: goldenRelation}) %}
    {% endfor %}

    {# /* Iterate over the supserset of every table that should exist for this source */ #}
    {% for tableKey, goldRelation in goldDict.items() %}
        {# /* Retrieve list of relations for this table, which is what exists currently  */ #}
        {% set relationList =  allDict.get(tableKey,[]) %}
        {# /* Iterate over the schema list to fix the delta between what should exist and what does exist */ #}
        {% for customer in schemaList %}
            {% set filteredList = relationList | selectattr("schema", "equalto", customer) | list %}
            {# /* Search the list of tables that do exist for this schema */ #}
            {% if filteredList|length > 0 %}
                {# /* Table exists, validate columns */ #}
                {% set customerRelation = filteredList[0] %}
                {{ validate_columns(customerRelation, goldRelation, excludeColumns, executionMode) }}
            {% else %}
                {# /* Table doesn't exist, create the table using golden customers table structure */ #}
                {% set query %}
                    CREATE TABLE `{{customer}}.{{tableKey}}` AS SELECT * FROM `{{goldRelation.schema}}.{{tableKey}}` limit 1 ;
                {% endset %}
                {% if executionMode %}
                    {% do run_query(query) %}
                    {{ log("Running create table query: " ~ query)}}
                {% else %}
                    {{ log("Would run create table query: " ~ query)}}
                {% endif %}
                {# /* Drop any columns that are excluded */ #}
                {% for col in excludeColumns %}
                    {% set dropQuery %}
                        ALTER TABLE `{{customer}}.{{tableKey}}` DROP COLUMN `{{col}}`;
                    {% endset %}
                    {% if executionMode %}
                        {% do run_query(dropQuery) %}
                        {{ log("Running drop column query: " ~ dropQuery)}}
                    {% else %}
                        {{ log("Would run drop column query: " ~ dropQuery)}}
                    {% endif %}
                {% endfor %}
            {% endif %}
        {% endfor %}
    {% endfor %}
{% endmacro %}