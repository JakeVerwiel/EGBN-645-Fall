set r /USA, China, ROW/ ; 

set year /2020*2025/;

parameter
pbar(r),
qbar_s(r) /USA 0, CHINA 37.95, ROW 62.05/,
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

