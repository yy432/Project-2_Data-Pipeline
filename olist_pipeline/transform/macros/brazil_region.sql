-- macros/brazil_region.sql
-- Usage: {{ brazil_region('column_name') }}
-- Returns a CASE expression mapping Brazilian state codes to regions.

{% macro brazil_region(state_col) %}
    case {{ state_col }}
        when 'SP' then 'Southeast' when 'RJ' then 'Southeast'
        when 'MG' then 'Southeast' when 'ES' then 'Southeast'
        when 'RS' then 'South'     when 'SC' then 'South'    when 'PR' then 'South'
        when 'BA' then 'Northeast' when 'PE' then 'Northeast'
        when 'CE' then 'Northeast' when 'MA' then 'Northeast'
        when 'PB' then 'Northeast' when 'RN' then 'Northeast'
        when 'AL' then 'Northeast' when 'SE' then 'Northeast'
        when 'PI' then 'Northeast'
        when 'GO' then 'Central-West' when 'MT' then 'Central-West'
        when 'MS' then 'Central-West' when 'DF' then 'Central-West'
        when 'AM' then 'North'     when 'PA' then 'North'
        when 'RO' then 'North'     when 'AC' then 'North'
        when 'AP' then 'North'     when 'RR' then 'North'
        when 'TO' then 'North'
        else 'Unknown'
    end
{% endmacro %}
