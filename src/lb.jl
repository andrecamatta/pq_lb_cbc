"""
    hqla_after_haircuts(bank, scenario)

Aplica haircuts regulatórios e os haircuts adicionais do cenário sobre o
estoque de HQLA do banco. Retorna NamedTuple com os componentes Nível 1
(caixa, reservas, demais L1) e Nível 2 (2A com 15% + extra; 2B com 50% +
extra) e o total monetizável após o cap de 40% sobre Nível 2 e 15% sobre
Nível 2B (BCBS 238, parágrafos 49-54).
"""
function hqla_after_haircuts(bank::Bank, scenario::StressScenario)
    h1 = (1 - scenario.extra_haircut_l1)
    cash_eff = bank.cash * h1
    reserves_eff = bank.central_bank_reserves * h1
    l1_eff = bank.hqla_level1 * h1

    l2a_eff = bank.hqla_level2a * (1 - 0.15) * (1 - scenario.extra_haircut_l2a)
    l2b_eff = bank.hqla_level2b * (1 - 0.50) * (1 - scenario.extra_haircut_l2b)

    total_l1 = cash_eff + reserves_eff + l1_eff

    # BCBS 238 §51: cap de Nível 2 = 2/3 de Nível 1 após haircut
    # Cap de Nível 2B = min(15/85 × (L1 + L2A); 1/3 × L1)
    cap_l2 = (2.0 / 3.0) * total_l1
    cap_l2b = min((15.0 / 85.0) * (total_l1 + l2a_eff), (1.0 / 3.0) * total_l1)

    l2b_in_buffer = min(l2b_eff, cap_l2b)
    l2a_in_buffer = min(l2a_eff, cap_l2 - l2b_in_buffer)

    htm_eff = bank.htm_securities * scenario.htm_monetizable_fraction

    total = total_l1 + l2a_in_buffer + l2b_in_buffer + htm_eff

    return (
        cash = cash_eff,
        reserves = reserves_eff,
        level1 = l1_eff,
        level2a = l2a_in_buffer,
        level2b = l2b_in_buffer,
        htm = htm_eff,
        total = total,
    )
end

"""
    net_cash_outflows(bank, scenario)

Calcula as saídas líquidas de caixa em 30 dias sob o cenário. Retorna o
total agregado. Para a quebra por causa, ver `decompose_outflows_by_cause`.

A modelagem segue a estrutura do BCBS 238 com inflows assumidos zero
(simplificação compatível com o cap de 75% sobre outflows do LCR).
"""
function net_cash_outflows(bank::Bank, scenario::StressScenario)
    components = decompose_outflows_by_cause(bank, scenario)
    return sum(values(components))
end

"""
    decompose_outflows_by_cause(bank, scenario)

Decompõe as saídas líquidas em três causas econômicas (Castagna e Fede,
2013, Cap. 7):

- `:maturity_mismatch`: runoff de depósitos varejo, atacado e dívida unsecured.
- `:off_balance`: drawdown de linhas de crédito comprometidas.
- `:collateral`: chamadas de margem em derivativos.

Retorna `Dict{Symbol, Float64}` com as três contribuições.
"""
function decompose_outflows_by_cause(bank::Bank, scenario::StressScenario)
    mm = bank.retail_stable * scenario.runoff_retail_stable +
         bank.retail_less_stable * scenario.runoff_retail_less_stable +
         bank.wholesale_operational * scenario.runoff_wholesale_operational +
         bank.wholesale_non_operational * scenario.runoff_wholesale_non_operational +
         bank.unsecured_short_term * scenario.runoff_unsecured

    obs = bank.commit_credit_retail * scenario.drawdown_credit_retail +
          bank.commit_credit_corporate * scenario.drawdown_credit_corporate +
          bank.commit_credit_financial * scenario.drawdown_credit_financial

    col = bank.derivatives_vm_30d * scenario.margin_call_multiplier

    return Dict(
        :maturity_mismatch => mm,
        :off_balance => obs,
        :collateral => col,
    )
end

"""
    lcr(bank, scenario = bcbs238_baseline())

Liquidity Coverage Ratio sob um cenário. Convencionalmente o LCR é
calculado com o cenário `bcbs238_baseline`; com outros cenários a função
permite avaliar a sensibilidade do indicador a estresses mais severos.
"""
function lcr(bank::Bank, scenario::StressScenario = bcbs238_baseline())
    hqla = hqla_after_haircuts(bank, scenario)
    outflows = net_cash_outflows(bank, scenario)
    return hqla.total / outflows
end

