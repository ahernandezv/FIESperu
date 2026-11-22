#' Plot Food Insecurity Prevalences and Rasch Psychometric Diagnostics
#'
#' Creates publication-ready visualizations of FIES prevalence estimates (with
#' 95% confidence intervals) or psychometric Rasch validation diagnostics
#' (`"equating"`, `"items"`, `"scree"`). Uses `ggplot2` when installed and
#' falls back gracefully to base R graphics otherwise.
#'
#' @param x Either a prevalence table returned by [estimate_fies()], a
#'   household `fies_tbl` returned by [prepare_fies()], or a `"fies_validation"`
#'   object returned by [validate_rasch()].
#' @param type Type of plot to produce:
#'   * `"prevalence"`: Forest/point-interval plot of prevalence estimates and
#'     confidence intervals (default when `x` comes from [estimate_fies()]).
#'   * `"equating"`: Calibration scatter plot comparing Peru's item severities
#'     against the rescaled FAO FIES Global Standard (`adj_global_st`).
#'   * `"items"`: Item Infit statistics with the acceptable `[0.7, 1.3]` Rasch
#'     fit band.
#'   * `"scree"`: Scree plot of residual principal component eigenvalues to
#'     assess unidimensionality.
#' @param indicator For `type = "prevalence"`, filters `"Moderate or Severe"`
#'   (`"mod_sev"`, default) or `"Severe"` (`"sev"`).
#' @param group Optional character string filtering a specific `group` column
#'   value in prevalence plots (e.g., `"region_inei"` or `"department"`).
#' @param year Optional integer year to plot (defaults to the most recent year).
#' @param ... Additional arguments (currently unused).
#'
#' @returns A `ggplot` object if `ggplot2` is installed, or invisibly `NULL`
#'   when rendered via base R graphics.
#' @export
#'
#' @examples
#' df_demo <- prepare_fies(sample_data = fies_sample, quiet = TRUE)
#' est <- estimate_fies(df_demo, by = "area")
#' plot_fies(est, type = "prevalence")
#' plot_fies(df_demo, type = "equating")
plot_fies <- function(x,
                      type = c("prevalence", "equating", "items", "scree"),
                      indicator = c("mod_sev", "sev"),
                      group = NULL,
                      year = NULL,
                      ...) {
  if (missing(type)) {
    type <- if (inherits(x, "fies_validation") || inherits(x, "fies_tbl")) {
      "equating"
    } else {
      "prevalence"
    }
  } else {
    type <- match.arg(type)
  }
  indicator <- match.arg(indicator)
  use_gg <- requireNamespace("ggplot2", quietly = TRUE)
  if (use_gg) .data <- ggplot2::.data

  if (type == "prevalence") {
    if (inherits(x, "fies_tbl")) {
      x <- estimate_fies(x, by = if (is.null(group)) "area" else group)
    }
    ind_target <- if (indicator == "mod_sev") "Moderate or Severe" else "Severe"
    df_p <- x[x$indicator == ind_target, , drop = FALSE]
    if (!is.null(year)) df_p <- df_p[df_p$year %in% as.integer(year), , drop = FALSE]
    if (!is.null(group)) {
      df_p <- df_p[df_p$group %in% group, , drop = FALSE]
    } else if (length(unique(df_p$group)) > 1L) {
      non_nat <- setdiff(unique(df_p$group), "National")
      df_p <- df_p[df_p$group == non_nat[1L], , drop = FALSE]
    }
    df_p <- df_p[order(df_p$estimate), , drop = FALSE]
    df_p$category <- factor(df_p$category, levels = unique(df_p$category))

    if (use_gg) {
      p <- ggplot2::ggplot(
        df_p,
        ggplot2::aes(x = .data$estimate, y = .data$category)
      ) +
        ggplot2::geom_errorbarh(
          ggplot2::aes(xmin = .data$lower, xmax = .data$upper),
          height = 0.25, color = "#2b5c8f"
        ) +
        ggplot2::geom_point(size = 2.6, color = "#b22222") +
        ggplot2::labs(
          title = paste0("Food Insecurity Prevalence (", ind_target, ")"),
          subtitle = paste0("Peru ENAHO ", paste(unique(df_p$year), collapse = ", "),
                            " - 95% CI (Sampling + Rasch Error)"),
          x = "Prevalence (%)",
          y = NULL
        ) +
        ggplot2::theme_minimal(base_size = 11)
      return(p)
    } else {
      graphics::dotchart(df_p$estimate, labels = as.character(df_p$category),
                         xlab = "Prevalence", main = paste("FIES -", ind_target))
      return(invisible(NULL))
    }
  }

  # Psychometric plots require fies_validation
  val <- if (inherits(x, "fies_validation")) x else validate_rasch(x, year = year)
  yr_use <- if (is.null(year)) max(val$summary$year) else as.integer(year[1L])
  it_df <- val$items[val$items$year == yr_use, , drop = FALSE]
  mod_m <- val$models[[as.character(yr_use)]]

  if (type == "equating") {
    if (use_gg) {
      p <- ggplot2::ggplot(
        it_df,
        ggplot2::aes(x = .data$adj_global_st, y = .data$severity_b, label = .data$item_code)
      ) +
        ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "grey50") +
        ggplot2::geom_point(size = 3, color = "#1f77b4") +
        ggplot2::geom_text(vjust = -0.8, size = 3.2) +
        ggplot2::labs(
          title = paste0("FIES Scale Equating: Peru ENAHO ", yr_use, " vs. FAO Global Standard"),
          subtitle = sprintf("Correlation r = %.4f", mod_m$cor_global),
          x = "Adjusted FAO FIES Global Scale",
          y = paste0("Peru ENAHO ", yr_use, " Item Severity (logits)")
        ) +
        ggplot2::theme_minimal(base_size = 11)
      return(p)
    } else {
      graphics::plot(it_df$adj_global_st, it_df$severity_b, pch = 16, col = "blue",
                     xlab = "FIES global scale (adj)", ylab = paste("Peru", yr_use))
      graphics::abline(0, 1, lty = 2)
      graphics::text(it_df$adj_global_st, it_df$severity_b, labels = it_df$item_code, pos = 3, cex = 0.75)
      return(invisible(NULL))
    }
  }

  if (type == "items") {
    it_df$item_code <- factor(it_df$item_code, levels = it_df$item_code[order(it_df$severity_b)])
    if (use_gg) {
      p <- ggplot2::ggplot(
        it_df,
        ggplot2::aes(x = .data$infit, y = .data$item_code)
      ) +
        ggplot2::geom_vline(xintercept = c(0.7, 1.3), linetype = "dashed", color = "#d95f02") +
        ggplot2::geom_vline(xintercept = 1.0, linetype = "dotted", color = "grey50") +
        ggplot2::geom_point(size = 3, color = "#1b9e77") +
        ggplot2::labs(
          title = paste0("Rasch Item Infit Statistics (ENAHO ", yr_use, ")"),
          subtitle = "Reference acceptable fit range: [0.7, 1.3]",
          x = "Infit Mean-Square",
          y = "FIES Item (ordered by severity)"
        ) +
        ggplot2::theme_minimal(base_size = 11)
      return(p)
    } else {
      graphics::dotchart(it_df$infit, labels = as.character(it_df$item_code),
                         xlab = "Infit", main = paste("Rasch Item Infit -", yr_use))
      graphics::abline(v = c(0.7, 1.3), lty = 2, col = "red")
      return(invisible(NULL))
    }
  }

  if (type == "scree") {
    sc_df <- data.frame(component = seq_along(mod_m$eigenvalues),
                        eigenvalue = mod_m$eigenvalues)
    if (use_gg) {
      p <- ggplot2::ggplot(
        sc_df,
        ggplot2::aes(x = .data$component, y = .data$eigenvalue)
      ) +
        ggplot2::geom_line(color = "#2b5c8f", linewidth = 0.8) +
        ggplot2::geom_point(size = 2.8, color = "#2b5c8f") +
        ggplot2::scale_x_continuous(breaks = sc_df$component) +
        ggplot2::labs(
          title = paste0("Residual PCA Scree Plot (ENAHO ", yr_use, ")"),
          subtitle = "Unidimensionality check on Rasch standardized residuals",
          x = "Principal Component",
          y = "Eigenvalue (Variance)"
        ) +
        ggplot2::theme_minimal(base_size = 11)
      return(p)
    } else {
      graphics::plot(sc_df$component, sc_df$eigenvalue, type = "b", pch = 16,
                     xlab = "Component", ylab = "Eigenvalue",
                     main = paste("Residual PCA Scree Plot -", yr_use))
      return(invisible(NULL))
    }
  }
}
