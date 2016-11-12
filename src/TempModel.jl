module TempModel
    using GaussianProcesses
    using PDMats
    using Optim
    using Mamba
    using Stan
    include("GPrealisations.jl")
    include("utils.jl")
    include("preprocessing.jl")
    include("predict_from_nearby.jl")
    include("stan_impute.jl")
end
