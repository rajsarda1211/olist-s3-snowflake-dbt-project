{% test column_length(model, column_name, length) %}

SELECT *
FROM {{ model }}
WHERE LENGTH({{ column_name }}) != {{ length }}

{% endtest %}