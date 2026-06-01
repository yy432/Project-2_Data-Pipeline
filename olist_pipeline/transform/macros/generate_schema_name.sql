-- macros/generate_schema_name.sql
-- Respects the custom schema suffix per environment, so staging models land
-- in <target_dataset>_staging and marts land in <target_dataset>_marts.

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
