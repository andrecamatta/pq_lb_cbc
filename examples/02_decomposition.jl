# Exemplo 2 — Decomposição do LB pelas causas econômicas
#
# Mostra como a contribuição de cada causa (descasamento de prazos,
# colateral de derivativos, compromissos off-balance) varia entre cenários.
# Útil para entender qual causa domina em cada perfil de banco.

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using PQLBCBC
using Printf

# Dois bancos com perfis distintos
moderate_bank = Bank(
    name = "Banco Moderado",
    cash = 10.0, central_bank_reserves = 20.0, hqla_level1 = 60.0,
    loans = 150.0,
    retail_stable = 90.0, retail_less_stable = 40.0,
    wholesale_operational = 30.0, wholesale_non_operational = 30.0,
    unsecured_short_term = 10.0,
    commit_credit_retail = 20.0, commit_credit_corporate = 30.0,
    derivatives_vm_30d = 2.0,
)

derivatives_heavy_bank = Bank(
    name = "Banco Derivativos-intensivo",
    cash = 8.0, central_bank_reserves = 15.0, hqla_level1 = 40.0,
    hqla_level2a = 10.0,
    loans = 100.0,
    retail_stable = 50.0, retail_less_stable = 20.0,
    wholesale_operational = 25.0, wholesale_non_operational = 35.0,
    unsecured_short_term = 15.0,
    commit_credit_retail = 5.0, commit_credit_corporate = 15.0,
    commit_credit_financial = 10.0,
    derivatives_vm_30d = 25.0,           # exposição material a margin calls
)

# Decomposição sob cenário combinado severo
scenario = combined_severe()

println("Decomposição das saídas líquidas em estresse combinado severo")
println("="^72)

for bank in (moderate_bank, derivatives_heavy_bank)
    decomp = decompose_outflows_by_cause(bank, scenario)
    total = sum(values(decomp))
    @printf "\n%s\n" bank.name
    @printf "  Saídas totais (R\$ bi)        : %8.2f\n" total
    @printf "  Maturity mismatch            : %8.2f (%5.1f%%)\n" decomp[:maturity_mismatch] 100*decomp[:maturity_mismatch]/total
    @printf "  Off-balance commitments      : %8.2f (%5.1f%%)\n" decomp[:off_balance] 100*decomp[:off_balance]/total
    @printf "  Collateral margining         : %8.2f (%5.1f%%)\n" decomp[:collateral] 100*decomp[:collateral]/total
end
