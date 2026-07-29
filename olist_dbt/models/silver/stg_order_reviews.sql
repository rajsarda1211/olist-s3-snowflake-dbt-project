{{ config(
    unique_key=['review_id', 'order_id']
) }}

WITH source AS (
    SELECT * FROM {{ source('bronze', 'raw_order_reviews') }}
),

cleaned AS (
    SELECT
        review_id,
        order_id,
        TRY_CAST(review_score AS INT)                      AS review_score,
        COALESCE(review_comment_title, '')                 AS review_comment_title,
        COALESCE(review_comment_message, '')               AS review_comment_message,
        TRY_CAST(review_creation_date AS TIMESTAMP_NTZ)    AS review_creation_date,
        TRY_CAST(review_answer_timestamp AS TIMESTAMP_NTZ) AS review_answer_timestamp,
        _source_file,
        _loaded_at,
        _row_hash
    FROM source
    WHERE review_id IS NOT NULL
      AND order_id IS NOT NULL

    {% if is_incremental() %}
        AND _loaded_at > (
            SELECT DATEADD(day, -3, MAX(_loaded_at))
            FROM {{ this }}
        )
    {% endif %}
),

deduplicated AS (
    SELECT *
    FROM cleaned
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY review_id, order_id
        ORDER BY review_creation_date DESC, _loaded_at DESC
    ) = 1
)

SELECT * FROM deduplicated