module OptionPricing

using Reexport
@reexport using Dates
import Statistics: mean

export AmericanOption, Put, simulate_price, price_option, SwingOption, 
SwingContract, Valuation, PriceProcess

abstract type AbstractOption end
abstract type RealOption <:AbstractOption end
abstract type FinancialOption <: AbstractOption end

# Option Types may use Traits
abstract type OptionStyle end
struct Put <: OptionStyle end
struct Call <: OptionStyle end

include("american.jl")
include("swing.jl")


# power_series takes an an array and returns an array with each each 
# value raised to 0 up to order.
function power_series(price::AbstractArray, order::Int)
    return price .^ (0:order)' 
end



end # module


