assert(loadfile("scripts/animal/BreedingMath.lua"))()

local function approximately(actual, expected, tolerance)
    assert(math.abs(actual - expected) <= tolerance,
        string.format("expected %.12f, got %.12f (tolerance %.12f)", expected, actual, tolerance))
end

assert(BreedingMath.clamp(-1, 0, 1) == 0)
assert(BreedingMath.clamp(2, 0, 1) == 1)
assert(BreedingMath.clamp(0.5, 0, 1) == 0.5)

approximately(BreedingMath.normal_cdf(0), 0.5, 0.000001)
approximately(BreedingMath.inv_norm_cdf(0.5), 0, 0.000001)
approximately(BreedingMath.normal_cdf(BreedingMath.inv_norm_cdf(0.975)), 0.975, 0.00001)

local sd = BreedingMath.sd_from_poutside(1.0, 0.10)
assert(sd ~= nil and sd > 0)

math.randomseed(12345)
local child, probabilities = BreedingMath.breedOffspring(0.25, 1.75, { sd = 0.15 })
assert(child >= 0.25 and child <= 1.75)
approximately(probabilities.above_best + probabilities.between + probabilities.below_worst, 1, 0.000001)
assert(probabilities.sd == 0.15)
