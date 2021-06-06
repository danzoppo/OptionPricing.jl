# American Option pricing with Least Squares Monte Carlo simulation.

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

function price_option(opt::AmericanOption; runs::Int = 10_000, order::Int = 3)
    # Initialize 
    stepsize = opt.maturity / opt.epochs
    discount_rate = exp(-1.0 * opt.riskfree * stepsize)

    # Initial value function matrix with the simulated prices.
    val_matrix = simulate_price(opt; runs = runs)

    # Terminal Value
    val_matrix[:,end] .= max.(opt.strike .- val_matrix[:,end], 0.0)

    # Value Iteration
    for epoch in (opt.epochs-1):-1:1
        prices = @view val_matrix[:, epoch]
        exercise_vals = max.(opt.strike .- prices, 0.0)
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

function exercise_value(opt::AmericanOption, price)
end

function exercise_value(price::AbstractFloat, strike::AbstractFloat, type::)

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