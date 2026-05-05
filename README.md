# Quantitative-Analysis-of-Operational-Risk
This project analyzes 10 years of OpRisk data (964 events) to estimate 99.9% VaR. By applying Extreme Value Theory (EVT) and GPD modeling, it addresses extreme right-skewness and infinite variance. It validates capital requirements via Monte Carlo and Single Loss Approximation, capturing the "low-frequency high-impact" nature of risk
1. Data Summary
You have 964 loss events over 10 years from risk class X.
Statistic	Value	Interpretation
Min	€48.8	Very small losses exist
Max	€52.8M	Catastrophic tail events exist
Mean	€293,920	Heavily pulled up by extremes
Median	€83,384	Typical loss is much smaller than mean
Std Dev	€1.84M	Enormous dispersion
Key insight for your report: The mean is 3.5× larger than the median. In a normal distribution they would be equal. This massive gap is the first signal that the data is severely right-skewed with a heavy tail — a handful of very large losses are dragging the mean upward. This immediately rules out symmetric distributions and justifies using heavy-tailed models.

2. Goodness-of-Fit Tests — Full Sample
All three distributions rejected at p = 0.0000 by both KS and AD tests.
"The Kolmogorov-Smirnov and Anderson-Darling tests reject all three candidate distributions (Lognormal, Weibull, Gamma) at any conventional significance level when fitted to the full sample. This result is not surprising for two reasons. First, with n = 964 observations, both tests have very high statistical power and will detect even minor deviations from the theoretical distribution. Second, and more importantly, operational loss data typically exhibits two distinct behavioral regimes: a body of frequent, moderate losses driven by routine operational events, and a tail of rare, catastrophic losses driven by extreme events. No single parametric distribution can simultaneously capture both regimes adequately. This motivates the adoption of a two-component model: the empirical CDF for the body and a Generalized Pareto Distribution (GPD) for the tail, following the Peaks Over Threshold (POT) methodology from Extreme Value Theory."

3. Threshold Selection
The scan tested thresholds from the 50th to 95th percentile. The 65th percentile (u_I = €142,722) was selected because it produced the highest KS p-value of 0.9993 — meaning the GPD fits the exceedances extremely well above this point.
"The threshold selection was performed by sequentially fitting a GPD to exceedances above candidate thresholds ranging from the 50th to the 95th percentile, evaluating fit quality via the Kolmogorov-Smirnov test at each level. The 65th percentile (u_I = €142,722) yielded the highest p-value of 0.9993, indicating a near-perfect GPD fit to the 337 exceedances above this threshold. This threshold balances two competing requirements: it must be high enough for the GPD approximation to be theoretically valid, yet low enough to retain sufficient tail observations for reliable parameter estimation. With 337 tail observations (35% of the sample), both conditions are satisfied."

4. GPD Tail Fit — The Most Important Result
Parameter	Value	Meaning
Shape ξ (xi)	0.8456	Heavy tail, Pareto-like
Scale σ (sigma)	139,746	Controls spread of exceedances
KS p-value	0.9993	Excellent fit
The shape parameter ξ = 0.8456 is the single most important number in your entire analysis. Here is why:
•	ξ > 0 confirms a heavy-tailed (Pareto-type) distribution
•	ξ = 0.8456 means the distribution has finite mean but infinite variance (since the variance is infinite when ξ > 0.5)
•	It means extreme losses can be astronomically large — there is no natural upper bound
•	The theoretical mean of the GPD tail exists (since ξ < 1) but the variance does not
"The GPD fitted to the 337 exceedances above u_I = €142,722 yields a shape parameter ξ = 0.8456 and scale parameter σ = €139,746, with a KS p-value of 0.9993 confirming an excellent fit. The positive shape parameter confirms that the tail of the loss distribution belongs to the Fréchet domain of attraction — a heavy-tailed regime consistent with Pareto-type behavior. Specifically, ξ = 0.8456 implies that while the mean of the exceedance distribution is finite (requiring ξ < 1), its variance is infinite (ξ > 0.5), reflecting the extreme concentration of risk in the upper tail. This finding has significant implications for risk measurement: standard variance-based risk metrics are theoretically ill-defined for this risk class, and high quantile estimation via Monte Carlo or SLA is essential."

