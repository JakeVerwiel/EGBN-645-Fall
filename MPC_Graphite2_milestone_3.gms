*================================================
*Impotant Note: Calibration numbers are hard coded in this model. If you change the calibration, you will need to update the numbers in the code.
*They are as follows.
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
* Graphite market model | 100 model units = 1.55 million tonnes per year
*================================================
set r /USA, China, ROW/ ;

set year /2025/;
parameter
pbar(r),
qbar_s(r) /USA 0,    CHINA 81.94, ROW 18.06/,
qbar_d(r) /USA 4.21, CHINA 73.01, ROW 22.78/,
e_d /-.58/ ,
e_s /0.31/ ;

* Regional reference prices in USD per metric tonne.
table priceIndex(year,r)
         USA  CHINA  ROW
2025     775   460   650
;
pbar(r) = sum(year, priceIndex(year,r)) / card(year);

qbar_d("row") = sum(r,qbar_s(r)) - qbar_d("USA") - qbar_d("China") ;

parameter a(r), b(r),  c(r),  d(r);
b(r) = pbar(r) / (e_d * qbar_d(r)) ;
a(r) = pbar(r) - b(r) * qbar_d(r) ;
d(r)$(qbar_s(r) > 0) = pbar(r) / (e_s * qbar_s(r));
c(r)$(qbar_s(r) > 0) = pbar(r) - d(r) * qbar_s(r);

* Potential U.S. graphite producer.
c("USA") = 100;
d("USA") = 2;

scalar e;
parameter tradeCost(r);
tradeCost(r) = 0;
tradeCost("China") = 315;
tradeCost("ROW") = 125;
scalar tradeCostChinaROW /190/;
positive variable Xcr "China exports to ROW";

positive variable Qd(r), Qs(r) ;
positive variable X(r) "exports" ;
Qs.fx("USA") = 0;
X.fx("USA") = 0;
variable W "total welfare" ;

equation objfn, market_clearing(r) ;
objfn.. W =e=
    sum(r, a(r)*Qd(r) + b(r)*sqr(Qd(r))/2
    - c(r)*Qs(r) - d(r)*sqr(Qs(r))/2)
    - sum(r, tradeCost(r)*X(r))
    - tradeCostChinaROW*Xcr;

alias(r,rr);
market_clearing(r)..
    Qs(r)
    + sum(rr$(not sameas(rr,"USA")), X(rr))$sameas(r,"USA")
    + Xcr$sameas(r,"ROW")
    =g=
    Qd(r)
    + X(r)$(not sameas(r,"USA"))
    + Xcr$sameas(r,"China");

* Solve the welfare problem first to initialize the MCP.
model simple /all/;
solve simple using QCP maximizing W;

set scenario /BAU/;
set metric /Qd, Qs, P, Exports/;
parameter rep(scenario,metric,r);
rep("BAU","Qd",r) = Qd.l(r);
rep("BAU","Qs",r) = Qs.l(r);
rep("BAU","P",r) = -market_clearing.m(r);
rep("BAU","Exports",r) = X.l(r);
execute_unload 'rep_graphite_mcp.gdx' ;

positive variable P(r) ;
equation foc_qs(r), foc_qd(r), foc_x(r) ;

foc_qs(r).. c(r) + d(r) * Qs(r) =g= P(r) ;
foc_qd(r)..   P(r) =g= a(r)+b(r)*Qd(r) ;
foc_x(r)$(not sameas(r,"USA"))..
    tradeCost(r) + P(r) =g= P("USA");
equation foc_xcr;
foc_xcr.. tradeCostChinaROW + P("China") =g= P("ROW");

model graphite_mcp /
    market_clearing.P,
    foc_qs.Qs,
    foc_qd.Qd,
    foc_x.X,
    foc_xcr.Xcr
/;

P.l(r) = max(0, -market_clearing.m(r));
solve graphite_mcp using MCP;

parameter results(*,*,r);
parameter welfare(*);
* Record the MCP baseline.
results("Baseline","Price",r)   = P.l(r);
results("Baseline","Demand",r)  = Qd.l(r);
results("Baseline","Supply",r)  = Qs.l(r);
results("Baseline","Exports",r) = X.l(r);

welfare("Baseline") =
    sum(r,
        a(r)*Qd.l(r) + b(r)*sqr(Qd.l(r))/2
        - c(r)*Qs.l(r) - d(r)*sqr(Qs.l(r))/2
    )
    - sum(r, tradeCost(r)*X.l(r));

