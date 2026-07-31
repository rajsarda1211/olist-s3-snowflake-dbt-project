{% macro metadata_join(base_table, base_alias) %}

    {% set query %}
        SELECT table_name, join_key, join_type, alias, source_alias, extra_excludes
        FROM {{ ref('obt_join_config') }}
    {% endset %}

    {% set results = run_query(query) %}

    {% if execute %}
        {% set join_configs = results.rows %}
    {% else %}
        {% set join_configs = [] %}
    {% endif %}

    SELECT
        {{ base_alias }}.*
        {% for row in join_configs %}
            , {{ row['ALIAS'] }}.* EXCLUDE ({{ row['JOIN_KEY'] }}{% if row['EXTRA_EXCLUDES'] %}, {{ row['EXTRA_EXCLUDES'] }}{% endif %})
        {% endfor %}
    FROM {{ ref(base_table) }} {{ base_alias }}
    {% for row in join_configs %}
        {{ row['JOIN_TYPE'] }} JOIN {{ ref(row['TABLE_NAME']) }} {{ row['ALIAS'] }}
            ON {{ row['SOURCE_ALIAS'] }}.{{ row['JOIN_KEY'] }} = {{ row['ALIAS'] }}.{{ row['JOIN_KEY'] }}
    {% endfor %}

{% endmacro %}