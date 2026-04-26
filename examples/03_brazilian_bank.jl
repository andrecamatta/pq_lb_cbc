# Exemplo 3 — Particularidades do balanço brasileiro
#
# Banco brasileiro estilizado refletindo:
# - HQLA quase 100% Nível 1 (LFT, NTN, reservas no BCB)
# - Compulsório remunerado computado como Nível 1 (até 15% do total Nível 1, Voto BCB 38/2020)
# - Ausência de Nível 2 material (mercado escasso de bonds corporativos AA-)
# - Funding majoritariamente retail e atacado doméstico
#
# Compara com um banco europeu hipotético com Nível 2A relevante.

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PQLBCBC

# Banco brasileiro (perfil S1 médio em R$ bilhões)
br_bank = Bank(
    name = "Banco Brasileiro S1",
    cash = 8.0,
    central_bank_reserves = 50.0,    # inclui parcela do compulsório elegível
    hqla_level1 = 120.0,             # LFT majoritário
    hqla_level2a = 0.0,
    hqla_level2b = 0.0,
    loans = 280.0,
    retail_stable = 150.0,
    retail_less_stable = 70.0,
    wholesale_operational = 50.0,
    wholesale_non_operational = 60.0,
    secured_funding = 40.0,
    unsecured_short_term = 25.0,
    commit_credit_retail = 40.0,
    commit_credit_corporate = 60.0,
    commit_credit_financial = 8.0,
    derivatives_vm_30d = 4.0,
)

# Banco europeu hipotético com mesmo tamanho mas composição mais diversa
eu_bank = Bank(
    name = "EU Bank (hipotético)",
    cash = 8.0,
    central_bank_reserves = 30.0,
    hqla_level1 = 80.0,
    hqla_level2a = 50.0,             # covered/corporate AA-
    hqla_level2b = 10.0,
    loans = 280.0,
    retail_stable = 120.0,
    retail_less_stable = 90.0,
    wholesale_operational = 50.0,
    wholesale_non_operational = 70.0,
    secured_funding = 40.0,
    unsecured_short_term = 25.0,
    commit_credit_retail = 30.0,
    commit_credit_corporate = 70.0,
    commit_credit_financial = 8.0,
    derivatives_vm_30d = 4.0,
)

scenarios = [
    bcbs238_baseline(),
    market_severe(),       # cenário onde extra haircut em Nível 2 importa
    combined_severe(),
]

for bank in (br_bank, eu_bank)
    println("\n\n>>> ", bank.name, " <<<")
    summary_report(bank, scenarios)
end

println("\n\nComparativo de LCR sob cenário sistêmico severo:")
println("  Banco brasileiro: ", round(100 * lcr(br_bank, market_severe()), digits = 1), "%")
println("  EU bank        : ", round(100 * lcr(eu_bank, market_severe()), digits = 1), "%")
println("\nNota: o banco brasileiro mantém razão de cobertura mais estável")
println("sob estresse de mercado por concentração em Nível 1 sem haircut.")
println("O custo é a exposição estrutural a risco soberano (doom loop).")