* Milestone 1 | Chinese natural graphite production expansion
set productionShock /S10, S20, S30, S40/;
parameter shockPct(productionShock) /
    S10 0.10, S20 0.20, S30 0.30, S40 0.40
/;

scalar baselineChinaProduction;
parameter targetProduction(productionShock);
baselineChinaProduction = Qs.l("China");

* Re-solve the QCP and MCP for each production shock.
loop(productionShock,
    Qs.fx("China") = baselineChinaProduction*(1+shockPct(productionShock));
    targetProduction(productionShock) = baselineChinaProduction*(1+shockPct(productionShock));
    solve simple using QCP maximizing W;
    P.l(r) = max(0,-market_clearing.m(r));
    solve graphite_mcp using MCP;
    results(productionShock,"Price",r) = P.l(r);
    results(productionShock,"Demand",r) = Qd.l(r);
    results(productionShock,"Supply",r) = Qs.l(r);
    results(productionShock,"Exports",r) = X.l(r);

* Calculate the original Milestone 1 welfare report.
    welfare(productionShock) =
        sum(r,
            a(r)*Qd.l(r)
            + b(r)*sqr(Qd.l(r))/2
            - c(r)*Qs.l(r)
            - d(r)*sqr(Qs.l(r))/2
        )
        - sum(r,tradeCost(r)*X.l(r));
);

Qs.lo("China") = 0;
Qs.up("China") = +inf;

display baselineChinaProduction;
display targetProduction;
display results;
display welfare;

execute_unload 'graphite_milestone1.gdx';

* Milestone 2 | Natural and synthetic graphite substitution
set g /natural, synthetic/;
set china2 /C00, C10, C20, C30, C40/;
parameter chinaPct2(china2) /
    C00 0, C10 0.10, C20 0.20, C30 0.30, C40 0.40
/;
set syn2 /T00, T10, T20, T30/;
parameter synPct2(syn2) /
    T00 0, T10 0.10, T20 0.20, T30 0.30
/;

* Illustrative natural and synthetic baseline shares.
parameter share2(g) /
    natural 0.70, synthetic 0.30
/;

parameter qbar_s2(r,g);
parameter c2(r,g), d2(r,g);
parameter weight2(g);
qbar_s2(r,g) = qbar_s(r)*share2(g)/share2("natural");

* Calibrate the supply curve for each product.
d2(r,g)$(qbar_s2(r,g)>0) = pbar(r)/(e_s*qbar_s2(r,g));
c2(r,g)$(qbar_s2(r,g)>0) = pbar(r)-d2(r,g)*qbar_s2(r,g);
c2("USA","natural") = 100;
d2("USA","natural") = 2;
c2("USA","synthetic") = 110;
d2("USA","synthetic") = 2;

* Calibrate the demand curve for the CES basket.
scalar epsCES /0.0001/;
parameter qbar_d2(r,g), gbarCES(r), aCES(r), bCES(r);

qbar_d2(r,g) = qbar_d(r)*share2(g)/share2("natural");
gbarCES(r)   = sum(g, qbar_d2(r,g)) + epsCES;
bCES(r) = pbar(r)/(e_d*gbarCES(r));
aCES(r) = pbar(r) - bCES(r)*gbarCES(r);
scalar weightDenom;

positive variables
    QdCES(r,g)
    QsCES(r,g)
    XCES(r,g)
    XcrCES(g)
    GCES(r);
variable WCES;

equations
    cesDemand(r)
    objCES
    marketCES(r,g);

cesDemand(r)..
    GCES(r) =e=
    sqr(weight2("natural")*sqrt(QdCES(r,"natural")+epsCES)
        + weight2("synthetic")*sqrt(QdCES(r,"synthetic")+epsCES));

objCES..
    WCES =e=
    sum(r,
        aCES(r)*GCES(r)
        + bCES(r)*sqr(GCES(r))/2
    )
    -
    sum((r,g),
        c2(r,g)*QsCES(r,g)
        + d2(r,g)*sqr(QsCES(r,g))/2
        + tradeCost(r)*XCES(r,g)
    )
    - tradeCostChinaROW*sum(g, XcrCES(g));

marketCES(r,g)..
    QsCES(r,g)
    + sum(rr$(not sameas(rr,"USA")),XCES(rr,g))
        $sameas(r,"USA")
    + XcrCES(g)$sameas(r,"ROW")
    =e=
    QdCES(r,g)
    + XCES(r,g)$(not sameas(r,"USA"))
    + XcrCES(g)$sameas(r,"China");

