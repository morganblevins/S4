-- Bottom pane of Fig. 12 in
-- Shanhui Fan and J. D. Joannopoulos,
-- "Analysis of guided resonances in photonic crystal slabs",
-- Phys. Rev. B, Vol. 65, 235112

S = S4.NewSimulation()
S:SetLattice({1,0}, {0,1})
S:SetNumG(100)
epsxxr  = -21
epsxxi  = 15
epsyyr  = -17
epsyyi  = 11
S:AddMaterial("PbTaSe2", { 
    {epsxxr, epsxxi}, {0, 0}, {0, 0},
	{0, 0}, {epsxxr, epsxxi}, {0, 0},
	{0, 0}, {0, 0}, {epsyyr, epsyyi}
	})
S:AddMaterial("Vacuum", {1,0})
S:AddLayer('AirAbove', 0 , 'Vacuum')
S:AddLayer('Slab', 0.5, 'PbTaSe2')
S:SetLayerPatternCircle('Slab', 'Vacuum', {0,0}, 0.2)
S:AddLayerCopy('AirBelow', 0, 'AirAbove')

S:SetExcitationPlanewave(
	{0,0}, -- incidence angles
	{1,0}, -- s-polarization amplitude and phase (in degrees)
	{0,0}) -- p-polarization amplitude and phase

--S:UsePolarizationDecomposition()
file = "PbTaSe2_data.txt"
function exgest(file)
    local f = io.open(file, 'w')
    io.output(f)
	io.write(tostring(data))
    io.write("\n")
    io.close(f)
 end

for freq=0.25,0.27,0.003 do
	S:SetFrequency(freq)
	forward,backward = S:GetPoyntingFlux('AirAbove', 0)
	forward = S:GetPoyntingFlux('AirBelow', 0)
	print (freq .. '\t' .. forward .. '\t' .. backward)
    exgest(file, freq)
	io.stdout:flush()
end
 
