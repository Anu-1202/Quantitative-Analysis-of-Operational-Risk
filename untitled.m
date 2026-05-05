clear; clc; close all;
dataTable = readtable("C:\Users\91955\Desktop\dataset_exam.xlsx");
data = dataTable.Loss;
data = data(~isnan(data));
data = data(data > 0);

% Basic stats
n = length(data);
minVal = min(data);
maxVal = max(data);
meanVal = mean(data);
medianVal = median(data);
stdVal = std(data);

disp('Basic statistics:');
disp(table(n, minVal, maxVal, meanVal, medianVal, stdVal));

% Histogram
figure;
histogram(data, 50);
title('Histogram of Loss Data');
xlabel('Loss');
ylabel('Frequency');
grid on;

% Log-histogram
figure;
histogram(log(data), 50);
title('Histogram of Log(Loss)');
xlabel('log(Loss)');
ylabel('Frequency');
grid on;

% Empirical CDF
[f,x] = ecdf(data);

figure;
plot(x,f,'LineWidth',1.5);
title('Empirical CDF of Loss Data');
xlabel('Loss');
ylabel('F(x)');
grid on;

figure;
semilogx(x,f,'LineWidth',1.5);
title('Empirical CDF of Loss Data (log scale)');
xlabel('Loss (log scale)');
ylabel('F(x)');
grid on;

% Fit candidate distributions
pd_logn  = fitdist(data,'Lognormal');
pd_weib  = fitdist(data,'Weibull');
pd_gamma = fitdist(data,'Gamma');

xgrid = linspace(min(data), max(data), 2000);

cdf_logn  = cdf(pd_logn, xgrid);
cdf_weib  = cdf(pd_weib, xgrid);
cdf_gamma = cdf(pd_gamma, xgrid);

figure;
plot(x, f, 'k', 'LineWidth', 2); hold on;
plot(xgrid, cdf_logn,  'r--', 'LineWidth', 1.5);
plot(xgrid, cdf_weib,  'b-.', 'LineWidth', 1.5);
plot(xgrid, cdf_gamma, 'g:', 'LineWidth', 1.5);
legend('Empirical CDF','Lognormal','Weibull','Gamma','Location','best');
title('Empirical vs Fitted CDFs');
xlabel('Loss');
ylabel('CDF');
grid on;

figure;
semilogx(x, f, 'k', 'LineWidth', 2); hold on;
semilogx(xgrid, cdf_logn,  'r--', 'LineWidth', 1.5);
semilogx(xgrid, cdf_weib,  'b-.', 'LineWidth', 1.5);
semilogx(xgrid, cdf_gamma, 'g:', 'LineWidth', 1.5);
legend('Empirical CDF','Lognormal','Weibull','Gamma','Location','best');
title('Empirical vs Fitted CDFs (log scale)');
xlabel('Loss (log scale)');
ylabel('CDF');
grid on;

% QQ / probability plots
figure;
qqplot(log(data));
title('QQ Plot of log(Loss)');
grid on;

figure;
probplot('lognormal', data);
title('Lognormal Probability Plot');
grid on;

%%
fprintf('\n=== GOODNESS-OF-FIT TESTS (full sample) ===\n');
fprintf('%-12s  %-25s  %-25s\n', 'Distribution', 'KS (p-val / reject)', 'AD (p-val / reject)');

[h_ks_logn,  p_ks_logn]  = kstest(data, 'CDF', pd_logn);
[h_ks_weib,  p_ks_weib]  = kstest(data, 'CDF', pd_weib);
[h_ks_gamma, p_ks_gamma] = kstest(data, 'CDF', pd_gamma);

[h_ad_logn,  p_ad_logn]  = adtest(data, 'Distribution', pd_logn);
[h_ad_weib,  p_ad_weib]  = adtest(data, 'Distribution', pd_weib);
[h_ad_gamma, p_ad_gamma] = adtest(data, 'Distribution', pd_gamma);

fprintf('%-12s  p=%.4f (reject=%d)       p=%.4f (reject=%d)\n', ...
    'Lognormal', p_ks_logn,  h_ks_logn,  p_ad_logn,  h_ad_logn);
