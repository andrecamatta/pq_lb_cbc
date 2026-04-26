using Test
using PQLBCBC

@testset "PQLBCBC" begin

    @testset "Construção de tipos" begin
        bank = Bank(name = "Test", cash = 10.0)
        @test bank.name == "Test"
        @test bank.cash == 10.0
        @test bank.hqla_level1 == 0.0

        s = bcbs238_baseline()
        @test s.kind == :bcbs238_baseline
        @test s.runoff_retail_stable == 0.03
    end

    @testset "HQLA com haircuts" begin
        bank = Bank(
            name = "Test",
            cash = 10.0,
            hqla_level1 = 50.0,
            hqla_level2a = 20.0,
        )
        s = bcbs238_baseline()
        hqla = hqla_after_haircuts(bank, s)
        @test hqla.cash == 10.0
        @test hqla.level1 == 50.0
        @test hqla.level2a ≈ 20.0 * 0.85
        @test hqla.total > 0
    end

    @testset "Cap de Nível 2 (40%)" begin
        bank = Bank(
            name = "Heavy L2",
            hqla_level1 = 10.0,
            hqla_level2a = 100.0,
        )
        s = bcbs238_baseline()
        hqla = hqla_after_haircuts(bank, s)
        # Total HQLA não pode ter mais de 40% em Nível 2
        @test hqla.level2a + hqla.level2b ≤ hqla.total * 0.40 + 1e-6
    end

    @testset "Decomposição soma ao total" begin
        bank = Bank(
            name = "Test",
            retail_less_stable = 100.0,
            wholesale_non_operational = 50.0,
            commit_credit_corporate = 30.0,
            derivatives_vm_30d = 10.0,
        )
        s = combined_severe()
        decomp = decompose_outflows_by_cause(bank, s)
        total = sum(values(decomp))
        @test total ≈ net_cash_outflows(bank, s)
        @test decomp[:maturity_mismatch] > 0
        @test decomp[:off_balance] > 0
        @test decomp[:collateral] > 0
    end

    @testset "LCR > 100% para banco bem capitalizado" begin
        bank = Bank(
            name = "Healthy",
            cash = 50.0,
            central_bank_reserves = 50.0,
            hqla_level1 = 100.0,
            retail_stable = 100.0,
            retail_less_stable = 30.0,
            wholesale_operational = 20.0,
            wholesale_non_operational = 10.0,
        )
        @test lcr(bank) > 1.0
    end

    @testset "Sizing do LB usa cenário binding" begin
        bank = Bank(
            name = "Test",
            cash = 100.0,
            hqla_level1 = 200.0,
            retail_less_stable = 50.0,
            wholesale_non_operational = 50.0,
        )
        scenarios = [bcbs238_baseline(), idiosyncratic_severe(), combined_severe()]
        lb = size_liquidity_buffer(bank, scenarios)
        # O cenário combinado severo gera o maior gap
        @test lb.size == net_cash_outflows(bank, combined_severe())
    end

end
