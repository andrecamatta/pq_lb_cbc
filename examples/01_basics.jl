# Exemplo 1 — Definição de banco estilizado e cálculo do Liquidity Buffer
#
# Este exemplo segue o frame de Castagna & Fede (2013, Cap. 7) e a
# parametrização do BCBS 238. Os valores estão em R$ bilhões e refletem
# a ordem de grandeza de um banco médio brasileiro do segmento S1.

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PQLBCBC

# Banco estilizado com perfil de funding diversificado e exposição moderada
# a derivativos e linhas comprometidas
pq_bank = Bank(
    name = "PQ Bank Brasil",
    cash = 5.0,
    central_bank_reserves = 30.0,
    hqla_level1 = 80.0,         # majoritariamente LFT/NTN
    hqla_level2a = 5.0,
    hqla_level2b = 0.0,
    htm_securities = 50.0,      # carteira HTM com unrealized loss
    loans = 200.0,
    retail_stable = 100.0,
    retail_less_stable = 60.0,
    wholesale_operational = 40.0,
    wholesale_non_operational = 50.0,
    secured_funding = 30.0,
    unsecured_short_term = 20.0,
    commit_credit_retail = 30.0,
    commit_credit_corporate = 50.0,
    commit_credit_financial = 5.0,
    derivatives_vm_30d = 5.0,
)

# Conjunto de cenários para dimensionamento
scenarios = [
    bcbs238_baseline(),
    idiosyncratic_severe(),
    market_severe(),
    combined_severe(),
]

# Relatório completo
cbc = summary_report(pq_bank, scenarios)

# LCR sob o cenário regulatório padrão
println("\nLCR (BCBS 238 baseline) = ", round(100 * lcr(pq_bank), digits = 1), "%")