fprintf('%-12s  p=%.4f (reject=%d)       p=%.4f (reject=%d)\n', ...
    'Weibull',   p_ks_weib,  h_ks_weib,  p_ad_weib,  h_ad_weib);
fprintf('%-12s  p=%.4f (reject=%d)       p=%.4f (reject=%d)\n', ...
    'Gamma',     p_ks_gamma, h_ks_gamma, p_ad_gamma, h_ad_gamma);


%%
pctiles    = 50:5:95;
thresholds = prctile(data, pctiles);
pvals_gpd  = nan(size(thresholds));
n_tail     = zeros(size(thresholds));

fprintf('\n=== THRESHOLD SCAN (GPD on exceedances) ===\n');
fprintf('%-12s  %-14s  %-10s  %-10s\n','Percentile','Threshold','Tail n','KS p-val');

for i = 1:length(thresholds)
    u           = thresholds(i);
    exceedances = data(data > u) - u;
    n_tail(i)   = length(exceedances);

    if n_tail(i) < 20
        continue
    end

    try
        pd_gpd_tmp   = fitdist(exceedances, 'GeneralizedPareto');
        [~, p]       = kstest(exceedances, 'CDF', pd_gpd_tmp);
        pvals_gpd(i) = p;
    catch
        % fit failed, leave as NaN
    end

    fprintf('%-12d  %-14.1f  %-10d  %-10.4f\n', ...
        pctiles(i), u, n_tail(i), pvals_gpd(i));
end

% Plot p-value vs threshold
figure;
plot(thresholds, pvals_gpd, 'b-o', 'LineWidth', 1.8, 'MarkerFaceColor', 'b');
yline(0.05, 'r--', '5% significance', 'LineWidth', 1.5);
xlabel('Threshold u'); ylabel('KS p-value');
title('GPD GoF p-value vs Threshold');
grid on;

% Select best threshold
[~, idx_best] = max(pvals_gpd);
u_I           = thresholds(idx_best);
fprintf('\n>>> Chosen threshold u_I = %.2f  (%dth percentile, %d tail obs)\n', ...
    u_I, pctiles(idx_best), sum(data > u_I));


%%
tail_excess = data(data > u_I) - u_I;
pd_gpd      = fitdist(tail_excess, 'GeneralizedPareto');

fprintf('\n=== GPD TAIL FIT ===\n');
fprintf('  Shape  (xi)    = %.4f\n', pd_gpd.k);
fprintf('  Scale  (sigma) = %.4f\n', pd_gpd.sigma);

if pd_gpd.k > 0
    fprintf('  Tail type: HEAVY (Pareto-like)\n');
elseif pd_gpd.k == 0
    fprintf('  Tail type: EXPONENTIAL\n');
else
    fprintf('  Tail type: BOUNDED\n');
end

[h_gpd, p_gpd] = kstest(tail_excess, 'CDF', pd_gpd);
fprintf('  KS test on tail: p = %.4f  (reject = %d)\n', p_gpd, h_gpd);

figure;
qqplot(tail_excess, pd_gpd);
title(sprintf('QQ Plot: Exceedances vs GPD  (u_I = %.0f)', u_I));
grid on;

%%
% Deduplicate x, f from your ecdf output for safe interpolation
[x_u, ia] = unique(x, 'last');
f_u        = f(ia);
ecdf_eval  = @(xq) interp1(x_u, f_u, xq, 'linear', 'extrap');

F_uI = ecdf_eval(u_I);
fprintf('\n=== COMPOSITE CDF ===\n');
fprintf('  F_empirical(u_I) = %.4f  (%.1f%% of mass below threshold)\n', F_uI, F_uI*100);

% Build composite CDF on a fine grid
x_body = linspace(minVal, u_I, 2000);
x_tail = linspace(u_I, maxVal * 10, 3000);
x_comp = [x_body, x_tail(2:end)];   % avoid duplicate point at u_I

F_body = ecdf_eval(x_body);
F_tail = F_uI + (1 - F_uI) .* cdf(pd_gpd, x_tail(2:end) - u_I);
F_comp = [F_body, F_tail];

