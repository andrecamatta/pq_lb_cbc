"""
    Bank

Balanço estilizado de um banco para análise de Liquidity Buffer.

Todos os valores em unidades monetárias (u.m.). Os campos seguem o frame
de Castagna e Fede (2013, Cap. 7) e a separação Pillar 3 entre HQLA por
nível, fontes de funding por contraparte e compromissos off-balance.

# Campos
- `name`: identificação do banco
- Liquidez intrínseca:
    - `cash`: caixa (HQLA Nível 1)
    - `central_bank_reserves`: reservas no banco central (HQLA Nível 1)
    - `hqla_level1`: títulos públicos federais e equivalentes (sem haircut)
    - `hqla_level2a`: covered/corporate AA-, haircut 15%, cap conjunto 40%
    - `hqla_level2b`: RMBS, equities, BBB corp, haircut 25-50%, cap 15%
- Ativos não-buffer:
    - `htm_securities`: held-to-maturity, com loss recognition lag (não contam para LCR)
    - `loans`: ativos de crédito não-líquidos
- Funding:
    - `retail_stable`: depósitos cobertos por seguro e relacionamento estável
    - `retail_less_stable`: depósitos sem cobertura completa ou relacionamento curto
    - `wholesale_operational`: depósitos de clientes corporativos com operações de cash management
    - `wholesale_non_operational`: depósitos atacado sem componente operacional
    - `secured_funding`: repo e similares colateralizados
    - `unsecured_short_term`: dívida unsecured com vencimento ≤30 dias
- Off-balance:
    - `commit_credit_retail`: linhas de crédito comprometidas a varejo
    - `commit_credit_corporate`: linhas a corporates não-financeiros
    - `commit_credit_financial`: linhas a contrapartes financeiras
- Derivativos:
    - `derivatives_vm_30d`: chamada de margem variation potencial em 30 dias (estimada por VaR de cenário stressado)
"""
Base.@kwdef struct Bank
    name::String

    cash::Float64 = 0.0
    central_bank_reserves::Float64 = 0.0
    hqla_level1::Float64 = 0.0
    hqla_level2a::Float64 = 0.0
    hqla_level2b::Float64 = 0.0

    htm_securities::Float64 = 0.0
    loans::Float64 = 0.0

    retail_stable::Float64 = 0.0
    retail_less_stable::Float64 = 0.0
    wholesale_operational::Float64 = 0.0
    wholesale_non_operational::Float64 = 0.0
    secured_funding::Float64 = 0.0
    unsecured_short_term::Float64 = 0.0

    commit_credit_retail::Float64 = 0.0
    commit_credit_corporate::Float64 = 0.0
    commit_credit_financial::Float64 = 0.0

    derivatives_vm_30d::Float64 = 0.0
end

"""
    StressScenario

Cenário de estresse do BCBS 144 (idiossincrático, sistêmico ou combinado).

Encapsula taxas de runoff, drawdown, haircuts e fator de margin call que
parametrizam o cálculo do funding gap em 30 dias.

# Campos
- `name`: identificação do cenário
- `kind`: `:bcbs238_baseline`, `:idiosyncratic`, `:market`, `:combined`
- Runoffs (fração que evapora em 30 dias):
    - `runoff_retail_stable`, `runoff_retail_less_stable`
    - `runoff_wholesale_operational`, `runoff_wholesale_non_operational`
    - `runoff_unsecured`
- Drawdowns de linhas comprometidas:
    - `drawdown_credit_retail`, `drawdown_credit_corporate`, `drawdown_credit_financial`
- Haircuts adicionais sobre HQLA (acima dos haircuts regulatórios padrão):
    - `extra_haircut_l1`, `extra_haircut_l2a`, `extra_haircut_l2b`
- `margin_call_multiplier`: multiplicador sobre `derivatives_vm_30d`
- `htm_monetizable_fraction`: fração da carteira HTM que o banco consegue mobilizar (tipicamente 0 em estresse com unrealized loss)
"""
Base.@kwdef struct StressScenario
    name::String
    kind::Symbol = :combined

    runoff_retail_stable::Float64 = 0.03
    runoff_retail_less_stable::Float64 = 0.10
    runoff_wholesale_operational::Float64 = 0.25
    runoff_wholesale_non_operational::Float64 = 0.40
    runoff_unsecured::Float64 = 1.00

    drawdown_credit_retail::Float64 = 0.05
    drawdown_credit_corporate::Float64 = 0.10
    drawdown_credit_financial::Float64 = 1.00

    extra_haircut_l1::Float64 = 0.0
    extra_haircut_l2a::Float64 = 0.0
    extra_haircut_l2b::Float64 = 0.0

    margin_call_multiplier::Float64 = 1.0
    htm_monetizable_fraction::Float64 = 0.0
end

"""
    LiquidityBuffer

Estoque dedicado de ativos líquidos elegíveis para cobrir o funding gap
no horizonte de sobrevivência. Segue as três features do CEBS (2009):
tamanho, survival period e composição.

A composição é desagregada por origem (caixa, reservas, Nível 1, 2A, 2B)
para permitir cálculo de custo de carrego e diagnóstico de concentração.
"""
Base.@kwdef struct LiquidityBuffer
    size::Float64
    survival_period_days::Int = 30
    cash::Float64 = 0.0
    central_bank_reserves::Float64 = 0.0
    level1::Float64 = 0.0
    level2a::Float64 = 0.0
    level2b::Float64 = 0.0
end

"""
    CounterbalancingCapacity

Conjunto amplo de fontes de geração de liquidez que sustenta o banco em
estresse. O LB é a ponta curta da CBC (CEBS 2009, ECB ILAAP 2018).

# Componentes
- `liquidity_buffer`: ativos líquidos dedicados (curto prazo, monetizáveis)
- `secured_funding_capacity`: capacidade adicional de levantar repo (médio prazo)
- `unsecured_funding_capacity`: capacidade unsecured (tipicamente zero em estresse severo)
- `asset_sale_capacity`: venda outright de ativos não-buffer (longo prazo, sujeito a fire-sale)
"""
Base.@kwdef struct CounterbalancingCapacity
    liquidity_buffer::LiquidityBuffer
    secured_funding_capacity::Float64 = 0.0
    unsecured_funding_capacity::Float64 = 0.0
    asset_sale_capacity::Float64 = 0.0
end
