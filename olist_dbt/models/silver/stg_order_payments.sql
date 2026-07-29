{{ config(
    unique_key=['order_id', 'payment_sequential']
) }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_order_payments') }}
),

cleaned AS (
    SELECT
        order_id,
        TRY_CAST(payment_sequential AS INT)   AS payment_sequential,
        payment_type,
        TRY_CAST(payment_installments AS INT) AS payment_installments,
        {{ cast_monetary('payment_value') }}  AS payment_value,
        _source_file,
        _loaded_at,
        _row_hash
    FROM source
    WHERE order_id IS NOT NULL
      AND payment_sequential IS NOT NULL

    {% if is_incremental() %}
        AND _loaded_at > (
            SELECT DATEADD(day, -3, MAX(_loaded_at))
            FROM {{ this }}
        )
    {% endif %}
)

SELECT * FROM cleaned