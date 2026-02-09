# Quick Resume Guide - Free Stock Prediction Project

**Last Session:** 2026-02-09
**Current Status:** T1 ✅ | T2 ✅ | T3 Hybrid ✅ | T3 Game Theory ⏳ | T4 ❌ | Tester ❌

---

## 🚀 Quick Start

### 1. Restart the Project (5 seconds)
```bash
/project-start "Free stock prediction"
```
This loads all 5 terminals with proper context files.

### 2. Review Status (1 minute)
```bash
cat /home/parris/stock_predictor/PROJECT_STATUS.md
```
Read this for complete project overview.

### 3. Choose Your Path

#### Path A: Complete T3 Game Theory (~15 min)
```bash
# Terminal: T3
cd /home/parris/stock_predictor/game_theory

# Edit parameters to speed up (manual edit needed):
# minority_game.py line 99: n_agents=20, memory_length=3
# agent_based_model.py lines 172-175: reduce all agents by 70%

python run_all_game_theory.py
```

#### Path B: Start T4 Sentiment Analysis (~3-4 hours)
```bash
# Terminal: T4
cd /home/parris/stock_predictor

# Install dependencies first
pip install transformers praw vaderSentiment requests beautifulsoup4

# Start with news sentiment (easiest)
# Create sentiment_news.py (see T4 detailed guide)
```

#### Path C: Run Final Validation (after T3 & T4 done)
```bash
# Terminal: Tester
cd /home/parris/stock_predictor

# Create validation_comprehensive.py
# Load all results and run statistical tests
```

---

## 📊 Current Results

**Best Models:**
- AAPL: 53.14% (T3 Dynamic Ensemble)
- MSFT: 52.48% (T3 Simple Stacking)
- GOOGL: 54.88% (T1 Moving Average)
- SPY: 54.69% (T1 Moving Average)

**Key Insight:** We're at 53-55%, need sentiment (T4) to push past 55%.

---

## 📁 Important Files

**Status & Documentation:**
- `/home/parris/stock_predictor/PROJECT_STATUS.md` ← Main status
- `~/.claude/context/Free stock prediction/PROJECT_PROGRESS.md` ← Session notes
- `~/.claude/context/Free stock prediction/RESUME_GUIDE.md` ← You are here

**Results (Available):**
- `results/t1_results.json` ✅
- `results/t2_results.json` ✅
- `results/t3_hybridization_results.json` ✅

**Results (Pending):**
- `results/t3_game_theory_results.json` ⏳
- `results/t4_results.json` ❌
- `results/tester_validation.json` ❌

---

## 🔧 Known Issues & Fixes

### Issue: Game Theory Timeout
**Fix:** Reduce agent counts
```python
# minority_game.py line 99
game = MinorityGame(n_agents=20, memory_length=3, n_strategies=2)

# agent_based_model.py lines 172-175
market = AgentBasedMarket(n_chartists=10, n_fundamentalists=10,
                          n_momentum=5, n_noise=5)
```

### Issue: CSV Data Format
**Already Fixed:** Data loading uses `skiprows=[1,2]`

---

## ✅ Todo List

- [ ] T3: Fix and run game theory (15 min)
- [ ] T4: Implement sentiment analysis (3-4 hours)
- [ ] Tester: Run comprehensive validation (30 min)
- [ ] Final: Generate report and visualizations (30 min)

---

## 💡 Terminal Roles

| Terminal | Role | Status |
|----------|------|--------|
| T1 | Statistical Methods | ✅ Complete |
| T2 | Machine Learning | ✅ Complete |
| T3 | Hybridization & Game Theory | ⚠️ Partial |
| T4 | Sentiment Analysis | ❌ Not Started |
| Tester | Independent Validation | ❌ Not Started |

---

## 🎯 End Goal

Generate a comprehensive report answering:
1. Which prediction method is best for stock market?
2. Do ML models beat statistical methods?
3. Does hybridization help?
4. Does sentiment analysis matter?
5. Which methods are production-ready?

**All with statistical validation (not just accuracy numbers).**
