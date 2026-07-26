{% macro clean_string(column_name) %}
    LOWER(TRIM({{ column_name }}))
{% endmacro %}