model graphite_CES / cesDemand objCES marketCES /;

* Initialize and solve the baseline with no U.S. production.
QsCES.fx("USA",g) = 0;
XCES.fx("USA",g) = 0;
weight2(g) = sqrt(share2(g));

* Illustrative U.S. cost curve used in Milestone 2.
c2("USA","natural") = 10;
d2("USA","natural") = 2;
QdCES.l(r,g) = qbar_d(r)*share2(g);
QsCES.l(r,g) = qbar_s(r)*share2(g);
GCES.l(r) = qbar_d(r);

solve graphite_CES using NLP maximizing WCES;
abort$(graphite_CES.modelStat <> 1 and graphite_CES.modelStat <> 2)
    "Milestone 2 baseline did not solve";

scalar baselineChinaNatural;
baselineChinaNatural = QsCES.l("China","natural");

* Apply the production shocks and synthetic preference shifts.
parameter M2results(china2,syn2,*);
parameter qsces_rep ;
loop(china2,
    QsCES.fx("China","natural") = baselineChinaNatural*(1 + chinaPct2(china2));

    loop(syn2,
        qsces_rep(china2,syn2,"qsces") = QsCES.l("China","natural") ;

* Increase and normalize the synthetic preference weight.
        weightDenom = sqrt(
            share2("natural")
            + share2("synthetic")*sqr(1+synPct2(syn2))
        );
        weight2("natural") = sqrt(share2("natural"))/weightDenom;
        weight2("synthetic") = sqrt(share2("synthetic")) *(1+synPct2(syn2))/weightDenom;

        qsces_rep(china2,syn2,"natural") = weight2("natural") ;
        qsces_rep(china2,syn2,"synthetic") = weight2("synthetic") ;

* The second solve starts from the first solution.
        solve graphite_CES using NLP maximizing WCES;
        solve graphite_CES using NLP maximizing WCES;
        abort$(graphite_CES.modelStat <> 1 and graphite_CES.modelStat <> 2)
            "Milestone 2 scenario did not solve";

* Record demand, prices, supply, trade, and welfare.
        M2results(china2,syn2,"US_Natural_Demand") = QdCES.l("USA","natural");
        M2results(china2,syn2,"US_Synthetic_Demand") = QdCES.l("USA","synthetic");
        M2results(china2,syn2,"US_Natural_Price") = -marketCES.m("USA","natural");
        M2results(china2,syn2,"US_Synthetic_Price") = -marketCES.m("USA","synthetic");
        M2results(china2,syn2,"China_Natural_Supply") = QsCES.l("China","natural");
        M2results(china2,syn2,"China_Synthetic_Supply") = QsCES.l("China","synthetic");
        M2results(china2,syn2,"China_Natural_Exports") = XCES.l("China","natural");
        M2results(china2,syn2,"China_Synthetic_Exports") = XCES.l("China","synthetic");
        M2results(china2,syn2,"US_Synthetic_Share") =
            QdCES.l("USA","synthetic")
            / max(epsCES,sum(g,QdCES.l("USA",g)));
        M2results(china2,syn2,"Welfare") = WCES.l;

    );
);

display baselineChinaNatural;
display M2results;
execute_unload 'graphite_milestone2.gdx' ;

* Milestone 3 | Competition and U.S. entry
option limrow=0, limcol=0, solprint=off;

set shock3 /Base, S10, S20, S30, S40/;
parameter shockPct3(shock3) /Base 0, S10 0.10, S20 0.20,
 S30 0.30, S40 0.40/;
set entry3 /NoEntry, Entry/;

scalar
    fixedCost3 /6238.61/
    USCapacity3 /11.29/
    ChinaBase3
    ChinaWTP3;

parameter
    price3(r,g)
    report3(shock3,entry3,*)
    decision3(shock3,*);

* Restore baseline CES preferences and production bounds.
weight2(g) = sqrt(share2(g));

* Costs for the potential U.S. entrant.
c2("USA","natural") = 610;
d2("USA","natural") = 2;
fixedCost3 = 6238.61;

QsCES.lo("China","natural") = 0;
QsCES.up("China","natural") = +inf;
QsCES.fx("USA",g) = 0;

solve graphite_CES using NLP maximizing WCES;
abort$(graphite_CES.modelStat <> 1 and graphite_CES.modelStat <> 2)
   "Milestone 3 baseline failed";

