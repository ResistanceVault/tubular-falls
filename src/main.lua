hg = require("harfang")

function CreatePhysicCubeEx(scene, size, mtx, model_ref, materials, rb_type, mass)
	local rb_type = rb_type or hg.RBT_Dynamic
	local mass = mass or 0
	local node = hg.CreateObject(scene, mtx, model_ref, materials)
	node:SetName("Physic Cube")
	local rb = scene:CreateRigidBody()
	rb:SetType(rb_type)
	node:SetRigidBody(rb)
    -- create custom cube collision
	local col = scene:CreateCollision()
	col:SetType(hg.CT_Cube)
	col:SetSize(size)
	col:SetMass(mass)
    -- set cube as collision shape
	node:SetCollision(0, col)
	return node, rb
end

function CreatePhysicCylinderEx(scene, radius, height, mtx, model_ref, materials, rb_type, mass)
	local rb_type = rb_type or hg.RBT_Dynamic
	local mass = mass or 0
	local node = hg.CreateObject(scene, mtx, model_ref, materials)
	node:SetName("Physic Cylinder")
	local rb = scene:CreateRigidBody()
	rb:SetType(rb_type)
	node:SetRigidBody(rb)
    -- create custom cylinder collision
	local col = scene:CreateCollision()
	col:SetType(hg.CT_Cylinder)
	col:SetRadius(radius)
	col:SetHeight(height)
	col:SetMass(mass)
    -- set cylinder as collision shape
	node:SetCollision(0, col)
	return node, rb
end

hg.AddAssetsFolder('assets_compiled')

-- main window
hg.InputInit()
hg.WindowSystemInit()

res_x, res_y = 800, 600
win = hg.RenderInit('Physics Test', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

pipeline = hg.CreateForwardPipeline()
res = hg.PipelineResources()

-- physics debug
vtx_line_layout = hg.VertexLayoutPosFloatColorUInt8()
line_shader = hg.LoadProgramFromAssets("shaders/pos_rgb")

-- create material
pbr_shader = hg.LoadPipelineProgramRefFromAssets('core/shader/pbr.hps', res, hg.GetForwardPipelineInfo())
mat_grey = hg.CreateMaterial(pbr_shader, 'uBaseOpacityColor', hg.Vec4(1, 1, 1), 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.5, 0.05))

-- create models
vtx_layout = hg.VertexLayoutPosFloatNormUInt8()

-- cube
cube_size =  hg.Vec3(1, 1, 1)
cube_ref = res:AddModel('cube', hg.CreateCubeModel(vtx_layout, cube_size.x, cube_size.y, cube_size.z))

-- cylinder
cylinder_radius = 0.25
cylinder_height = 10
cylinder_ref = res:AddModel('cylinder', hg.CreateCylinderModel(vtx_layout, cylinder_radius, cylinder_height, 16))

-- ground
ground_size = hg.Vec3(15, 0.05, 15)
ground_ref = res:AddModel('ground', hg.CreateCubeModel(vtx_layout, ground_size.x, ground_size.y, ground_size.z))

-- setup the scene
scene = hg.Scene()

cam_mat = hg.TransformationMat4(hg.Vec3(0, 6, -8.5), hg.Vec3(hg.Deg(25), 0, 0))
cam = hg.CreateCamera(scene, cam_mat, 0.01, 1000, hg.Deg(30))
view_matrix = hg.InverseFast(cam_mat)
c = cam:GetCamera()
projection_matrix = hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1))

scene:SetCurrentCamera(cam)	

lgt = hg.CreateLinearLight(scene, hg.TransformationMat4(hg.Vec3(0, 0, 0), hg.Vec3(hg.Deg(30), hg.Deg(30), 0)), hg.Color(1, 1, 1), hg.Color(1, 1, 1), 10, hg.LST_Map, 0.00025, hg.Vec4(2, 4, 10, 16))

-- cube_node = hg.CreatePhysicCube(scene, cube_size, hg.TranslationMat4(hg.Vec3(0, 1, 2.5)), cube_ref, {mat_grey}, 0)
floor, rb_floor = CreatePhysicCubeEx(scene, ground_size, hg.TranslationMat4(hg.Vec3(0, -0.5, 0)), ground_ref, {mat_grey}, hg.RBT_Static, 0)

