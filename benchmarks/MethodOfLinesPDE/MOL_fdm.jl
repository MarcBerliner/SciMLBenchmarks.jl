"""
---
title: Burgers FDM Work-Precision Diagrams with Various MethodOfLines Methods
author: Alex Jones
---
"""
# This benchmark is for the MethodOfLines package, which is an automatic PDE discretization package.
# It is concerned with comparing the performance of various discretization methods for the Burgers equation.

using MethodOfLines, DomainSets, OrdinaryDiffEq, ModelingToolkit, DiffEqDevTools, LinearAlgebra,
      LinearSolve, Plots
# Note: ModelingToolkit is held at v8.22.1, as somewhere between this and v8.29.1 a bug was introduced that breaks this benchmark.
# See MethodOfLines/#194 for more information.

#Here is the burgers equation with a Dirichlet and Neumann boundary conditions,
# pdesys1 has Dirichlet BCs, pdesys2 has Neumann BCs


const N = 30

@parameters x t
@variables u(..)
Dx = Differential(x)
Dt = Differential(t)
x_min = 0.0
x_max = 1.0
t_min = 0.0
t_max = 20.0

solver = FBDF()

analytic_u(t, x) = x / (t + 1)

analytic = [u(t, x) => analytic_u]

eq = Dt(u(t, x)) ~ -u(t, x) * Dx(u(t, x))

bcs1 = [u(0, x) ~ x,
    u(t, x_min) ~ analytic_u(t, x_min),
    u(t, x_max) ~ analytic_u(t, x_max)]

bcs2 = [u(0, x) ~ x,
    Dx(u(t, x_min)) ~ 1 / (t + 1),
    Dx(u(t, x_max)) ~ 1 / (t + 1)]

domains = [t ∈ Interval(t_min, t_max),
    x ∈ Interval(x_min, x_max)]

@named pdesys1 = PDESystem(eq, bcs1, domains, [t, x], [u(t, x)])
@named pdesys2 = PDESystem(eq, bcs2, domains, [t, x], [u(t, x)])

# Here is a uniform discretization with the Upwind scheme:

discupwind1 = MOLFiniteDifference([x => N], t, advection_scheme=UpwindScheme())
discupwind2 = MOLFiniteDifference([x => N-1], t, advection_scheme=UpwindScheme(), grid_align=edge_align)


# Here is a uniform discretization with the WENO scheme:

discweno1 = MOLFiniteDifference([x => N], t, advection_scheme=WENOScheme())
discweno2 = MOLFiniteDifference([x => N-1], t, advection_scheme=WENOScheme(), grid_align=edge_align)

# Here is a non-uniform discretization with the Upwind scheme, using tanh (nonuniform WENO is not implemented yet):
gridf(x) = tanh.(x) ./ 2 .+ 0.5
gridnu1 = gridf(vcat(-Inf, range(-3.0, 3.0, length=N-2), Inf))
gridnu2 = gridf(vcat(-Inf, range(-3.0, 3.0, length=N - 3), Inf))

discnu1 = MOLFiniteDifference([x => gridnu1], t, advection_scheme=UpwindScheme())
discnu2 = MOLFiniteDifference([x => gridnu2], t, advection_scheme=UpwindScheme(), grid_align=edge_align)

# Here are the problems for pdesys1:
probupwind1 = discretize(pdesys1, discupwind1; analytic=analytic)
probupwind2 = discretize(pdesys1, discupwind2; analytic=analytic)

probweno1 = discretize(pdesys1, discweno1; analytic=analytic)
probweno2 = discretize(pdesys1, discweno2; analytic=analytic)

probnu1 = discretize(pdesys1, discnu1; analytic=analytic)
probnu2 = discretize(pdesys1, discnu2; analytic=analytic)

probs1 = [probupwind1, probupwind2, probnu1, probnu2, probweno1, probweno2]

# Work-Precision Plot for Burgers Equation, Dirichlet BCs

abstols = 1.0 ./ 10.0 .^ (5:8)
reltols = 1.0 ./ 10.0 .^ (1:4);
setups = [Dict(:alg => solver, :prob_choice => 1),
    Dict(:alg => solver, :prob_choice => 2),
    Dict(:alg => solver, :prob_choice => 3),
    Dict(:alg => solver, :prob_choice => 4),
    Dict(:alg => solver, :prob_choice => 5),
    Dict(:alg => solver, :prob_choice => 6),]
names = ["Uniform Upwind, center_align", "Uniform Upwind, edge_align", "Nonuniform Upwind, center_align",
         "Nonuniform Upwind, edge_align", "WENO, center_align", "WENO, edge_align"];

wp = WorkPrecisionSet(probs1, abstols, reltols, setups; names=names,
    save_everystep=false, maxiters=Int(1e5),
    numruns=10, wrap=Val(false))
plot(wp)

# Here are the problems for pdesys2:
probupwind1 = discretize(pdesys2, discupwind1; analytic=analytic)
probupwind2 = discretize(pdesys2, discupwind2; analytic=analytic)

probweno1 = discretize(pdesys2, discweno1; analytic=analytic)
probweno2 = discretize(pdesys2, discweno2; analytic=analytic)

probnu1 = discretize(pdesys2, discnu1; analytic=analytic)
probnu2 = discretize(pdesys2, discnu2; analytic=analytic)

probs2 = [probupwind1, probupwind2, probnu1, probnu2, probweno1, probweno2]
# Work-Precision Plot for Burgers Equation, Neumann BCs

abstols = 1.0 ./ 10.0 .^ (5:8)
reltols = 1.0 ./ 10.0 .^ (1:4);
setups = [Dict(:alg => solver, :prob_choice => 1),
          Dict(:alg => solver, :prob_choice => 2),
          Dict(:alg => solver, :prob_choice => 3),
          Dict(:alg => solver, :prob_choice => 4),
          Dict(:alg => solver, :prob_choice => 5),
          Dict(:alg => solver, :prob_choice => 6),]
names = ["Uniform Upwind, center_align", "Uniform Upwind, edge_align", "Nonuniform Upwind, center_align",
         "Nonuniform Upwind, edge_align", "WENO, center_align", "WENO, edge_align"];

wp = WorkPrecisionSet(probs2, abstols, reltols, setups; names=names,
                      save_everystep=false, maxiters=Int(1e5),
                      numruns=10, wrap=Val(false))
plot(wp)
