# Stock Predictor - Task Assignments

## Project Overview
Enhanced stock prediction system using statistical methods, machine learning, hybridization, game theory, and sentiment analysis.

## Terminal Assignments

### T1 - Statistical Methods Specialist
- **Primary Tasks:**
  - Download stock data using yfinance
  - Implement Moving Average Crossover strategy
  - Implement ARIMA models
  - Implement technical indicators (RSI, MACD, Bollinger Bands)
  - Build backtesting framework
  - Save results to `/home/parris/stock_predictor/results/t1_results.json`
  - Share data in `/home/parris/stock_predictor/data/` for other terminals

### T2 - Machine Learning Specialist
- **Primary Tasks:**
  - Build Random Forest classifier/regressor
  - Build XGBoost model
  - Build SVM model
  - Create feature engineering pipeline
  - Implement proper train/validation/test splits
  - Build voting ensemble from ML models
  - Use T1's data from the data directory
  - Save results to `/home/parris/stock_predictor/results/t2_results.json`

### T3 - Advanced Methods (Hybridization & Game Theory)
- **Primary Tasks:**
  - **Hybridization:**
    - Meta-stacking models using T1/T2 predictions
    - Adaptive model selection based on market regimes
    - Dynamic weighted ensembles
  - **Game Theory:**
    - Minority Game implementation
    - Agent-Based Market modeling
    - Nash equilibrium strategies
  - Use T1/T2 results as inputs
  - Save results to `/home/parris/stock_predictor/results/t3_results.json`

### T4 - Sentiment Analysis & Alternative Data
- **Primary Tasks:**
  - Financial news sentiment (Yahoo Finance, Google News RSS, FinBERT)
  - Social media sentiment (Reddit r/wallstreetbets via PRAW)
  - SEC filings analysis (EDGAR)
  - Create sentiment features to enhance ML models
  - **Use FREE data sources only**
  - Save sentiment data to `/home/parris/stock_predictor/sentiment_data/`
  - Save results to `/home/parris/stock_predictor/results/t4_results.json`

### Tester - Independent Validation Specialist
- **Primary Tasks:**
  - Validate all models (T1, T2, T3, T4) on holdout test set
  - Calculate comprehensive metrics:
    - Accuracy, Precision, Recall, F1
    - Sharpe ratio, Max drawdown
    - Annualized returns
  - Perform statistical significance tests:
    - Paired t-tests
    - Diebold-Mariano tests
  - Generate comparative visualizations and tables
  - Save validation results to `/home/parris/stock_predictor/results/tester_validation.json`

## Coordination Guidelines
- All terminals work in `/home/parris/stock_predictor`
- Share data via common directories
- T1 provides base data for other terminals
- T2 and T1 results feed into T3
- T4 creates supplementary sentiment features
- Tester validates all approaches independently
