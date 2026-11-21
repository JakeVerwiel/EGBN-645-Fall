The Model runs properly without errors and important notes to get the results are as follows
Model Code: it is listed under MPC_Graphite2_milestone_3.gms
  There are two methods of seeing results
  1. The lst file: MPC_Graphite2_milsestone_3.lst
  2. The gdx file: graphite_milestone3.gdx
Under both files the output tables can be found fia the following table titles or list files
1. Stage 1 (EQM and Chinese Expansion EQM): Parameter Results
2. Stage 2 (EQM/Substitution and Chinese Expansion EQM): Parameter M2Results
3. Stage 3 (EQM/new market entrant and Chinese Expansion EQM): Parameter report3 *I am ging to fix this in the final iteration

Input and Calibration Data:
  Unfortunately I hardcoded it in, so I am pasting it here, and in the model gms for reference
  Calibration Data is as follow (all under the following titles

* REGIONAL BASELINE
* Quantities are in model units. For reporting, 1 unit = 15,500 tonnes/year.
* Prices and trade wedges are in USD per metric tonne.
* The price-table row label is preserved as written in the model.
*
* set r /USA, China, ROW/;
* set year /2025/;
*
* parameter
*     pbar(r)
*     qbar_s(r) /USA 0, China 81.94, ROW 18.06/
*     qbar_d(r) /USA 4.21, China 73.01, ROW 22.78/
*     e_d       /-0.58/
*     e_s       /0.31/;
*
* table priceIndex(year,r)
*           USA    China    ROW
* 2025      775      460    650
* ;
*
* pbar(r) = sum(year, priceIndex(year,r)) / card(year);
* qbar_d("ROW") = sum(r, qbar_s(r)) - qbar_d("USA") - qbar_d("China");
*
* Regional demand and supply curve coefficients.
* parameter a(r), b(r), c(r), d(r);
*
* b(r) = pbar(r) / (e_d*qbar_d(r));
* a(r) = pbar(r) - b(r)*qbar_d(r);
* d(r)$(qbar_s(r) > 0) = pbar(r) / (e_s*qbar_s(r));
* c(r)$(qbar_s(r) > 0) = pbar(r) - d(r)*qbar_s(r);
*
* c("USA") = 100;
* d("USA") = 2;
*
* Trade wedges. tradeCost(r) is the wedge from region r to the USA.
* parameter tradeCost(r) /USA 0, China 315, ROW 125/;
* scalar tradeCostChinaROW /190/;
*
* MILESTONE 1: CHINESE PRODUCTION SHOCKS
* set productionShock /S10, S20, S30, S40/;
* parameter shockPct(productionShock) /
*     S10 0.10, S20 0.20, S30 0.30, S40 0.40
* /;
* U.S. production and exports are fixed at 0.
*
* MILESTONE 2: NATURAL AND SYNTHETIC GRAPHITE
* set g /natural, synthetic/;
* set china2 /C00, C10, C20, C30, C40/;
* set syn2 /T00, T10, T20, T30/;
*
* parameter chinaPct2(china2) /
*     C00 0, C10 0.10, C20 0.20, C30 0.30, C40 0.40
* /;
* parameter synPct2(syn2) /
*     T00 0, T10 0.10, T20 0.20, T30 0.30
* /;
* parameter share2(g) /natural 0.70, synthetic 0.30/;
*
* scalar epsCES /0.0001/;
* The CES functional form implies a substitution elasticity of 2.
*
* parameter qbar_s2(r,g), qbar_d2(r,g), gbarCES(r);
* parameter c2(r,g), d2(r,g), aCES(r), bCES(r), weight2(g);
*
* qbar_s2(r,g) = qbar_s(r)*share2(g)/share2("natural");
* qbar_d2(r,g) = qbar_d(r)*share2(g)/share2("natural");
*
* d2(r,g)$(qbar_s2(r,g) > 0) = pbar(r)/(e_s*qbar_s2(r,g));
* c2(r,g)$(qbar_s2(r,g) > 0) = pbar(r) - d2(r,g)*qbar_s2(r,g);
*
* c2("USA","natural") = 100;
* d2("USA","natural") = 2;
* c2("USA","synthetic") = 110;
* d2("USA","synthetic") = 2;
*
* gbarCES(r) = sum(g, qbar_d2(r,g)) + epsCES;
* bCES(r) = pbar(r)/(e_d*gbarCES(r));
* aCES(r) = pbar(r) - bCES(r)*gbarCES(r);
* weight2(g) = sqrt(share2(g));
*
* Override applied before the Milestone 2 baseline solve.
* U.S. production and exports remain fixed at 0 for both products.
* c2("USA","natural") = 10;
* d2("USA","natural") = 2;
*
* MILESTONE 3: U.S. ENTRY AND CHINESE PRODUCTION SHOCKS
* set shock3 /Base, S10, S20, S30, S40/;
* set entry3 /NoEntry, Entry/;
* parameter shockPct3(shock3) /
*     Base 0, S10 0.10, S20 0.20, S30 0.30, S40 0.40
* /;
*
* scalar
*     fixedCost3  /6238.61/
*     USCapacity3 /11.29/;
*
* Restore the baseline weights and apply the entrant's cost curve.
* weight2(g) = sqrt(share2(g));
* c2("USA","natural") = 610;
* d2("USA","natural") = 2;
* fixedCost3 = 6238.61;
*
* NoEntry: U.S. natural production is fixed at 0.
* Entry: U.S. natural production is bounded between 0 and 11.29.
* Entry viability: net profit > 0 and production > 0.0001 model units.
