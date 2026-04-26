# pq_lb_cbc

Pacote Julia para análise didática de Liquidity Buffer (LB) e
Counterbalancing Capacity (CBC) em bancos, com base no framework de
Castagna e Fede (2013, *Measuring and Managing Liquidity Risk*, Cap. 7).

Companion code do artigo "Liquidity buffer e counterbalancing capacity:
definições, causas e o frame estrutural" (Pílulas de Quant).

## Escopo

Modela um balanço bancário estilizado e calcula:

- LCR sob o cenário regulatório padrão (BCBS 238).
- Funding gap em 30 dias sob cenários idiossincrático, sistêmico e combinado (BCBS 144 / CEBS 2009).
- Decomposição das saídas líquidas pelas causas econômicas: descasamento de prazos, colateral de derivativos e compromissos off-balance.
- Tamanho do LB pelo cenário binding e composição alocada por nível HQLA.
- Capacidade adicional de geração de liquidez (CBC) via repo, unsecured e venda de ativos.

O pacote é didático. Não substitui ferramentas de produção de tesouraria
(Moody's RiskAuthority, Wolters Kluwer OneSumX, FIS Ambit Liquidity).

## Instalação

```julia
] activate .
] instantiate
```

## Uso mínimo

```julia
using PQLBCBC

bank = Bank(
    name = "Banco Teste",
    cash = 5.0,
    central_bank_reserves = 30.0,
    hqla_level1 = 80.0,
    retail_stable = 100.0,
    retail_less_stable = 60.0,
    wholesale_non_operational = 50.0,
    commit_credit_corporate = 50.0,
    derivatives_vm_30d = 5.0,
)

scenarios = [
    bcbs238_baseline(),
    idiosyncratic_severe(),
    market_severe(),
    combined_severe(),
]

summary_report(bank, scenarios)
```

## Exemplos

- `examples/01_basics.jl`: banco estilizado e relatório completo.
- `examples/02_decomposition.jl`: decomposição das saídas por causa em dois perfis distintos.
- `examples/03_brazilian_bank.jl`: comparação entre composição brasileira (Nível 1 dominante) e europeia (com Nível 2A relevante).

Executar:

```bash
julia examples/01_basics.jl
```

## Testes

```julia
] test
```

## Estrutura

```
src/
  PQLBCBC.jl       # módulo principal
  types.jl         # Bank, StressScenario, LiquidityBuffer, CounterbalancingCapacity
  scenarios.jl     # bcbs238_baseline, idiosyncratic_severe, market_severe, combined_severe
  lb.jl            # hqla_after_haircuts, decompose_outflows_by_cause, lcr, size_liquidity_buffer, build_cbc, summary_report
examples/
  01_basics.jl
  02_decomposition.jl
  03_brazilian_bank.jl
test/
  runtests.jl
```

## Referências

- CASTAGNA, A.; FEDE, F. *Measuring and Managing Liquidity Risk*. Wiley Finance, 2013.
- BCBS. *Principles for Sound Liquidity Risk Management and Supervision* (BCBS 144). Basel: BIS, 2008.
- BCBS. *Basel III: The Liquidity Coverage Ratio and Liquidity Risk Monitoring Tools* (BCBS 238). Basel: BIS, 2013.
- CEBS. *Guidelines on Liquidity Buffers & Survival Periods*. London: CEBS, 2009.
- BANCO CENTRAL DO BRASIL. *Resolução CMN nº 4.401, de 27 de fevereiro de 2015*.

## Licença

MIT.
