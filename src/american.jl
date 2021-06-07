# American Option pricing with Least Squares Monte Carlo simulation.

"""
    AmericanOption{R<:AbstractFloat, S<:OptionStyle} <: FinancialOption

AmericanOption is a struct holding the attributes of an american option. 
"""
struct AmericanOption{R<:AbstractFloat, S<:OptionStyle} <: FinancialOption
    initialprice::R
    strike::R
    riskfree::R
    dividend_yield::R
    volatility::R
    maturity::R
    epochs::Int # The number of exercise points
    style::S
end

"""
    price_option(opt::AmericanOption; runs::Int = 10_000, order::Int = 3)

price_option calls the simulation of the geometric Brownian motion process 
and uses the LSM algorithm to value the option.
"""
function price_option(opt::AmericanOption; runs::Int = 10_000, order::Int = 3)
    # Initialize 
    stepsize = opt.maturity / opt.epochs
    discount_rate = exp(-1.0 * opt.riskfree * stepsize)

    # Initial value function matrix with the simulated prices.
    val_matrix = simulate_price(opt; runs = runs)

    # Terminal Value
    val_matrix[:,end] .= exercise_value(opt, val_matrix[:,end])

    # Value Iteration
    @inbounds for epoch in (opt.epochs-1):-1:1
        prices = @view val_matrix[:, epoch]
        exercise_vals = exercise_value(opt, prices)
        discounted_vals = discount_rate * val_matrix[:,epoch+1]

        # Power series matrix for regression
        power_matrix = power_series(prices, order)
        reg_coeff = power_matrix \ discounted_vals

        # Expected continuation val_matrix
        continue_vals = power_matrix * reg_coeff

        # Decision and period val_matrix
        val_matrix[:,epoch] .= (exercise_vals .>= continue_vals) .* exercise_vals + 
                           (exercise_vals .< continue_vals) .* discounted_vals
    end
    return mean(discount_rate * val_matrix[:,1])
end

"exercise_value returns the option return based on the simulated price depending on whether a put or a call"
function exercise_value(opt::AmericanOption, price::AbstractArray)
    retval = similar(price)
    @inbounds for i in 1:length(price)
        retval[i] = exercise_value(price[i], opt.strike, opt.style)
    end
    return retval
end

function exercise_value(price::T, strike::T, style::Put) where {T<:AbstractFloat}
    return max(strike - price, zero(T))
end

function exercise_value(price::T, strike::T, style::Call) where {T<:AbstractFloat}
    return max(price - strike, zero(T))
end

"simulate_price returns a matrix of asset prices"
function simulate_price(opt::AmericanOption; runs::Int = 10_000)
    # Set step size 
    stepsize = opt.maturity / opt.epochs

    # Initialize return val_matrix
    retval = zeros(runs, opt.epochs)

    # Simulate runs as rows so that the LSM algorithm has access to adjacent
    # data across different runs when executing the regression.
    for run in 1:runs, epoch in 1:opt.epochs
        last_price = epoch == 1 ? opt.initialprice : retval[run,epoch-1]
        price = last_price * exp( (opt.riskfree - opt.dividend_yield - opt.volatility^2 / 2) * 
                stepsize + opt.volatility * sqrt(stepsize) * randn())
        retval[run,epoch] = price
    end
    return retval
end