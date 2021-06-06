using OptionPricing
using Test

const op = OptionPricing

# model assumptions
const runs = 10_000
const order = 5

option = AmericanOption(36.0,40.0,0.06,0.0,0.20,1.0,51, Put())
simulate_price(option)
price_option(option; runs = 100_000, order = order)
op.exercise_value(option, 37.0)
x = [rand(30.0:50.0) for i in 1:10]
op.exercise_value(option, x)
op.exercise_value(20.0, 12.0, Put())

@testset "OptionPricing.jl" begin
    # Write your tests here.
end