5. Composite CDF
"F_empirical(u_I) = 0.6505 — 65% of mass below threshold"
This means:
•	65% of all losses (the body) are modeled by the empirical CDF — no parametric assumptions needed
•	35% of all losses (the tail) are modeled by the GPD
•	The two pieces are joined seamlessly at u_I using the merging formula from Extreme Value Theory
"The composite severity distribution combines the empirical CDF for losses below u_I = €142,722, which accounts for 65.1% of the probability mass, with the fitted GPD for losses exceeding this threshold. This hybrid approach is theoretically justified: the body is described non-parametrically, making no distributional assumptions about routine losses, while the tail is governed by the GPD, which is the theoretically optimal distribution for exceedances above a high threshold by the Pickands–Balkema–de Haan theorem."

6. Frequency Model
λ = 96.4 events per year modeled as Poisson.

"The annual frequency of loss events is modeled using a Poisson distribution with parameter λ = 96.4, derived from the observed 964 events over 10 years. The Poisson assumption is standard in operational risk modeling under the Loss Distribution Approach (LDA) and implies that events occur independently and at a constant average rate."

7. VaR Results — The Bottom Line
Method	VaR 99.9%
Monte Carlo	€814,160,000
SLA	€789,520,000
SLA Adjusted	€820,310,000
Three critical observations:
Observation 1 — The numbers are enormous relative to typical losses. The median loss is €83,384 but the 99.9% VaR is €814M. This is the hallmark of heavy-tailed operational risk — the worst year in 1,000 years is roughly 10,000× the typical loss. This is driven entirely by ξ = 0.8456.
Observation 2 — SLA and Monte Carlo are very close. The SLA (€789M) and Monte Carlo (€814M) differ by only 3%. The adjusted SLA (€820M) is within 0.7% of Monte Carlo. This is excellent agreement and validates both methods.
Observation 3 — Why they agree so well. With ξ = 0.8456, the tail is genuinely sub-exponential and extremely heavy. This means the worst annual loss is almost entirely dominated by a single catastrophic event, not the accumulation of many losses. The SLA is designed precisely for this scenario, which is why it works so well here.
"The 99.9% Value at Risk of risk class X is estimated at approximately €814M via Monte Carlo simulation (200,000 scenarios) and €790M via the Single Loss Approximation, with the adjusted SLA yielding €820M. The close agreement between the three estimates — within 4% of each other — is a direct consequence of the heavy tail shape parameter ξ = 0.8456. For distributions in the Fréchet domain of attraction with such a high shape parameter, the aggregate annual loss is dominated by a single extreme event rather than the accumulation of many moderate losses. This validates the SLA as an appropriate approximation for this risk class. The magnitude of the VaR — approximately €814M against a median single loss of €83,384 — underscores the extreme tail risk inherent in this operational risk category and the critical importance of heavy-tailed modeling over standard parametric approaches."

Overall Conclusion for Your Report
"The analysis demonstrates that the operational losses of risk class X exhibit a severely heavy-tailed distribution that cannot be adequately captured by standard parametric distributions such as the Lognormal, Weibull, or Gamma. The Peaks Over Threshold approach, combining an empirical body with a GPD tail fitted above the 65th percentile threshold, provides an excellent fit to the data (KS p-value = 0.9993 on the tail). The estimated GPD shape parameter ξ = 0.8456 places the distribution firmly in the heavy-tailed Fréchet domain, with infinite variance and extreme sensitivity to tail events. The resulting 99.9% VaR of approximately €814M, consistently estimated by both Monte Carlo simulation and the Single Loss Approximation, reflects the catastrophic potential of this risk class and highlights the necessity of Extreme Value Theory methods for its proper quantification."
