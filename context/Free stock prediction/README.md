# Stock Predictor - Multi-Method Ensemble System

## Project Description
This project implements a comprehensive stock prediction system that combines multiple approaches:
- Statistical methods (Moving Averages, ARIMA, Technical Indicators)
- Machine Learning (Random Forest, XGBoost, SVM, Ensemble)
- Hybridization (Meta-stacking, Adaptive Selection, Dynamic Weighting)
- Game Theory (Minority Game, Agent-Based Models, Nash Equilibrium)
- Sentiment Analysis (News, Social Media, SEC Filings)

## Directory Structure
```
/home/parris/stock_predictor/
├── data/                    # Raw stock data (shared by T1)
├── results/                 # Model results and predictions
│   ├── t1_results.json     # Statistical methods results
│   ├── t2_results.json     # ML models results
│   ├── t3_results.json     # Hybridization & game theory results
│   ├── t4_results.json     # Sentiment-enhanced results
│   └── tester_validation.json  # Independent validation
├── sentiment_data/          # Sentiment analysis data (T4)
├── models/                  # Saved model files
└── reports/                 # Analysis reports and visualizations
```

## Data Requirements
- **Stock Tickers:** Configure target stocks in each terminal
- **Time Period:** Minimum 2 years of historical data recommended
- **Data Source:** yfinance (free and reliable)
- **Train/Val/Test Split:** 70/15/15 or 60/20/20

## Key Dependencies
- Python 3.8+
- yfinance, pandas, numpy
- scikit-learn, xgboost
- statsmodels (for ARIMA)
- transformers (for FinBERT)
- praw (for Reddit sentiment)
- matplotlib, seaborn (for visualizations)

## Evaluation Metrics
- **Classification:** Accuracy, Precision, Recall, F1-score
- **Regression:** MSE, MAE, R²
- **Trading:** Sharpe Ratio, Max Drawdown, Annualized Return
- **Statistical:** Paired t-tests, Diebold-Mariano test

## Communication Protocol
- Terminals coordinate via shared data directories
- Results saved in JSON format for interoperability
- Tester performs final validation on all approaches
- Use inter-terminal messaging for coordination: `/terminal-send <name> <message>`

## Best Practices
- Always use proper train/val/test splits
- Document all hyperparameters
- Save models and results with timestamps
- Include error handling for data downloads
- Log progress and errors to respective terminal logs
