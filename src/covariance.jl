function optim_kernel(k_spatiotemporal::Kernel, logNoise_init::Float64, 
                      stations_data::DataFrame, hourly_data::DataFrame, 
                      method::Symbol=:NLopt; 
                      x_tol=1e-5, f_tol=1e-10)
    chunks=GPE[]
    chunk_width=24*10 # 10 days at a time
    tstart=0.0
    nobsv=0
    max_time = maximum(hourly_data[:ts_hours])
    while tstart < max_time
        tend=tstart+chunk_width
        in_chunk= tstart .<= hourly_data[:ts_hours] .< tend
        hourly_chunk = hourly_data[in_chunk,:]
        nobsv_chunk = sum(in_chunk)
        nobsv += nobsv_chunk

        chunk_X_PRJ = stations_data[:X_PRJ][hourly_chunk[:station]]
        chunk_Y_PRJ = stations_data[:Y_PRJ][hourly_chunk[:station]]
        chunk_X = [hourly_chunk[:ts_hours] chunk_X_PRJ chunk_Y_PRJ]

        y = hourly_chunk[:temp]
        chunk = GPE(chunk_X', y, MeanConst(mean(y)), k_spatiotemporal, logNoise_init)
        push!(chunks, chunk)

        tstart=tend
    end
    reals = TempModel.GPRealisations(chunks)
    local min_neg_ll
    local min_hyp
    local opt_out
    if method == :NLopt
        min_neg_ll, min_hyp, ret, count = TempModel.optimize_NLopt(reals, domean=false, x_tol=x_tol, f_tol=f_tol)
        opt_out = (min_neg_ll, min_hyp, ret, count)
        @assert ret ∈ (:SUCCESS, :FTOL_REACHED, :XTOL_REACHED)
    elseif method == :Optim
        opt_out = TempModel.optimize!(reals, domean=false, 
                                      options=Optim.Options(x_tol=x_tol, f_tol=f_tol)
                                     )
        min_hyp = Optim.minimizer(opt_out)
        min_neg_ll = Optim.minimum(opt_out)
        @assert Optim.converged(opt_out)
    else
        throw(MethodError())
    end
    @assert min_neg_ll ≈ -reals.mll
    return Dict(
        :hyp => min_hyp,
        :logNoise => reals.logNoise,
        :mll => -min_neg_ll,
        :opt_out => opt_out,
       )
end