cylinders_list = {}

cylinder_mtx = hg.TransformationMat4(hg.Vec3(0, 5, 0), hg.Vec3(hg.Deg(0), hg.Deg(0), hg.Deg(90)))
cylinder_node, cylinder_rb = CreatePhysicCylinderEx(scene, cylinder_radius, cylinder_height, cylinder_mtx, cylinder_ref, {mat_grey}, hg.RBT_Dynamic, 1.0)
table.insert(cylinders_list, cylinder_node)

cylinder_mtx = hg.TransformationMat4(hg.Vec3(0, 10, 0.15), hg.Vec3(hg.Deg(0), hg.Deg(0), hg.Deg(90)))
cylinder_node, cylinder_rb = CreatePhysicCylinderEx(scene, cylinder_radius, cylinder_height, cylinder_mtx, cylinder_ref, {mat_grey}, hg.RBT_Dynamic, 1.0)
table.insert(cylinders_list, cylinder_node)


-- scene physics
physics = hg.SceneBullet3Physics()
physics:SceneCreatePhysicsFromAssets(scene)
physics_step = hg.time_from_sec_f(1 / 60)
dt_frame_step = hg.time_from_sec_f(1 / 60)

clocks = hg.SceneClocks()

-- 

for i = 1, #cylinders_list do
	local _node = cylinders_list[i]
	physics:NodeSetLinearFactor(_node, hg.Vec3(0.0, 1.0, 1.0))
	physics:NodeSetAngularFactor(_node, hg.Vec3(1.0, 0.0, 0.0))
end

-- main loop
keyboard = hg.Keyboard()
mouse = hg.Mouse()

vtx = hg.Vertices(vtx_line_layout, 2)
vid_scene_opaque = 0

while not keyboard:Down(hg.K_Escape) and hg.IsWindowOpen(win) do
    keyboard:Update()
	mouse:Update()

	-- for i = 1, 60 do
	-- 	start_pos = hg.Vec3(-8 + 0.2 * i, 0.75, -5)
	-- 	end_pos = hg.Vec3(-8 + 0.2 * i, 0.75, 10)
	-- 	raycast_out = physics:RaycastFirstHit(scene, start_pos, end_pos)
	-- 	if raycast_out.node:IsValid() then
	-- 		vtx:Clear()
	-- 		vtx:Begin(0):SetPos(start_pos):SetColor0(hg.Color.Green):End()
	-- 		vtx:Begin(1):SetPos(raycast_out.P):SetColor0(hg.Color.Green):End()
	-- 		hg.DrawLines(vid_scene_opaque, vtx, line_shader)  -- submit all lines in a single call
	-- 	else
	-- 		vtx:Clear()
	-- 		vtx:Begin(0):SetPos(start_pos):SetColor0(hg.Color.Red):End()
	-- 		vtx:Begin(1):SetPos(end_pos):SetColor0(hg.Color.Red):End()
	-- 		hg.DrawLines(vid_scene_opaque, vtx, line_shader)  -- submit all lines in a single call
	-- 	end
	-- end

    view_id = 0
    hg.SceneUpdateSystems(scene, clocks, dt_frame_step, physics, physics_step, 3)
    view_id, pass_id = hg.SubmitSceneToPipeline(view_id, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)
	vid_scene_opaque = hg.GetSceneForwardPipelinePassViewId(pass_id, hg.SFPP_Opaque)

    -- Debug physics display
    hg.SetViewClear(view_id, 0, 0, 1.0, 0)
    hg.SetViewRect(view_id, 0, 0, res_x, res_y)
    hg.SetViewTransform(view_id, hg.InverseFast(cam:GetTransform():GetWorld()), hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1)))
    rs = hg.ComputeRenderState(hg.BM_Opaque, hg.DT_Disabled, hg.FC_Disabled)
    physics:RenderCollision(view_id, vtx_line_layout, line_shader, rs, 0)

    hg.Frame()
    hg.UpdateWindow(win)
end

scene:Clear()
scene:GarbageCollect()

hg.RenderShutdown()
hg.DestroyWindow(win)

hg.WindowSystemShutdown()
hg.InputShutdown()