set r /USA, China, ROW/ ; 

set year /2020*2025/;

parameter
pbar(r),
qbar_s(r) /USA 0, CHINA 75, ROW 25/,
qbar_d(r) /USA 20.5, CHINA 10, ROW 69.5/,
e_d /-0.58/,
e_s /0.2/ ;

table priceIndex(year,r)
         USA  CHINA  ROW
2020     100     85   95
2021     110     90  102
2022     135    115  125
2023     120    105  112
2024     115     95  108
2025     125    100  115
;

pbar(r) = sum(year, priceIndex(year,r)) / card(year);

qbar_d("row") = sum(r,qbar_s(r)) - qbar_d("USA") - qbar_d("China") ; 

parameter a(r), b(r),  c(r),  d(r); 

b(r) = pbar(r) / (e_d * qbar_d(r)) ; 
a(r) = pbar(r) - b(r) * qbar_d(r) ; 
d(r)$(qbar_s(r) > 0) = pbar(r) / (e_s * qbar_s(r));
c(r)$(qbar_s(r) > 0) = pbar(r) - d(r) * qbar_s(r);

* Potential US graphite producer
c("USA") = 100;
d("USA") = 2;

scalar e;
parameter tradeCost(r);
tradeCost(r) = 0;
tradeCost("China") = 10;
tradeCost("ROW") = 10;

positive variable Qd(r), Qs(r) ; 
positive variable X(r) "exports" ;
Qs.fx("USA") = 0;
X.fx("USA") = 0;
variable W "total welfare" ; 

equation objfn, market_clearing(r) ; 

objfn.. W =e=
    sum(r, a(r)*Qd(r) + b(r)*sqr(Qd(r))/2
    - c(r)*Qs(r) - d(r)*sqr(Qs(r))/2)
    - sum(r, tradeCost(r)*X(r)); 

$ontext
market_clearing_usa.. Qd("USA") + X("USA") =e= Qs("USA") ;
market_clearing_china.. Qd("China") + X("China") =e= Qs("China") ;
market_clearing_row.. Qd("ROW") =e= Qs("ROW") + X("USA") + X("China")  ; 
$offtext

alias(r,rr);

market_clearing(r)..
    Qs(r)
    + sum(rr$(not sameas(rr,"USA")), X(rr))$sameas(r,"USA")
    =g=
    Qd(r)
    + X(r)$(not sameas(r,"USA"));

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

model graphite_mcp
/
market_clearing.P,
foc_qs.qs,
foc_qd.qd,
foc_x.X
/;

P.l(r) = max(0, -market_clearing.m(r));

solve graphite_mcp using MCP;

parameter results(*,*,r);
parameter welfare(*);

* Save baseline results
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

    
* ==========================================
* MILESTONE 1: CHINESE PRODUCTION EXPANSION
* ==========================================

set productionShock /S10, S20, S30, S40/;

parameter shockPct(productionShock)
/
S10 0.10
S20 0.20
S30 0.30
S40 0.40
/;

scalar baselineChinaProduction;

parameter targetProduction(productionShock);

* Save baseline Chinese production
baselineChinaProduction = Qs.l("China");

* ==========================================
* RUN PRODUCTION EXPANSION SCENARIOS
* ==========================================

loop(productionShock,

* Increase Chinese production
    Qs.fx("China") =
        baselineChinaProduction*(1+shockPct(productionShock));

    targetProduction(productionShock) =
        baselineChinaProduction*(1+shockPct(productionShock));

* Solve new welfare equilibrium
    solve simple using QCP maximizing W;

* Initialize equilibrium prices
    P.l(r) = max(0,-market_clearing.m(r));

* Solve MCP equilibrium
    solve graphite_mcp using MCP;

* Save scenario results
    results(productionShock,"Price",r) = P.l(r);
    results(productionShock,"Demand",r) = Qd.l(r);
    results(productionShock,"Supply",r) = Qs.l(r);
    results(productionShock,"Exports",r) = X.l(r);

* Calculate welfare
    welfare(productionShock) =
        sum(r,
            a(r)*Qd.l(r)
            + b(r)*sqr(Qd.l(r))/2
            - c(r)*Qs.l(r)
            - d(r)*sqr(Qs.l(r))/2
        )
        - sum(r,tradeCost(r)*X.l(r));

);

* Restore Chinese production flexibility
Qs.lo("China") = 0;
Qs.up("China") = +inf;

* ==========================================
* DISPLAY MILESTONE 1 RESULTS
* ==========================================

display baselineChinaProduction;
display targetProduction;
display results;
display welfare;

execute_unload 'graphite_milestone1.gdx',
    results, welfare, targetProduction;

$exit


* ==========================================
* MILESTONE 2: GRAPHITE SUBSTITUTION
* ==========================================

* Natural and synthetic graphite
set g /natural, synthetic/;

* Chinese production expansion scenarios
set china2 /C00, C10, C20, C30, C40/;

parameter chinaPct2(china2)
/
C00 0
C10 0.10
C20 0.20
C30 0.30
C40 0.40
/;

* Synthetic graphite preference scenarios
set syn2 /T00, T10, T20, T30/;

parameter synPct2(syn2)
/
T00 0
T10 0.10
T20 0.20
T30 0.30
/;

* ==========================================
* REFERENCE SUPPLY AND DEMAND
* ==========================================