ChinaBase3 = QsCES.l("China","natural");

* Compare no-entry and entry equilibria at each Chinese output level.
loop(shock3,
    QsCES.fx("China","natural") = ChinaBase3*(1+shockPct3(shock3));

    loop(entry3,
* Enable U.S. natural graphite production only in the entry case.
        QsCES.lo("USA","natural") = 0;
        QsCES.up("USA","natural") = 0;
        if(sameas(entry3,"Entry"),
            QsCES.up("USA","natural") = USCapacity3;
        );

        solve graphite_CES using NLP maximizing WCES;
        abort$(graphite_CES.modelStat <> 1 and graphite_CES.modelStat <> 2)
           "Milestone 3 scenario failed";

        price3(r,g) = max(0,-marketCES.m(r,g));

* Record U.S. price, output, and net profit.
        report3(shock3,entry3,"US_Price") = price3("USA","natural");
        report3(shock3,entry3,"US_Production") = QsCES.l("USA","natural");
        report3(shock3,entry3,"US_Net_Profit") =
            price3("USA","natural") *QsCES.l("USA","natural")
            -c2("USA","natural") *QsCES.l("USA","natural")
            -d2("USA","natural") *sqr(QsCES.l("USA","natural"))/2
            -fixedCost3$sameas(entry3,"Entry");

* Record Chinese producer profit.
        report3(shock3,entry3,"China_Profit") =
            sum(g,
                price3("China",g) *QdCES.l("China",g)
                +(price3("USA",g) -tradeCost("China")) *XCES.l("China",g)
                -c2("China",g) *QsCES.l("China",g)
                -d2("China",g) *sqr(QsCES.l("China",g))/2
            );

* Record Chinese and global welfare.
        report3(shock3,entry3,"China_Welfare") =
            a("China")*GCES.l("China")
            +b("China") *sqr(GCES.l("China"))/2
            -sum(g, price3("China",g) *QdCES.l("China",g) )
            +report3(shock3,entry3,"China_Profit");

        report3(shock3,entry3,"Global_Welfare") =
            WCES.l
            -fixedCost3$sameas(entry3,"Entry");

    );

* Entry requires positive net profit and production.
    decision3(shock3,"US_Enters") = (report3(shock3,"Entry","US_Net_Profit") > 0)
        and
        (report3(shock3,"Entry","US_Production") > 0.0001);

);

* Compare Chinese profits and welfare with the no-entry baseline.
decision3(shock3,"China_Profit_Loss") =
    report3("Base","NoEntry","China_Profit")
    - report3(shock3,"NoEntry","China_Profit");

decision3(shock3,"China_Welfare_Loss") =
    report3("Base","NoEntry","China_Welfare")
    - report3(shock3,"NoEntry","China_Welfare");

* Evaluate the profit gain from preventing entry.
ChinaWTP3 = max(0,
    report3("Base","NoEntry","China_Profit")
    -report3("Base","Entry","China_Profit")
);

decision3(shock3,"Deters_Entry") = decision3("Base","US_Enters")
    *(1-decision3(shock3,"US_Enters"));

decision3(shock3,"Worth_Deterring") = (decision3(shock3,"Deters_Entry") > 0)
    and
    (decision3(shock3,"China_Profit_Loss") <= ChinaWTP3);

* Find the lowest profit sacrifice among shocks that deter entry.
scalar
    CanDeter3
    MinDeterrenceCost3
    DeterrenceWorthIt3;

CanDeter3 = sum( shock3$(decision3(shock3,"Deters_Entry") > 0), 1 );

MinDeterrenceCost3 = 0;
if(CanDeter3 > 0,
    MinDeterrenceCost3 = smin(
        shock3$(decision3(shock3,"Deters_Entry") > 0),
        decision3(shock3,"China_Profit_Loss")
    );
);

DeterrenceWorthIt3 = 0;
if(CanDeter3 > 0,
    DeterrenceWorthIt3 = (MinDeterrenceCost3 <= ChinaWTP3);
);

display CanDeter3, MinDeterrenceCost3, ChinaWTP3, DeterrenceWorthIt3;
* Preserve the listing's repeated display of the deterrence results.
display CanDeter3, MinDeterrenceCost3, ChinaWTP3, DeterrenceWorthIt3;

display ChinaBase3, report3, decision3, ChinaWTP3;

execute_unload 'graphite_milestone3.gdx' ;
$exit
