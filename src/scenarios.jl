"""
    bcbs238_baseline()

Cenário do LCR padrão Basel III (BCBS 238), com taxas de runoff e drawdown
calibradas para o estresse de 30 dias prescrito pelo regulador.

Referência: BCBS 238, "Basel III: The Liquidity Coverage Ratio and
Liquidity Risk Monitoring Tools", janeiro de 2013.
"""
bcbs238_baseline() = StressScenario(
    name = "BCBS 238 LCR baseline",
    kind = :bcbs238_baseline,
    runoff_retail_stable = 0.03,
    runoff_retail_less_stable = 0.10,
    runoff_wholesale_operational = 0.25,
    runoff_wholesale_non_operational = 0.40,
    runoff_unsecured = 1.00,
    drawdown_credit_retail = 0.05,
    drawdown_credit_corporate = 0.10,
    drawdown_credit_financial = 1.00,
    margin_call_multiplier = 1.0,
)

"""
    idiosyncratic_severe()

Cenário idiossincrático severo (multi-notch downgrade, perda de confiança
no banco). Eleva runoff de varejo e atacado, mas mantém condições de
mercado normais (haircuts regulatórios sem agravamento).

Referência: CEBS Guidelines on Liquidity Buffers (2009), parágrafo 39;
BCBS 144 Princípio 10.
"""
idiosyncratic_severe() = StressScenario(
    name = "Idiossincrático severo",
    kind = :idiosyncratic,
    runoff_retail_stable = 0.05,
    runoff_retail_less_stable = 0.20,
    runoff_wholesale_operational = 0.40,
    runoff_wholesale_non_operational = 0.75,
    runoff_unsecured = 1.00,
    drawdown_credit_retail = 0.10,
    drawdown_credit_corporate = 0.20,
    drawdown_credit_financial = 1.00,
    margin_call_multiplier = 1.5,
    htm_monetizable_fraction = 0.0,
)

"""
    market_severe()

Cenário sistêmico severo (disfunção generalizada de mercados de funding e
de ativos). Mantém runoff em níveis moderados, mas eleva haircuts em
HQLA Nível 2 e fator de margin call em derivativos.

Calibrado em referência aos picos observados no episódio LDI UK (set/2022)
e no dash-for-cash de mar/2020.
"""
market_severe() = StressScenario(
    name = "Sistêmico severo",
    kind = :market,
    runoff_retail_stable = 0.05,
    runoff_retail_less_stable = 0.15,
    runoff_wholesale_operational = 0.30,
    runoff_wholesale_non_operational = 0.50,
    runoff_unsecured = 1.00,
    drawdown_credit_retail = 0.05,
    drawdown_credit_corporate = 0.15,
    drawdown_credit_financial = 1.00,
    extra_haircut_l1 = 0.02,
    extra_haircut_l2a = 0.10,
    extra_haircut_l2b = 0.20,
    margin_call_multiplier = 3.0,
    htm_monetizable_fraction = 0.0,
)

"""
    combined_severe()

Cenário combinado idiossincrático + sistêmico, conforme o BCBS 144
Princípio 10 e o CEBS (2009) prescrevem para dimensionamento do LB.
"""
combined_severe() = StressScenario(
    name = "Combinado severo",
    kind = :combined,
    runoff_retail_stable = 0.07,
    runoff_retail_less_stable = 0.25,
    runoff_wholesale_operational = 0.50,
    runoff_wholesale_non_operational = 0.85,
    runoff_unsecured = 1.00,
    drawdown_credit_retail = 0.15,
    drawdown_credit_corporate = 0.30,
    drawdown_credit_financial = 1.00,
    extra_haircut_l1 = 0.02,
    extra_haircut_l2a = 0.15,
    extra_haircut_l2b = 0.30,
    margin_call_multiplier = 4.0,
    htm_monetizable_fraction = 0.0,
)
