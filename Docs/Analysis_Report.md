# Data Analysis Report

**Analysis Period**: 2026-01-01 ~ 2026-02-11
**Data Count**: 38451 rows

## 1. Feature-Label Correlations
Top 10 Positive/Negative Correlations for Label_Open_Buy:

### Positive Correlation (Buy Signal)
|                   |   Label_Open_Buy |
|:------------------|-----------------:|
| LRA_BSPScale(180) |        0.124798  |
| QQE_TrLevel       |        0.104227  |
| LRA_stdS(180)     |        0.103305  |
| LRA_BSPScale(60)  |        0.0979114 |
| QQE_RsiMa         |        0.086876  |
| LRA_stdS(60)      |        0.0807684 |
| CHV_Val           |        0.0468825 |
| CHV_CVScale       |        0.0439299 |
| CHV_StdDev        |        0.0396129 |
| CE_Upl1           |        0.0354813 |

### Negative Correlation (Buy Signal)
|                     |   Label_Open_Buy |
|:--------------------|-----------------:|
| TDI_Signal          |       0.00901686 |
| SmoothBOP_Val(30,5) |       0.00858279 |
| SmoothBOP_Val(10,3) |       0.00845685 |
| ADX_Val             |       0.00293366 |
| ADX_Scale           |       0.00149768 |
| BOP_Up1             |      -0.0105217  |
| BOP_Diff            |      -0.0626372  |
| BOP_Scale           |      -0.0629071  |
| CSI_Val             |      -0.0948396  |
| CSI_Scale           |      -0.0989231  |

## 2. Dual LRAVGSTD Analysis
|                   |   Label_Open_Buy |   Label_Open_Sell |   Label_Close_Buy |   Label_Close_Sell |
|:------------------|-----------------:|------------------:|------------------:|-------------------:|
| LRA_stdS(60)      |        0.0807684 |        -0.102328  |         0.0830767 |         -0.115309  |
| LRA_BSPScale(60)  |        0.0979114 |        -0.0829926 |         0.110229  |         -0.0813528 |
| LRA_stdS(180)     |        0.103305  |        -0.111068  |         0.104602  |         -0.124777  |
| LRA_BSPScale(180) |        0.124798  |        -0.0929213 |         0.131174  |         -0.0934847 |

> **Insight**: Compare sensitivity of Short (60) vs Long (180) periods.

## 3. Intra-Indicator Relationships
### BOP Group
|                     |   Label_Open_Buy |   Label_Open_Sell |   Label_Close_Buy |   Label_Close_Sell |
|:--------------------|-----------------:|------------------:|------------------:|-------------------:|
| BOP_Diff            |      -0.0626372  |         0.0150232 |        0.0150674  |         -0.0142948 |
| BOP_Up1             |      -0.0105217  |        -0.0299702 |       -0.00888344 |         -0.0209483 |
| BOP_Scale           |      -0.0629071  |         0.0154258 |        0.0159537  |         -0.0156445 |
| SmoothBOP_Val(10,3) |       0.00845685 |         0.0216303 |        0.00752507 |          0.0134003 |
| SmoothBOP_Val(30,5) |       0.00858279 |         0.0216508 |        0.00729172 |          0.0135871 |