"""
    size_liquidity_buffer(bank, scenarios; survival_period_days = 30)

Dimensiona o LB pelo pior funding gap entre os cenários considerados.
Implementa a Definição 7.2.2 de Castagna e Fede (2013): o LB é o
estoque que cobre a necessidade adicional sob estresse, no horizonte de
sobrevivência escolhido.

# Argumentos
- `bank::Bank`: balanço estilizado.
- `scenarios::Vector{StressScenario}`: cenários (idiossincrático, sistêmico, combinado).
- `survival_period_days`: horizonte (padrão 30 dias do LCR).

Retorna um `LiquidityBuffer` com tamanho igual ao máximo das saídas
líquidas e composição alocada na ordem de prioridade caixa → reservas →
Nível 1 → 2A → 2B (até o limite do estoque do banco).
"""
function size_liquidity_buffer(
    bank::Bank,
    scenarios::Vector{StressScenario};
    survival_period_days::Int = 30,
)
    binding = argmax(scenarios) do s
        net_cash_outflows(bank, s)
    end
    target_size = net_cash_outflows(bank, binding)

    remaining = target_size
    cash_alloc = min(remaining, bank.cash); remaining -= cash_alloc
    reserves_alloc = min(remaining, bank.central_bank_reserves); remaining -= reserves_alloc
    l1_alloc = min(remaining, bank.hqla_level1); remaining -= l1_alloc

    l2a_haircut = (1 - 0.15) * (1 - binding.extra_haircut_l2a)
    l2a_needed = remaining > 0 ? remaining / l2a_haircut : 0.0
    l2a_alloc_face = min(l2a_needed, bank.hqla_level2a)
    l2a_alloc_eff = l2a_alloc_face * l2a_haircut
    remaining -= l2a_alloc_eff

    l2b_haircut = (1 - 0.50) * (1 - binding.extra_haircut_l2b)
    l2b_needed = remaining > 0 ? remaining / l2b_haircut : 0.0
    l2b_alloc_face = min(l2b_needed, bank.hqla_level2b)
    l2b_alloc_eff = l2b_alloc_face * l2b_haircut

    return LiquidityBuffer(
        size = target_size,
        survival_period_days = survival_period_days,
        cash = cash_alloc,
        central_bank_reserves = reserves_alloc,
        level1 = l1_alloc,
        level2a = l2a_alloc_face,
        level2b = l2b_alloc_face,
    )
end

"""
    build_cbc(bank, scenarios; survival_period_days = 30)

Monta a CounterbalancingCapacity com o LB dimensionado e estimativas de
capacidade incremental via repo (Nível 2 não usado no LB), unsecured
(zero em cenário severo) e venda de ativos não-buffer (haircut de
fire-sale de 30% sobre HTM e empréstimos).
"""
function build_cbc(
    bank::Bank,
    scenarios::Vector{StressScenario};
    survival_period_days::Int = 30,
    fire_sale_haircut::Float64 = 0.30,
)
    lb = size_liquidity_buffer(bank, scenarios; survival_period_days = survival_period_days)

    repo_capacity = (bank.hqla_level2a - lb.level2a) * 0.85 +
                    (bank.hqla_level2b - lb.level2b) * 0.50

    unsecured_capacity = 0.0
    asset_sale_capacity = (bank.htm_securities + bank.loans) * (1 - fire_sale_haircut) * 0.10

    return CounterbalancingCapacity(
        liquidity_buffer = lb,
        secured_funding_capacity = max(repo_capacity, 0.0),
        unsecured_funding_capacity = unsecured_capacity,
        asset_sale_capacity = asset_sale_capacity,
    )
end

"""
    summary_report(bank, scenarios)

Imprime um relatório formatado com LCR sob cada cenário, decomposição
das saídas por causa, tamanho do LB binding e composição da CBC.
"""
function summary_report(bank::Bank, scenarios::Vector{StressScenario})
    println("="^72)
    println("Relatório de Liquidez — $(bank.name)")
    println("="^72)

    for s in scenarios
        outflows = decompose_outflows_by_cause(bank, s)
        total = sum(values(outflows))
        hqla = hqla_after_haircuts(bank, s)
        ratio = hqla.total / total

        @printf "\nCenário: %s\n" s.name
        @printf "  HQLA monetizável        : %10.2f\n" hqla.total
        @printf "  Saídas líquidas (30d)   : %10.2f\n" total
        @printf "    Maturity mismatch     : %10.2f (%5.1f%%)\n" outflows[:maturity_mismatch] 100*outflows[:maturity_mismatch]/total
        @printf "    Off-balance-sheet     : %10.2f (%5.1f%%)\n" outflows[:off_balance] 100*outflows[:off_balance]/total
        @printf "    Collateral margining  : %10.2f (%5.1f%%)\n" outflows[:collateral] 100*outflows[:collateral]/total
        @printf "  Razão de cobertura      : %10.2f%%\n" 100*ratio
    end

    cbc = build_cbc(bank, scenarios)
    println("\n" * "-"^72)
    println("Liquidity Buffer (binding):")
    @printf "  Tamanho               : %10.2f\n" cbc.liquidity_buffer.size
    @printf "  Survival period       : %10d dias\n" cbc.liquidity_buffer.survival_period_days
    println("\nComposição:")
    @printf "  Caixa                 : %10.2f\n" cbc.liquidity_buffer.cash
    @printf "  Reservas no BC        : %10.2f\n" cbc.liquidity_buffer.central_bank_reserves
    @printf "  HQLA Nível 1 demais   : %10.2f\n" cbc.liquidity_buffer.level1
    @printf "  HQLA Nível 2A         : %10.2f\n" cbc.liquidity_buffer.level2a
    @printf "  HQLA Nível 2B         : %10.2f\n" cbc.liquidity_buffer.level2b

    println("\nCounterbalancing Capacity (camadas adicionais):")
    @printf "  Capacidade repo extra : %10.2f\n" cbc.secured_funding_capacity
    @printf "  Capacidade unsecured  : %10.2f\n" cbc.unsecured_funding_capacity
    @printf "  Venda de ativos       : %10.2f\n" cbc.asset_sale_capacity
    println("="^72)
    return cbc
end