figure;
semilogx(x, f, 'k', 'LineWidth', 2); hold on;
semilogx(x_comp, F_comp, 'r--', 'LineWidth', 1.8);
xline(u_I, 'b:', 'LineWidth', 1.5, 'Label', sprintf('u_I=%.0f', u_I));
legend('Empirical CDF', 'Composite CDF (Emp+GPD)', 'Location', 'best');
title('Composite Severity CDF');
xlabel('Loss (log scale)'); ylabel('F(x)');
grid on;

%%
years  = 10;
lambda = n / years;

fprintf('\n=== FREQUENCY MODEL ===\n');
fprintf('  Total events : %d over %d years\n', n, years);
fprintf('  Lambda       : %.1f events/year\n', lambda);

%%
rng(42);
N_sim    = 200000;
q_target = 0.999;

% Composite CDF inverse for severity sampling
[F_uniq, iu] = unique(F_comp, 'last');
x_uniq       = x_comp(iu);

fprintf('\n=== MONTE CARLO SIMULATION (%d runs) ===\n', N_sim);
annual_loss = zeros(N_sim, 1);

for s = 1:N_sim
    N_s = poissrnd(lambda);
    if N_s == 0
        continue
    end
    u_s   = rand(N_s, 1);
    sev_s = interp1(F_uniq, x_uniq, u_s, 'linear', 'extrap');
    sev_s = max(sev_s, 0);
    annual_loss(s) = sum(sev_s);
end

VaR_MC = quantile(annual_loss, q_target);
ES_MC  = mean(annual_loss(annual_loss > VaR_MC));

fprintf('  VaR 99.9%% (Monte Carlo) = %.4e\n', VaR_MC);
fprintf('  ES  99.9%% (Monte Carlo) = %.4e\n', ES_MC);

figure;
histogram(annual_loss, 300, 'Normalization', 'probability', ...
    'FaceColor', [0.2 0.5 0.8], 'EdgeColor', 'none');
xline(VaR_MC, 'r-', 'LineWidth', 2.5, ...
    'Label', sprintf('VaR 99.9%% = %.2e', VaR_MC));
title('Monte Carlo Annual Loss Distribution');
xlabel('Annual Loss (€)'); ylabel('Probability');
grid on;

%%
p_SLA   = 1 - (1 - q_target) / lambda;
VaR_SLA = interp1(F_uniq, x_uniq, p_SLA, 'linear', 'extrap');

% E[X] numerically from composite CDF
dF    = diff(F_comp);
x_mid = 0.5 * (x_comp(1:end-1) + x_comp(2:end));
E_X   = sum(x_mid .* dF);
EL    = lambda * E_X;

VaR_SLA_adj = VaR_SLA + EL;

fprintf('\n=== SINGLE LOSS APPROXIMATION ===\n');
fprintf('  p_SLA              = %.10f\n', p_SLA);
fprintf('  VaR_SLA            = %.4e\n',  VaR_SLA);
fprintf('  E[X] mean severity = %.4e\n',  E_X);
fprintf('  EL = lambda*E[X]   = %.4e\n',  EL);
fprintf('  VaR_SLA adjusted   = %.4e\n',  VaR_SLA_adj);


%% ============================================================
%% FINAL SUMMARY
%% ============================================================
fprintf('\n');
fprintf('==============================================\n');
fprintf('           FINAL RESULTS SUMMARY             \n');
fprintf('==============================================\n');
fprintf('  Observations             : %d\n',     n);
fprintf('  Frequency lambda         : %.1f/yr\n', lambda);
fprintf('  Tail threshold u_I       : %.2f\n',   u_I);
fprintf('  GPD shape  (xi)          : %.4f\n',   pd_gpd.k);
fprintf('  GPD scale  (sigma)       : %.4f\n',   pd_gpd.sigma);
fprintf('----------------------------------------------\n');
fprintf('  VaR 99.9%% - Monte Carlo  : %.4e\n',  VaR_MC);
fprintf('  VaR 99.9%% - SLA          : %.4e\n',  VaR_SLA);
fprintf('  VaR 99.9%% - SLA adjusted : %.4e\n',  VaR_SLA_adj);
fprintf('==============================================\n');