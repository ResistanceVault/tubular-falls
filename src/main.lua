hg = require("harfang")
require("scenarios")
require("utils")

local enable_physics_debug = false

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

function PrepareCapture(tex_width, tex_height)
	-- create a 512x512 frame buffer to draw the scene to
	tex_width = tex_width or 512
	tex_height = tex_height or 512

	local picture = hg.Picture(tex_width, tex_height, hg.PF_RGBA32)

	local tex_color = hg.CreateTexture(tex_width, tex_height, "color_texture", hg.TF_RenderTarget, hg.TF_RGBA8)
	local tex_color_ref = res:AddTexture("tex_rb", tex_color)
	local tex_depth =  hg.CreateTexture(tex_width, tex_height, "depth_texture", hg.TF_RenderTarget, hg.TF_D24)
	local frame_buffer = hg.CreateFrameBuffer(tex_color, tex_depth, "framebuffer")

	local tex_readback = hg.CreateTexture(tex_width, tex_height, "readback", hg.TF_ReadBack | hg.TF_BlitDestination, hg.TF_RGBA8)

	-- create a plane model to display the render texture
	local vtx_layout = hg.VertexLayoutPosFloatNormUInt8TexCoord0UInt8()

	local screen_mdl = hg.CreatePlaneModel(vtx_layout, 2, 2 * (res_y / res_x), 1, 1)
	local screen_ref = res:AddModel('screen', screen_mdl)

	-- prepare the cube shader program
	local screen_prg = hg.LoadProgramFromAssets('shaders/texture')

	return picture, tex_color, tex_color_ref, tex_depth, frame_buffer, tex_readback, vtx_layout, screen_mdl, screen_ref, screen_prg
end

hg.AddAssetsFolder('assets_compiled')

-- main window
hg.InputInit()
hg.WindowSystemInit()

res_x, res_y = 320, 200
win = hg.RenderInit('Physics Test', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

pipeline = hg.CreateForwardPipeline()
res = hg.PipelineResources()

-- AAA pipeline
pipeline_aaa_config = hg.ForwardPipelineAAAConfig()
pipeline_aaa = hg.CreateForwardPipelineAAAFromAssets("core", pipeline_aaa_config, hg.BR_Equal, hg.BR_Equal)
pipeline_aaa_config.z_thickness = 0.1
pipeline_aaa_config.sample_count = 6
pipeline_aaa_config.temporal_aa_weight = 0.001
-- pipeline_aaa_config.sample_count = 3
-- pipeline_aaa_config.sample_count = 3

-- screen capture
picture, tex_color, tex_color_ref, tex_depth, frame_buffer, tex_readback, vtx_layout, screen_mdl, screen_ref, screen_prg = PrepareCapture(res_x, res_y)

-- -- physics debug
-- vtx_line_layout = hg.VertexLayoutPosFloatColorUInt8()
-- line_shader = hg.LoadProgramFromAssets("shaders/pos_rgb")

-- create material
pbr_shader = hg.LoadPipelineProgramRefFromAssets('core/shader/pbr.hps', res, hg.GetForwardPipelineInfo())
mat_grey = hg.CreateMaterial(pbr_shader, 'uBaseOpacityColor', hg.Vec4(0.25, 0.5, 1), 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.15, 0.05))
mat_chrome = hg.CreateMaterial(pbr_shader, 'uBaseOpacityColor', hg.Vec4(0.35, 0.7, 1), 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.01, 0.5))

-- create models
vtx_layout = hg.VertexLayoutPosFloatNormUInt8()

-- cube
cube_size =  hg.Vec3(1, 1, 1)
cube_ref = res:AddModel('cube', hg.CreateCubeModel(vtx_layout, cube_size.x, cube_size.y, cube_size.z))

-- cylinder
cylinder_radius = 0.25
cylinder_height = 20
cylinder_ref = res:AddModel('cylinder', hg.CreateCylinderModel(vtx_layout, cylinder_radius, cylinder_height, 16))

-- ground
ground_size = hg.Vec3(15, 0.05, 15)
ground_ref = res:AddModel('ground', hg.CreateCubeModel(vtx_layout, ground_size.x, ground_size.y, ground_size.z))