* Illustrative graphite composition
parameter share2(g)
/
natural 0.70
synthetic 0.30
/;

parameter qbar_s2(r,g);
parameter c2(r,g), d2(r,g);
parameter weight2(g);

qbar_s2(r,g) = qbar_s(r)*share2(g);

* Supply calibration for each product
d2(r,g)$(qbar_s2(r,g)>0) =
    pbar(r)/(e_s*qbar_s2(r,g));

c2(r,g)$(qbar_s2(r,g)>0) =
    pbar(r)-d2(r,g)*qbar_s2(r,g);

* Potential US production costs
c2("USA","natural") = 100;
d2("USA","natural") = 2;

c2("USA","synthetic") = 110;
d2("USA","synthetic") = 2;

* ==========================================
* CES DEMAND FUNCTION
* ==========================================

* Elasticity of substitution = 2
* CES exponent rho = 0.5

scalar epsCES /0.0001/;
scalar weightDenom;

positive variables
    QdCES(r,g)
    QsCES(r,g)
    XCES(r,g)
    GCES(r);

variable WCES;

equations
    cesDemand(r)
    objCES
    marketCES(r,g);

* Composite graphite consumption
cesDemand(r)..
    GCES(r) =e=
    sqr(weight2("natural")*sqrt(QdCES(r,"natural")+epsCES)+weight2("synthetic")*sqrt(QdCES(r,"synthetic")+epsCES));

* Welfare maximization
objCES..
    WCES =e=
    sum(r,
        a(r)*GCES(r)
        + b(r)*sqr(GCES(r))/2
    )
    -
    sum((r,g),
        c2(r,g)*QsCES(r,g)
        + d2(r,g)*sqr(QsCES(r,g))/2
        + tradeCost(r)*XCES(r,g)
    );

* Market clearing for each graphite type
marketCES(r,g)..
    QsCES(r,g)
    + sum(rr$(not sameas(rr,"USA")),XCES(rr,g))
        $sameas(r,"USA")
    =g=
    QdCES(r,g)
    + XCES(r,g)$(not sameas(r,"USA"));

model graphite_CES
/
cesDemand
objCES
marketCES
/;

* ==========================================
* BASELINE SUBSTITUTION EQUILIBRIUM
* ==========================================

* No US domestic production
QsCES.fx("USA",g) = 0;
XCES.fx("USA",g) = 0;

* Initial CES weights
weight2(g) = sqrt(share2(g));

* Initial quantities
QdCES.l(r,g) = qbar_d(r)*share2(g);
QsCES.l(r,g) = qbar_s(r)*share2(g);
GCES.l(r) = qbar_d(r);

solve graphite_CES using NLP maximizing WCES;

abort$(graphite_CES.modelStat <> 1
    and graphite_CES.modelStat <> 2)
    "Milestone 2 baseline did not solve";

scalar baselineChinaNatural;

baselineChinaNatural =
    QsCES.l("China","natural");

* ==========================================
* MILESTONE 2 SCENARIO LOOP
* ==========================================

parameter M2results(china2,syn2,*);

loop(china2,

* Expand Chinese natural graphite production
    QsCES.fx("China","natural") =
        baselineChinaNatural*(1+chinaPct2(china2));

    loop(syn2,

* Change preference for synthetic graphite
        weightDenom = sqrt(
            share2("natural")
            + share2("synthetic")*sqr(1+synPct2(syn2))
        );

        weight2("natural") =
            sqrt(share2("natural"))/weightDenom;

        weight2("synthetic") =
            sqrt(share2("synthetic"))
            *(1+synPct2(syn2))/weightDenom;

* Solve new equilibrium
        solve graphite_CES using NLP maximizing WCES;

        abort$(graphite_CES.modelStat <> 1
            and graphite_CES.modelStat <> 2)
            "Milestone 2 scenario did not solve";

* Save US consumption by graphite type
        M2results(china2,syn2,"US_Natural_Demand") =
            QdCES.l("USA","natural");

        M2results(china2,syn2,"US_Synthetic_Demand") =
            QdCES.l("USA","synthetic");

* Save US equilibrium prices
        M2results(china2,syn2,"US_Natural_Price") =
            max(0,-marketCES.m("USA","natural"));

        M2results(china2,syn2,"US_Synthetic_Price") =
            max(0,-marketCES.m("USA","synthetic"));

* Save Chinese production
        M2results(china2,syn2,"China_Natural_Supply") =
            QsCES.l("China","natural");

        M2results(china2,syn2,"China_Synthetic_Supply") =
            QsCES.l("China","synthetic");

* Save Chinese exports
        M2results(china2,syn2,"China_Natural_Exports") =
            XCES.l("China","natural");

        M2results(china2,syn2,"China_Synthetic_Exports") =
            XCES.l("China","synthetic");

* Save synthetic share of US consumption
        M2results(china2,syn2,"US_Synthetic_Share") =
            QdCES.l("USA","synthetic")
            / max(epsCES,sum(g,QdCES.l("USA",g)));

* Save welfare
        M2results(china2,syn2,"Welfare") = WCES.l;

    );
);

* ==========================================
* FINAL RESULTS
* ==========================================

display baselineChinaNatural;
display M2results;

execute_unload 'graphite_milestone2.gdx',
    M2results;

$exit
