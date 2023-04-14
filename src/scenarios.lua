hg = require("harfang")

function scenario00(scene, cylinder_radius, cylinder_height, cylinder_ref, mat_grey)
	local _list = {}

	local i, _y, _z, _s, _r, _m
	_y = 5
	_s = 1.0
	_m = 6.0
	_z = {_s + (0.1 * _m), _s - (0.1 * _m), _s + (0.0 * _m), _s + (0.2 * _m), _s - (0.2 * _m), _s + (0.0 * _m)}
	_r = 1.0
	for i = 1, 15 do
		local cylinder_mtx = hg.TransformationMat4(hg.Vec3(0, _y, _z[math.fmod(i, #_z) + 1]), hg.Vec3(hg.Deg(0), hg.Deg(0), hg.Deg(90)))
		local cylinder_node, cylinder_rb = CreatePhysicCylinderEx(scene, cylinder_radius, cylinder_height, cylinder_mtx, cylinder_ref, {mat_grey}, hg.RBT_Dynamic, 1.0)
		cylinder_rb:SetRestitution(_r)
		cylinder_rb:SetFriction(1.0)
		table.insert(_list, cylinder_node)

		_y = _y + 10.0
	end
	return _list
end

function scenario01(scene, cylinder_radius, cylinder_height, cylinder_ref, mat_grey)
	local _list = {}

	local i, _y, _z, _s, _r, _m
	_y = 5
	_s = 1.0
	_m = 6.0
	_z = 1.0
	_r = 1.0
	for i = 1, 15 do
		_y = (math.sin(i * math.pi / 15) * 2.5) + 5.0
		_z = (i * cylinder_radius * 5.0)
		local cylinder_mtx = hg.TransformationMat4(hg.Vec3(0, _y, _z), hg.Vec3(hg.Deg(0), hg.Deg(0), hg.Deg(90)))
		local cylinder_node, cylinder_rb = CreatePhysicCylinderEx(scene, cylinder_radius, cylinder_height, cylinder_mtx, cylinder_ref, {mat_grey}, hg.RBT_Dynamic, 1.0)
		cylinder_rb:SetRestitution(_r)
		cylinder_rb:SetFriction(1.0)
		table.insert(_list, cylinder_node)

		-- _y = _y + 10.0
	end
	return _list
end