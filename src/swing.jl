# Swing Option pricing for natural gas resources using LSM.




struct PriceProcess{T<:AbstractFloat}
    initialprice::T
    mean_reversion_rate::T 
    volatility::T 
    mean_reversion_level::T 
    riskfree::T
end

struct SwingContract{I<:Integer,R<:AbstractFloat}
    settlement::Date 
    maturity::Date 
    strike::R
    max_rights::I
    daily_contract::I
    min_contract::I
    max_contract::I
end

struct Valuation
    order::Int
    runs::Int
end
struct SwingOption
    process::PriceProcess
    contract::SwingContract
    val::Valuation
end

function price_option(opt::SwingOption)
    # Discount Factor
    days = Dates.value(opt.contract.maturity - opt.contract.settlement)
    stepsize = 1.0 / days
    discount_rate = exp(-opt.process.riskfree * stepsize)

    # Swing inventory values in MMBtu
    swingup = opt.contract.max_contract - opt.contract.daily_contract
    swingdown = opt.contract.min_contract - opt.contract.daily_contract

    # Initialize retval with the simulated prices. Note that retval is 3D.
    retval = zeros(runs,days,opt.contract.max_rights)
    prices = simulate_price(opt)

    # Obtain price spread between strike and simulated prices
    retval .=  prices .- opt.contract.strike

    # Obtain exercise values for each run and day 
    retval .= (retval .> 0.0) .* swingup .* retval .+ (retval .<= 0.0) .* swingdown .* retval

    # value iteration. Termainal value set by the exercise values above.
    @inbounds for epoch in (days-1):-1:1
        for right in 1:opt.contract.max_rights
            exercise_vals = @view retval[:,epoch,right]
            discounted_vals = discount_rate * retval[:,epoch+1,right]

            # power series matrix for regression and coefficients
            power_matrix = power_series(prices,opt.val.order)
            reg_coeff = power_matrix \ discounted_vals

            # Expected continuation values
            continue_vals = power_matrix * reg_coeff

            # next_continue_vals are the continuation values after exercise
            next_continue_vals = right == 1 ? zeros(length(continue_vals)) : retval[:,epoch,right-1]

            # Decision 
            retval[:, epoch, right] .= 


        end



    end




end


function simulate_price(opt::SwingOption)
    # Rename with locals option assumptions
    mean_rev_speed = opt.process.mean_reversion_rate
    mean_rev_level = opt.process.mean_reversion_level
    vol = opt.process.volatility
    runs = opt.val.runs

    # Initialize stepsize
    days = Dates.value(opt.contract.maturity - opt.contract.settlement)
    stepsize = 1.0 / days

    # Initialize retval 
    retval = zeros(runs,days)
    initial_logprice = log(opt.process.initialprice)

    # Simulate paths along rows of log-prices
    for run in 1:runs, epoch in 1:days
        last_price = epoch == 1 ? initial_logprice : retval[run,epoch-1]
        logprice = last_price + mean_rev_speed*(mean_rev_level-last_price)*stepsize +
                    vol * sqrt(stepsize) * randn()
        retval[run,epoch] = logprice
    end
    return exp.(retval)
end


