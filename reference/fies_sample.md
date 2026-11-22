# Synthetic ENAHO Household Sample for FIES and Rasch Training

A lightweight synthetic dataset of 400 stratified households mimicking
the structure and item severity ordering of the Peruvian ENAHO Module
2082 (\`enaho01-\<year\>-130\`, Chapter 130) and Module 34
(\`sumaria-\<year\>-12g\`). Designed both for offline package
examples/tests and as a hands-on training dataset for teaching Food
Insecurity Experience Scale ('FIES') and Rasch psychometric analysis.

## Usage

``` r
fies_sample
```

## Format

A data frame with 400 rows and 23 columns:

- year:

  Survey year (\`2025\`).

- conglome:

  Primary sampling unit identifier.

- vivienda:

  Dwelling identifier.

- hogar:

  Household identifier.

- ubigeo:

  Six-digit geographic code.

- dominio:

  Geographic domain (\`1\`–\`8\`).

- estrato:

  Sampling stratum (\`1\`–\`8\`, where \`6\`–\`8\` are rural).

- factor07:

  Household annual sampling weight.

- mieperho:

  Number of household members.

- pobreza:

  Monetary poverty code (\`1\` = Extreme poor, \`2\` = Non-extreme poor,
  \`3\` = Non-poor).

- pobrezav:

  Vulnerability code (\`1\`–\`4\`).

- gashog2d:

  Annual gross household expenditure (PEN).

- inghog2d:

  Annual net household income (PEN).

- p130_1:

  \`WORRIED\`: Worried about not having enough food (\`1\` = Yes, \`2\`
  = No).

- p130_2:

  \`HEALTHY\`: Unable to eat healthy and nutritious food (\`1\` = Yes,
  \`2\` = No).

- p130_3:

  \`FEWFOOD\`: Ate only a few kinds of foods (\`1\` = Yes, \`2\` = No).

- p130_4:

  \`SKIPPED\`: Had to skip a meal (\`1\` = Yes, \`2\` = No).

- p130_5:

  \`ATELESS\`: Ate less than normal (\`1\` = Yes, \`2\` = No; global
  threshold for Moderate or Severe).

- p130_6:

  \`RUNOUT\`: Household ran out of food (\`1\` = Yes, \`2\` = No).

- p130_7:

  \`HUNGRY\`: Felt hungry but did not eat (\`1\` = Yes, \`2\` = No).

- p130_8:

  \`WHLDAY\`: Went without eating for a whole day (\`1\` = Yes, \`2\` =
  No; global threshold for Severe).

- has_child_u5:

  Indicator (\`0\`/\`1\`) for presence of children under 5 years.

- has_disability:

  Indicator (\`0\`/\`1\`) for presence of a member with permanent
  disability.

## Source

Simulated Rasch item responses calibrated to the FAO FIES global scale.

## See also

\[fies_items()\] for the verbatim Spanish and English wording of all
eight items.
