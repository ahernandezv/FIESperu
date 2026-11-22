# Synthetic ENAHO Household Sample for FIES Demonstration and Testing

A lightweight synthetic dataset of 400 stratified households mimicking
the structure and item severity ordering of the Peruvian ENAHO Module
2082 (\`enaho01-2025-130\`) and Module 34 (\`sumaria-2025-12g\`).
Provided so examples, vignettes, and unit tests run offline in under a
second without contacting INEI servers.

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

- p130_1, p130_2, p130_3, p130_4, p130_5, p130_6, p130_7, p130_8:

  Eight FIES items coded \`1\` = Yes, \`2\` = No.

- has_child_u5:

  Indicator (\`0\`/\`1\`) for presence of children under 5 years.

- has_disability:

  Indicator (\`0\`/\`1\`) for presence of a member with permanent
  disability.

## Source

Simulated Rasch item responses calibrated to the FAO FIES global scale.
