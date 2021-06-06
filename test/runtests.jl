using OptionPricing
using Test

const op = OptionPricing

# model assumptions
const runs = 10_000
const order = 5

option = AmericanOption(36.0,40.0,0.06,0.0,0.20,1.0,51)
simulate_price(option)
price_option(option; runs = 100_000, order = order)

@testset "OptionPricing.jl" begin
    # Write your tests here.
end
