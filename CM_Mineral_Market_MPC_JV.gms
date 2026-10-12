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
* SCENARIO 2: US ENTRY + CHINESE SUPPLY SHOCK
* ==========================================

* Allow the US company to produce graphite
Qs.lo("USA") = 0;
Qs.up("USA") = +inf;

* China expands supply by lowering marginal cost
c("China") = c("China") - 30;

* Solve the new welfare equilibrium
solve simple using QCP maximizing W;

* Initialize MCP prices
P.l(r) = max(0, -market_clearing.m(r));

* Solve new market equilibrium
solve graphite_mcp using MCP;

* Save second scenario results
results("US_China_Response","Price",r)   = P.l(r);
results("US_China_Response","Demand",r)  = Qd.l(r);
results("US_China_Response","Supply",r)  = Qs.l(r);
results("US_China_Response","Exports",r) = X.l(r);

welfare("US_China_Response") =
    sum(r,
        a(r)*Qd.l(r) + b(r)*sqr(Qd.l(r))/2
        - c(r)*Qs.l(r) - d(r)*sqr(Qs.l(r))/2
    )
    - sum(r, tradeCost(r)*X.l(r));

* Compare both scenarios
display results, welfare;

execute_unload 'graphite_scenarios.gdx', results, welfare;

$exit