#' Analyze stanreg objects.
#'
#' Analyze stanreg objects.
#'
#' @param x stanreg object.
#' @param CI Credible interval bounds.
#' @param MEDP_step The step used for computing Maximum Effect Direction Probability.
#' @param MEDP_min The lower bound of MEDP (the minimum effect).
#' @param ... Arguments passed to or from other methods.
#'
#' @return output
#'
#' @examples
#' library(psycho)
#' require(rstanarm)
#' fit <- rstanarm::stan_glm(vs ~ mpg * cyl,
#'   data=mtcars,
#'   family = binomial(link = "logit"),
#'   prior=NULL)
#'
#'  analyze(fit)
#'
#' @author Dominique Makowski, \url{https://dominiquemakowski.github.io/}
#'
#' @import rstanarm
#' @import tidyr
#' @import dplyr
#' @import ggplot2
#' @importFrom stats quantile
#' @export
analyze.stanreg <- function(x, CI=95, MEDP_step=0.05, MEDP_min=0.001, ...) {

  # Processing
  # -------------
  fit <- x

  # Extract posterior distributions
  posteriors <- as.data.frame(fit)

  # Initialize empty values
  values <- list()
  # Loop over all variables
  for (varname in names(posteriors)){

    # Extract posterior
    posterior <- posteriors[, varname]

    # Find basic posterior indices
    median=median(posterior)
    mad=mad(posterior)
    mean <- mean(posterior)
    sd <- sd(posterior)
    CI_values <- quantile(posterior, c((100-CI)/2/100, 1-(100-CI)/2/100))

    # Compute MEDP
    for (MEDP in seq(0, 100, by = MEDP_step)){
      MEDP_values <- 100-MEDP
      MEDP_values <- quantile(posterior, c(0+MEDP_values/2/100, 1-MEDP_values/2/100))

      if (median >= 0){
        if (MEDP_values[1] <= MEDP_min){
          break
        }
      } else {
        if (MEDP_values[2] >= -MEDP_min){
          break
        }
      }
    }

    # Create text
    if (grepl(":", varname)){
      splitted <- strsplit(varname, ":")[[1]]
      if (length(splitted)==2){
        name <- paste("interaction effect between ", splitted[1], " and ", splitted[2], sep="")
      } else{
          name <- varname
        }
      } else{
        name <- paste("effect of ", varname, sep="")
    }

    text <- paste("Concerning the ", name, ", there is a probability of ", format_digit(MEDP), "% that its coefficient is between ", format_digit(MEDP_values[1]), " and ", format_digit(MEDP_values[2]), " (Median = ", format_digit(median), ", MAD = ", format_digit(mad), ", Mean = ", format_digit(mean), ", SD = ", format_digit(sd), ", ", CI, "% CI [", format_digit(CI_values[1]), ", ", format_digit(CI_values[2]), "]).", sep="")

    # Store all that
    values[[varname]] <- list(median=median,
                              mad=mad,
                              mean=mean,
                              sd=sd,
                              CI_values=CI_values,
                              MEDP=MEDP,
                              MEDP_values=MEDP_values,
                              posterior=posterior,
                              text=text)



  }


  # Effect size
  # -------------
  # if (standardized==T){
  #   print("Interpreting effect size following Cohen (1988)... Make sure your variables were scaled and centered!")
  #
  #   # http://www.polyu.edu.hk/mm/effectsizefaqs/thresholds_for_interpreting_effect_sizes2.html
  #   # Compute the probabilities
  #
  #   verylarge_neg <- length(posterior[posterior <= -1.30])/length(posterior)
  #   large_neg <- length(posterior[posterior > -1.30 & posterior <= -0.80])/length(posterior)
  #   medium_neg <- length(posterior[posterior > -0.80 & posterior <= -0.50])/length(posterior)
  #   small_neg <- length(posterior[posterior > -0.50 & posterior <= -0.20])/length(posterior)
  #   verysmall_neg <- length(posterior[posterior > -0.20 & posterior < 0])/length(posterior)
  #
  #   verylarge_pos <- length(posterior[posterior >= 1.30])/length(posterior)
  #   large_pos <- length(posterior[posterior < 1.30 & posterior >= 0.80])/length(posterior)
  #   medium_pos <- length(posterior[posterior < 0.80 & posterior >= 0.50])/length(posterior)
  #   small_pos <- length(posterior[posterior < 0.50 & posterior >= 0.20])/length(posterior)
  #   verysmall_pos <- length(posterior[posterior < 0.20 & posterior > 0])/length(posterior)
  #
  #
  #
  #   effect_size <- data.frame(Direction=c("Negative", "Negative", "Negative", "Negative", "Negative", "Positive", "Positive", "Positive", "Positive", "Positive"),
  #                             Size=c("VeryLarge", "Large", "Medium", "Small", "VerySmall", "VerySmall", "Small", "Medium", "Large", "VeryLarge"),
  #                             Probability=c(verylarge_neg, large_neg, medium_neg, small_neg, verysmall_neg, verysmall_pos, small_pos, medium_pos, large_pos, verylarge_pos))
  #   effect_size$Probability[is.na(effect_size$Probability)] <- 0
  #
  #   if(mean >= 0){
  #     opposite_prob <- sum(effect_size$Probability[effect_size$Direction=="Negative"])
  #     opposite_max <- min(posterior[posterior < 0])
  #     print(paste("Based on Cohen (1988) recommandations, there is a probability of ", round(verylarge_pos*100, 2), " that this effect size is very large, ", round(large_pos*100, 2), "% that this effect size is large, ", round(medium_pos*100, 2), "% that this effect size is medium, ", round(small_pos*100, 2), "% that this effect size is small, ", round(verysmall_pos*100, 2), "% that this effect is very small and ", round(opposite_prob*100, 2), "% that it has an opposite direction (between 0 and ", signif(opposite_max, 2), ").", sep=""))
  #   } else{
  #     opposite_prob <- sum(effect_size$Probability[effect_size$Direction=="Positive"])
  #     opposite_max <- max(posterior[posterior > 0])
  #     print(paste("Based on Cohen (1988) recommandations, there is a probability of ", round(verylarge_neg*100, 2), " that this effect size is very large, ", round(large_neg*100, 2), "% that this effect size is large, ", round(medium_neg*100, 2), "% that this effect size is medium, ", round(small_neg*100, 2), "% that this effect size is small, ", round(verysmall_neg*100, 2), "% that this effect is very small and ", round(opposite_prob*100, 2), "% that it has an opposite direction (between 0 and ", signif(opposite_max, 2), ").", sep=""))
  #   }
  #   return(effect_size)
  #
  # }



  # Summary
  # -------------
  MEDPs <- c()
  for (varname in names(values)){
    MEDPs <- c(MEDPs, values[[varname]]$MEDP)
  }
  medians <- c()
  for (varname in names(values)){
    medians <- c(medians, values[[varname]]$median)
  }
  mads <- c()
  for (varname in names(values)){
    mads <- c(mads, values[[varname]]$mad)
  }
  means <- c()
  for (varname in names(values)){
    means <- c(means, values[[varname]]$mean)
  }
  sds <- c()
  for (varname in names(values)){
    sds <- c(sds, values[[varname]]$sd)
  }
  CIs <- c()
  for (varname in names(values)){
    CIs <- c(CIs, values[[varname]]$CI_values)
  }
  summary <- data.frame(Variable=names(values), MEDP=MEDPs, Median=medians, MAD=mads, Mean=means, SD=sds, CI_lower=CIs[seq(1, length(CIs), 2)], CI_higher=CIs[seq(2, length(CIs), 2)])




  # Text
  # -------------
  # Model
  info <- paste("We fitted a Markov Chain Monte Carlo [type] model to predict [Y] with [X] (formula =", deparse(fit$formula), "). Priors were set as follow: [INSERT INFO ABOUT PRIORS].", sep="")

  # Coefs
  coefs_text <- c()
  for (varname in names(values)){
    coefs_text <- c(coefs_text, values[[varname]]$text)
  }
  text <- c(info, coefs_text)

  # Plot
  # -------------
  plot <- posteriors %>%
    # select(-`(Intercept)`) %>%
    gather() %>%
    rename_(Variable="key", Coefficient="value") %>%
    ggplot(aes_string(x="Variable", y="Coefficient", fill="Variable")) +
    geom_violin() +
    geom_boxplot(fill="grey", alpha=0.3, outlier.shape=NA) +
    stat_summary(fun.y = mean, geom = "errorbar", aes_string(ymax = "..y..", ymin = "..y.."), width = .75, linetype = "dashed", colour="red") +
    geom_hline(aes(yintercept=0)) +
    theme_classic() +
    coord_flip() +
    scale_fill_brewer(palette="Set1") +
    scale_colour_brewer(palette="Set1")


  output <- list(text=text, plot=plot, summary=summary, values=values)

  class(output) <- c("psychobject", "list")
  return(output)
}