-- setup the scene
scene = hg.Scene()

-- fog
scene.environment.fog_near = 12.0
scene.environment.fog_far = 16.0

cam_mat = hg.TransformationMat4(hg.Vec3(0, 6, -8.5), hg.Vec3(hg.Deg(25), 0, 0))
cam = hg.CreateCamera(scene, cam_mat, 0.01, 1000, hg.Deg(30))
view_matrix = hg.InverseFast(cam_mat)
c = cam:GetCamera()
projection_matrix = hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1))

scene:SetCurrentCamera(cam)	

lgt = hg.CreateLinearLight(scene, hg.TransformationMat4(hg.Vec3(0, 0, 0), hg.Vec3(hg.Deg(110), hg.Deg(0), 0)), hg.Color(1, 1, 1), hg.Color(1, 1, 1), 10, hg.LST_Map, 0.00025, hg.Vec4(5, 10, 25, 50))

-- cube_node = hg.CreatePhysicCube(scene, cube_size, hg.TranslationMat4(hg.Vec3(0, 1, 2.5)), cube_ref, {mat_grey}, 0)
floor, rb_floor = CreatePhysicCubeEx(scene, ground_size, hg.TranslationMat4(hg.Vec3(0, -0.5, 0)), ground_ref, {mat_chrome}, hg.RBT_Static, 0)
rb_floor:SetRestitution(1.0)
rb_floor:SetFriction(1.0)

cylinders_list = scenario01(scene, cylinder_radius, cylinder_height, cylinder_ref, mat_grey)


-- scene physics
physics = hg.SceneBullet3Physics()
physics:SceneCreatePhysicsFromAssets(scene)
physics_step = hg.time_from_sec_f(1 / 600)
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

-- vtx = hg.Vertices(vtx_line_layout, 2)
vid_scene_opaque = 0

delete_files_with_prefix("_capture", "frame_")

local frame = 0
local flag_capture_texture = false
local frame_count_capture = -1

while not keyboard:Down(hg.K_Escape) and hg.IsWindowOpen(win) and frame < 800 do
    keyboard:Update()
	mouse:Update()

    view_id = 0
    hg.SceneUpdateSystems(scene, clocks, dt_frame_step, physics, physics_step, 3)
    -- view_id, pass_id = hg.SubmitSceneToPipeline(view_id, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)
    view_id, pass_id = hg.SubmitSceneToPipeline(view_id, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame, frame_buffer.handle)

    if not flag_capture_texture and frame_count_capture ~= 0xffff then
		frame_count_capture, view_id = hg.CaptureTexture(view_id, res, tex_color_ref, tex_readback, picture)
		flag_capture_texture = frame_count_capture ~= 0xffff
    end

	vid_scene_opaque = hg.GetSceneForwardPipelinePassViewId(pass_id, hg.SFPP_Opaque)

	hg.SetViewPerspective(view_id, 0, 0, res_x, res_y, hg.TranslationMat4(hg.Vec3(0, 0, -1.8)))

	val_uniforms = {hg.MakeUniformSetValue('color', hg.Vec4(1, 1, 1, 1))}  -- note: these could be moved out of the main loop but are kept here for readability
	tex_uniforms = {hg.MakeUniformSetTexture('s_tex', tex_color, 0)}

	hg.DrawModel(view_id, screen_mdl, screen_prg, val_uniforms, tex_uniforms, hg.TransformationMat4(hg.Vec3(0, 0, 0), hg.Vec3(math.pi / 2, math.pi, 0)))

    frame = hg.Frame()

    -- save captured picture
    if flag_capture_texture and frame_count_capture <= frame then
	    hg.SavePNG(picture, "_capture/frame_" .. string.format("%05d", frame) .. ".png")
		flag_capture_texture = false
    end

    hg.UpdateWindow(win)
end

scene:Clear()
scene:GarbageCollect()

hg.RenderShutdown()
hg.DestroyWindow(win)

hg.WindowSystemShutdown()
hg.InputShutdown()

compress_folder_to_zip("_capture", "capture.zip")