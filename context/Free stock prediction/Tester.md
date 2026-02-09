# Terminal: Tester | Project: Free stock prediction

**Role:** Independent Validation Specialist

**Status:** Not Started ❌

---

## Files Created/Modified by This Terminal

<!-- FILE_REGISTRY_START -->
## File Registry

| File Path | Purpose | Last Modified |
|-----------|---------|---------------|
| (No files created yet) | - | - |
<!-- FILE_REGISTRY_END -->

---

## Mission

Perform **independent, comprehensive validation** of ALL prediction methods:
- T1: Statistical Methods (3 methods)
- T2: Machine Learning (4 models)
- T3: Hybridization (3 approaches) + Game Theory (2+ methods)
- T4: Sentiment-Enhanced Models

**Key Principle:** Don't just report accuracies - validate statistical significance!

---

## Assigned Tasks

### 1. Load All Results ✅
```python
results_files = [
    '/results/t1_results.json',           # Available ✅
    '/results/t2_results.json',           # Available ✅
    '/results/t3_hybridization_results.json',  # Available ✅
    '/results/t3_game_theory_results.json',    # Pending ⏳
    '/results/t4_results.json'            # Pending ⏳
]
```

### 2. Calculate Comprehensive Metrics

For each method, calculate:

**Classification Metrics:**
- Accuracy
- Precision, Recall, F1-Score
- Confusion Matrix
- ROC-AUC (if probability scores available)

**Trading Performance Metrics:**
- Sharpe Ratio
- Maximum Drawdown
- Annualized Return
- Win Rate (% profitable trades)
- Profit Factor

**Risk Metrics:**
- Volatility of returns
- Value at Risk (VaR)
- Sortino Ratio

### 3. Statistical Significance Tests

**Paired t-test:**
- Compare each method's predictions against a baseline
- Test if improvement is statistically significant (p < 0.05)

**Diebold-Mariano Test:**
- Compare forecast accuracy between two methods
- Specifically designed for time series predictions

**McNemar's Test:**
- Compare two classifiers on the same test set
- Tests if one is significantly better

### 4. Cross-Validation Analysis

- Verify results on different time periods
- Test period: 2024-01-01 to 2026-01-15 (done)
- Additional validation:
  - 2023 (if available)
  - Different market regimes (bull/bear/sideways)

### 5. Comparative Visualizations

**Create:**
- Accuracy comparison bar chart (all methods, all stocks)
- Performance over time (rolling accuracy)
- Sharpe ratio comparison
- Confusion matrix heatmaps
- ROC curves (if applicable)
- Trading performance curves (cumulative returns)

### 6. Generate Final Report

**Sections:**
1. Executive Summary
   - Best method overall
   - Best method per stock
   - Statistical significance findings

2. Detailed Results Table
   - All metrics for all methods
   - Ranked by performance

3. Statistical Tests Summary
   - Which improvements are real vs random chance
   - Confidence levels

4. Recommendations
   - Production-ready methods
   - Methods to avoid
   - Best use cases for each approach

5. Limitations & Future Work

---

## Expected Deliverables

**Files to Create:**
```
/home/parris/stock_predictor/
├── validation_comprehensive.py     # Main validation script
├── results/
│   └── tester_validation.json     # All metrics & test results
├── reports/
│   ├── final_report.md            # Comprehensive markdown report
│   ├── accuracy_comparison.png
│   ├── sharpe_comparison.png
│   ├── performance_over_time.png
│   ├── confusion_matrices.png
│   └── trading_performance.png
└── FINAL_RESULTS_SUMMARY.md       # Updated with final validated results
```

---

## Statistical Tests Implementation

**Example: Paired t-test**
```python
from scipy import stats

# Compare method A vs method B
method_a_correct = [1, 0, 1, 1, 0, ...]  # Binary correctness
method_b_correct = [1, 1, 1, 0, 0, ...]

t_stat, p_value = stats.ttest_rel(method_a_correct, method_b_correct)

if p_value < 0.05:
    print("Significant difference!")
else:
    print("No significant difference")
```

**Example: Diebold-Mariano Test**
```python
from statsmodels.tsa.stattools import acf

def diebold_mariano_test(errors_a, errors_b):
    """
    Test if forecast errors from two methods differ significantly.
    """
    d = errors_a**2 - errors_b**2  # Loss differential
    mean_d = d.mean()
    var_d = d.var()

    # Calculate test statistic
    dm_stat = mean_d / np.sqrt(var_d / len(d))

    # Two-tailed test
    p_value = 2 * (1 - stats.norm.cdf(abs(dm_stat)))

    return dm_stat, p_value
```

---

## Validation Checklist

### Data Quality Checks
- [ ] All results files exist and load correctly
- [ ] Same test period used across all methods
- [ ] No data leakage (future data used in training)
- [ ] Consistent target definition (next-day direction)

### Metric Calculations
- [ ] Accuracy for all methods
- [ ] Precision/Recall/F1 for all methods
- [ ] Sharpe Ratio (need to implement trading strategy)
- [ ] Maximum Drawdown
- [ ] Confusion matrices

### Statistical Tests
- [ ] Baseline comparison (all vs random 50%)
- [ ] Paired t-tests (top methods vs each other)
- [ ] Diebold-Mariano tests
- [ ] Confidence intervals for all metrics

### Visualizations
- [ ] Bar chart: accuracies by method and stock
- [ ] Line chart: rolling performance over time
- [ ] Heatmap: method performance across stocks
- [ ] Trading performance: cumulative returns
- [ ] Statistical significance markers

### Report Generation
- [ ] Executive summary (1 page)
- [ ] Detailed tables
- [ ] Statistical test results
- [ ] Recommendations
- [ ] Save as markdown and PDF

---

## Key Questions to Answer

1. **Which method is truly the best?**
   - Not just highest accuracy, but statistically significant

2. **Is ML better than statistical methods?**
   - T2 vs T1 comparison with significance tests

3. **Does hybridization help?**
   - T3 vs best of T1/T2 with statistical validation

4. **Does sentiment matter?**
   - T4 vs baseline with rigorous testing

5. **Which stocks are most predictable?**
   - Variance in performance across AAPL, MSFT, GOOGL, SPY

6. **Are any methods production-ready?**
   - Consider accuracy, stability, computational cost

---

## Dependencies

```bash
pip install scipy  # Statistical tests
pip install statsmodels  # Diebold-Mariano
pip install matplotlib seaborn  # Visualizations
pip install pandas numpy  # Data handling
```

---

## Coordination Notes

**Wait for:**
- T3 game theory completion ⏳
- T4 sentiment analysis completion ⏳

**Then:**
1. Load all results
2. Run comprehensive validation
3. Generate final report
4. Update FINAL_RESULTS_SUMMARY.md

**Inputs from all terminals:**
- Results JSON files
- Model predictions (if available)
- Performance logs

**Final output:**
- Definitive ranking of all methods
- Statistical confidence in findings
- Production recommendations
