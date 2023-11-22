{% macro validate_columns(relation, goldenRelation, excludeColumns ,executionMode) %}
    {# /* Check if table already exists */ #}
    {% if relation and execute %}
        {# /* Check if columns match */ #}
        {% set columns = adapter.get_columns_in_relation(relation) %}
        {% set goldenColumns = adapter.get_columns_in_relation(goldenRelation) %}   

        {# /* alter table to add missing columns */ #}
        {% for col in adapter.get_missing_columns(goldenRelation, relation) %}
            {% if col not in excludeColumns %}
                {% set query %}
                    ALTER TABLE `{{relation.schema}}.{{relation.table}}` add column `{{col.name}}` {{col.data_type}};
                {% endset %}
                {% if executionMode %}
                    {% do run_query(query) %}
                    {{ log("Running alter table query: " ~ query)}}
                {% else %}
                    {{ log("Would run alter table query: " ~ query)}}
                {% endif %}
            {% endif %}
        {% endfor %}
    {% endif %}
{% endmacro %}
