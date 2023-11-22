# [Full Documentation Here]([url](https://community.fivetran.com/t5/user-group-for-dbt/dynamically-enforcing-a-unified-schema-across-many-schemas/m-p/1326/)) #

## Adding a New Source to Source Validation ##

Add a new model to the models folder, by duplicating an existing source model, and modifying the control variables to match what is required for the new model. 
1. Duplicate an existing source model in the 'models' folder.
2. Modify the control variables to match the requirements of the new data source.

**Note:** We split each source into its own model because dbt will multi-thread the models, reducing validation process time.

The naming structure for these models could be ‘**validate_source.sql**‘ and they should be located in the models folder of your DBT project, as below.

<img width="515" alt="image" src="https://github.com/fivetran-jackmccormack/validate_source/assets/100202682/8ea73ea4-7210-409c-9bc5-b366e754b37a">

You must also add the new model into the ‘schema.yml’ file with the following structure;

Add the new model to the '**schema.yml**' file with the following structure:

```yml
version: 2
models:
  - name: validate_facebook
    description: "Model to validate Facebook source tables"
    columns:
      - name: table_name
        description: "The primary key for this table"
    tests:
      - unique
  - name: validate_<SOURCE>
    description: "Model to validate <SOURCE> source tables"
    columns:
      - name: table_name
        description: "The primary key for this table"
    tests:
      - unique
```
## Altering Macro Control Variables ##

### Golden Schema ###
This is the suffix for the schema that the golden tables will be created in, i.e. with tiktok as the source, and the below sample golden schema, the schema would end up being ‘tiktok_ads_ft_golden’

_Sample Golden Schema_
```sql
{% set goldenSchema = 'ft_golden' %}
 ```

### Table Pattern ###
This is the pattern that will be used to detect tables inside of the schemas that are being checked, by default we would use ‘%’ to add all tables.

_Sample Table Pattern_
```sql
{% set tablePattern = '%' %}
```

### Source Pattern ###
This is the pattern that will be used to dynamically detect schemas that match the source type we wish to verify. 
The logic for determining what pattern you wish to use is defined here.

_Sample Source Patterns_
```sql
{% set sourceType ='facebook_ads_%' %}
{% set sourceType ='google_ads_%' %}
{% set sourceType ='tiktok_ads_%' %}
{% set sourceType ='shopify_%' %}
{% set sourceType = 'instagram_ads_%' %}
{% set sourceType = '_____shopify_%' %}
```

### Exclude Schemas ###
These are schemas you specifically wish to exclude, sometimes you have specific customers, or schemas that match the pattern that you do not wish to include in the validation process.

_Sample Exclude Schema List_
```sql
{% set excludeSchemas = ["shopify_scraped","shopify_orgnametest"] %}
```

**Note:** It is very important to exclude any schemas that match the schema pattern that do not actually match the overall structure of the rest of the tables, as the macro will dynamically pick up all the tables within this schema and add them to every other schema.
If this happens, you can exclude the schema, delete the relevant golden tables and set the ‘Refresh Golden’ value to true for a single run, in order to re-create the golden tables without these unwanted tables, and then reset it to false.

### Exclude Tables ###
These are tables you specifically wish to exclude, sometimes you have specific tables that match the pattern that you use that you do not wish to include in the validation process.
We suggest that you always exclude the “fivetran_audit” table, and then define other exclusions on a source by source basis.

_Sample Exclude Table List_
```sql
{% set excludeTables = ["fivetran_audit"] %}
```

### Exclude Columns ###
These are columns you specifically wish to exclude, sometimes you have specific columns that you do not wish to include in the validation process.
When using goldenData as true we suggest that you always exclude the “_dbt_source_relation” column, and then define other exclusions on a source by source basis.

_Sample Exclude Column List_
```sql
{% set excludeColumns = ["_dbt_source_relation"] %}
```

### Refresh Golden ###
The process of unioning all tables for each source type and customer can take a little while, and it only actually needs to be run the first time, or whenever you modify your downstream models and need to add in a new value to your source validation that wasn’t previously validated.
Whenever this occurs you will need to drop the relevant source_ft_golden tables and set this flag to true for a single run, to perform a full refresh of the golden tables for this source, and then reset it to false to save on execution time for future model runs.

_Sample Refresh Golden Values_
```sql
{% set refreshGolden = false %}
{% set refreshGolden = true %}
```

### Execution Mode ###
Because the macro is dynamically picking up tables and schemas, we suggest testing the MVP with the execution mode set to false, and analyzing the logs to see what queries it ‘would have run’. 
When you set the execution mode to true, it will automatically generate and execute the queries to create and alter missing source tables and columns.

_Sample Execution Mode Values_
```sql
{% set executionMode = false %}
{% set executionMode = true %}
```
**Note:** Even with Execution Mode as false, the Golden tables will still be created as they need to be generated in order to test the rest of the functionality. However, no changes will be made to the source tables, or any other tables.

### Golden Data ###
This is a macro that controls whether the union_relations macro will take the data and the structure from the source tables, or just take the structure.
Note: If you do not have a use-case for having the data from all source tables joined together, then we would definitely suggest setting this value to false, as it will improve execution time and remove this unnecessary compute from being ran in your warehouse.
False means no data will be joined, True means data will be joined.

_Sample Golden Data Values_
```sql
{% set goldenData = false %}
{% set goldenData = true %}
```
