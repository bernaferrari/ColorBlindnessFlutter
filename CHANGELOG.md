## [0.3.0]

* Require Flutter 3.50+ / Dart 3.14+ and standalone `material_ui` types.
* Preserve floating-point channel precision, `ColorSpace`, and alpha in color blindness simulation.
* Add `simulateColorBlindness` extensions on `Color` and `ColorScheme`, plus `label` and `shortDescription` metadata on `ColorBlindnessType`.
* Add `colorContrastRatio`, `ContrastCheckIssue`, and `colorBlindnessContrastIssues` alongside `colorBlindnessAssertContrast` across all 45 Material 3 roles.
* Redesign the example app as a side-by-side Original vs Simulated Material 3 showcase with interactive contrast auditing and Dart export (removing `hsluv`).

## [0.2.0] - 10/05/2024

* Update constraints to Flutter 3.22.
* Support new ColorScheme colors.

## [0.1.2] - 03/03/2023

* Update constraints to Flutter 2.19.

## [0.1.1] - 12/05/2022

* Add support for M3 Color Scheme (Flutter 3).

## [0.1.0] - 23/02/2021

* Add null safety.

## [0.0.1] - 04/10/2020

* Initial release.
