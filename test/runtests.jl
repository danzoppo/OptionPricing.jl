using OptionPricing
using Test

const op = OptionPricing

# model assumptions
const runs = 10_000
const order = 5

swing = SwingOption(PriceProcess(3.9, 1.2,0.59,1.7,0.01),
    SwingContract(Date(2014,Jun,1),Date(2015,Jun,1),4.69,5,10_000, 2_500,15_000),
    Valuation(5,100_000)
)
simulate_price(swing)

@testset "OptionPricing.jl" begin
    # Write your tests here.
   @testset "American Options" begin 
        option = AmericanOption(36.0,40.0,0.06,0.0,0.20,1.0,51, Put())
        price_option(option; runs = 100_000, order = order)
   end

end
