local testFiles = {
    "tools/tests/lua/test_breeding_math.lua",
    "tools/tests/lua/test_pedigree_registry.lua",
    "tools/tests/lua/test_pedigree_serialization.lua",
}

for _, path in ipairs(testFiles) do
    io.write("Running " .. path .. "\n")
    assert(loadfile(path))()
end

io.write("Lua domain tests passed\n")
