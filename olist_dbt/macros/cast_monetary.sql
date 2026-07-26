{% macro cast_monetary(column_name) %}
    TRY_CAST({{ column_name }} AS DECIMAL(10, 2))
{% endmacro %}