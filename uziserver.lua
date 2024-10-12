 local FastCastRedux = loadstring(
	game:GetService "HttpService":GetAsync("https://raw.githubusercontent.com/rutheniumm/Project/refs/heads/main/FastCastRedux.lua", true)
)() 
local GunSettings = {
	BULLET_SPEED = 100 * 10	,						-- Studs/second - the speed of the bullet
	BULLET_MAXDIST = 5000	,						-- The furthest distance the bullet can travel 
	BULLET_GRAVITY = Vector3.new(0, -192.2 / 4, 0),		-- The amount of gravity applied to the bullet in world space (so yes, you can have sideways gravity)
	MIN_BULLET_SPREAD_ANGLE = 1,					-- THIS VALUE IS VERY SENSITIVE. Try to keep changes to it small. The least accurate the bullet can be. This angle value is in degrees. A value of 0 means straight forward. Generally you want to keep this at 0 so there's at least some chance of a 100% accurate shot.
	MAX_BULLET_SPREAD_ANGLE = 4	,				-- THIS VALUE IS VERY SENSITIVE. Try to keep changes to it small. The most accurate the bullet can be. This angle value is in degrees. A value of 0 means straight forward. This cannot be less than the value above. A value of 90 will allow the gun to shoot sideways at most, and a value of 180 will allow the gun to shoot backwards at most. Exceeding 180 will not add any more angular varience.
	FIRE_DELAY = 0.125		,						-- The amount of time that must pass after firing the gun before we can fire again.
	BULLETS_PER_SHOT = 1	,						-- The amount of bullets to fire every shot. Make this greater than 1 for a shotgun effect.
	PIERCE_DEMO = true,
}
local bullets = 34;
local currentbullets = bullets
local Caster = FastCastRedux.new() --Create a new caster object.
local reloading = false

-- Make a base cosmetic bullet object. This will be cloned every time we fire off a ray.
local CosmeticBullet = Instance.new("Part")
CosmeticBullet.Material = Enum.Material.Neon
CosmeticBullet.Color = Color3.fromRGB(255,255,155)
CosmeticBullet.CanCollide = false
CosmeticBullet.Anchored = true
CosmeticBullet.Size = Vector3.new(0.2 / .9, 0.2 / 0.9, 4)
local Trail = Instance.new("Trail", CosmeticBullet)
local A0, A1 = Instance.new("Attachment", CosmeticBullet), Instance.new("Attachment", CosmeticBullet)
A1.CFrame = CFrame.new(0, -0.25, 2)
Trail.Attachment0 = A0 Trail.Attachment1 = A1
Trail.Lifetime = 0.125
Trail.WidthScale = NumberSequence.new(2)
Trail.LightInfluence = 1
Trail.LightEmission = 1
Trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0,0), NumberSequenceKeypoint.new(1,1,1)})
Trail.Texture = "rbxassetid://2463944225"
local BulletMesh = Instance.new("SpecialMesh", CosmeticBullet)
BulletMesh.MeshType = Enum.MeshType.Sphere
local CastParams = RaycastParams.new()
CastParams.IgnoreWater = true
CastParams.FilterType = Enum.RaycastFilterType.Blacklist
CastParams.FilterDescendantsInstances = {}
local CosmeticBulletsFolder = workspace:FindFirstChild("CosmeticBulletsFolder") or Instance.new("Folder", script)
CosmeticBulletsFolder.Name = "CosmeticBulletsFolder"
local CastBehavior = FastCastRedux.newBehavior()
CastBehavior.RaycastParams = CastParams
CastBehavior.MaxDistance = GunSettings.BULLET_MAXDIST
CastBehavior.HighFidelityBehavior = FastCastRedux.HighFidelityBehavior.Default

CastBehavior.CosmeticBulletTemplate = CosmeticBullet -- Uncomment if you just want a simple template part and aren't using PartCache

CastBehavior.CosmeticBulletContainer = CosmeticBulletsFolder
CastBehavior.Acceleration = GunSettings.BULLET_GRAVITY
CastBehavior.AutoIgnoreContainer = false 

FastCastRedux.DebugLogging = false
FastCastRedux.VisualizeCasts = false


local tool = script.Parent;

local model = tool:WaitForChild("model")

local remote = tool:WaitForChild("remote")

local handle = model:WaitForChild('Handle')
handle.Transparency = 1
handle.Mag.Transparency = 1
local ignorelist = {}

local currentwelds = {}
currentwelds['Mag'] = handle.Mag.Mag6D
local currenttweens = {}

local posethreads = {}

local easingdir = Enum.EasingDirection
local easingstyle = Enum.EasingStyle

local lookrootpart

local animspeed = 1

local echos = {8940572767, 8940572102, 8940572571}
local snaps = {342190005, 342190012, 342190017, 342190024,342190488, 342190495, 342190504, 342190510}
local ti = TweenInfo.new

local rawTween = function(...)
	return game:GetService("TweenService"):Create(...)
end



local getSound = function(sfx : string?)
	return handle:FindFirstChild(sfx)
end

local equipSound = getSound("Equip")
local drawSound = getSound("Draw")
local fireSound = getSound("Fire")
local echoSound = getSound("Echo")
local distSound = getSound("Dist")
distSound.RollOffMinDistance = 50
distSound.RollOffMaxDistance = 250
fireSound.RollOffMaxDistance = 200
fireSound.RollOffMinDistance = 250 / 3

local RNG = Random.new()
local SubSonics = {1543863397,1543868661,1543862833,1543866965,1543862366,1543868286,1543869128}

local rates = {equip = NumberRange.new(0.98, 1.03), draw = NumberRange.new(0.98 / 1.3, 1.03 / 0.88925),fire = NumberRange.new(0.98, 1.03)}

local lastFire = os.clock() 

local thread = coroutine.create(Instance.new,'') thread = task.defer(thread, '')task.wait()
--Instance = {new=debug.info(thread, 0, 'f')} 
--warn(typeof(Instance))
local function playSound(sound : Sound?)
	local newSound = Instance.new'Sound' 
  newSound.Pitch = sound.Pitch
  newSound.RollOffMinDistance = sound.RollOffMinDistance
  newSound.RollOffMaxDistance = sound.RollOffMaxDistance

  newSound.SoundId = sound.SoundId
	newSound.Parent = sound.Parent
  newSound.Volume = sound.Volume;
	newSound.Name = tick();
	newSound:Play()
	newSound.Ended:Connect(function() if newSound then newSound:Destroy() end end)
	return newSound
end
local magc = CFrame.new(0, 0.868325591, -0.155000687, 1, 0, 0, 0, 1, 0, 0, 0, 1)
local animator = {
	["equip"] = { 
		[1] = {
      ["Mag"] = {CFrame.new(0, 0.868325591, -0.155000687, 1, 0, 0, 0, 1, 0, 0, 0, 1), easingdir.Out, easingstyle.Linear, 0.01};
			["Handle"] = {CFrame.new(-0.204498768, -1.2800951, -0.201242447, 0.769554555, 8.94069672e-08, 0.638580918, -0.583295882, -0.407006413, 0.702930212, 0.259906501, -0.91342473, -0.313213617), easingdir.Out, easingstyle.Sine, 0.05};
			["RightArmWeld"] = {CFrame.new(1.27275205, 0.0270502567, 0.449360847, 0.841375649, 0.295871556, -0.452268779, -0.0618487187, 0.884050667, 0.463280767, 0.536900163, -0.361820996, 0.762117863), easingdir.Out, easingstyle.Sine, 0.1};
			["LeftArmWeld"] = {CFrame.new(-1.45032501, -0.040602684, 0.070400238, 0.99204874, -0.091398716, -0.0865201652, 0.107116155, 0.974089146, 0.199189678, 0.0660726801, -0.206873566, 0.976134121), easingdir.Out, easingstyle.Sine, 0.1};
		},
		[2] = {
			["Handle"] = {CFrame.new(-0.0129351616, -1.2452898, -0.364902496, 0.931767821, 1.00582838e-07, -0.363054574, 0.363054454, -5.96046448e-08, 0.931767523, -5.96046448e-08, -0.999999642, 8.94069672e-08), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(1.27241516, 0.0544886589, -0.476769447, 0.848945081, 0.30411455, -0.432211161, -0.523161411, 0.367861509, -0.768752217, -0.0747948736, 0.878744721, 0.471395224), easingdir.Out, easingstyle.Sine, 0.35};
			["LeftArmWeld"] = {CFrame.new(-1.2652576, 0.0766291618, -0.500395775, 0.831764877, 0.301249564, -0.466278851, -0.546827555, 0.299913794, -0.781684875, -0.095638752, 0.905152142, 0.414189398), easingdir.Out, easingstyle.Sine, 0.35};
		}	
	},
	["idle"] = { 
		[1] = { 
			["Mag"] = {CFrame.new(0, 0.868325591, -0.155000687, 1, 0, 0, 0, 1, 0, 0, 0, 1), easingdir.Out, easingstyle.Circular, 0.4};
			["Handle"] = {CFrame.new(-0.00386142731, -1.24175453, -0.509126902, 0.931768, 5.86733222e-08, -0.363054693, 0.363054484, -1.67638063e-08, 0.931767642, -4.86616045e-08, -0.999999762, 3.91155481e-08), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(0.77859211, 0.162660599, -0.46551609, 0.946584046, 0.322453678, -0.00157818198, 0.00579211069, -0.0218960028, -0.999743521, -0.322405487, 0.946332037, -0.022594057), easingdir.Out, easingstyle.Sine, 0.35};
			["LeftArmWeld"] = {CFrame.new(-0.473414898, 0.246132851, -1.08607101, 0.862149477, -0.503756702, -0.0541068763, -0.0456906892, 0.0290521067, -0.998532832, 0.504589558, 0.863356948, 0.00203031301), easingdir.Out, easingstyle.Sine, 0.35};
		},
	},
	--//
	["shoot"] = {
		[1] = {
			["Handle"] = {CFrame.new(-0.00386142731, -1.24175453, -0.509126902, 0.931768, 5.86733222e-08, -0.363054693, 0.363054484, -1.67638063e-08, 0.931767642, -4.86616045e-08, -0.999999762, 3.91155481e-08) * CFrame.new(0, -0.2, 0), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(0.77859211, 0.162660599, -0.46551609, 0.946584046, 0.322453678, -0.00157818198, 0.00579211069, -0.0218960028, -0.999743521, -0.322405487, 0.946332037, -0.022594057) * CFrame.new(0, 0.2, 0) , easingdir.Out, easingstyle.Sine, 0.35};
			["LeftArmWeld"] = {CFrame.new(-0.473414898, 0.246132851, -1.08607101, 0.862149477, -0.503756702, -0.0541068763, -0.0456906892, 0.0290521067, -0.998532832, 0.504589558, 0.863356948, 0.00203031301) * CFrame.new(0, 0.2,0), easingdir.Out, easingstyle.Sine, 0.35};
		},
		[2] = {
			["Handle"] = {CFrame.new(-0.00386142731, -1.24175453, -0.509126902, 0.931768, 5.86733222e-08, -0.363054693, 0.363054484, -1.67638063e-08, 0.931767642, -4.86616045e-08, -0.999999762, 3.91155481e-08), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(0.77859211, 0.162660599, -0.46551609, 0.946584046, 0.322453678, -0.00157818198, 0.00579211069, -0.0218960028, -0.999743521, -0.322405487, 0.946332037, -0.022594057) , easingdir.Out, easingstyle.Sine, 0.35};
			["LeftArmWeld"] = {CFrame.new(-0.473414898, 0.246132851, -1.08607101, 0.862149477, -0.503756702, -0.0541068763, -0.0456906892, 0.0290521067, -0.998532832, 0.504589558, 0.863356948, 0.00203031301), easingdir.Out, easingstyle.Sine, 0.35};
		}
	},
	["reload"] = { 
		[1] = { 
			["Mag"] = {magc, easingdir.Out, easingstyle.Circular, 0.4};
			["Handle"] = {CFrame.new(-0.0129346848, -1.24528885, -0.364902496, 0.974198639, 0.222899079, 0.0353930593, -0.0479466915, 0.0511598922, 0.997538447, 0.220539764, -0.973497748, 0.0605271757), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(1.00426197, 0.471280813, -0.612170219, 0.845753908, 0.251792967, -0.470425904, -0.446733832, -0.147950321, -0.882348835, -0.291768909, 0.956405222, -0.0126451328), easingdir.Out, easingstyle.Sine, 0.35};
			["LeftArmWeld"] = {CFrame.new(-1.14152431, 0.267874718, -0.450926781, 0.857393205, 0, -0.514661908, -0.41166991, 0.600154161, -0.685815275, 0.308876514, 0.79988426, 0.51456815), easingdir.Out, easingstyle.Sine, 0.35};
		},
		[2] = { 
			["Mag"] = {magc, easingdir.Out, easingstyle.Circular, 0.4};
			["Handle"] = {CFrame.new(-0.0223665237, -1.31816292, -0.349402636, 0.970082343, 0.207759455, 0.125602007, -0.0765620172, -0.229156718, 0.970373392, 0.230386719, -0.95095861, -0.206394449), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(0.805099487, 0.108609438, -0.615839958, 0.7680372, 0.251792967, -0.588828564, -0.570731342, -0.147950321, -0.807698131, -0.290490121, 0.956405222, 0.0300747901), easingdir.Out, easingstyle.Sine, 0.35};
			["LeftArmWeld"] = {CFrame.new(-0.250196457, -0.10291338, -0.752233505, 0.788683951, -0.0193888806, -0.614493012, -0.488832295, 0.586387634, -0.645904183, 0.37285459, 0.80979836, 0.452996731), easingdir.Out, easingstyle.Sine, 0.35};
		},
		[3] = { 
			["Mag"] = {magc * CFrame.new(0,0.67,0), easingdir.Out, easingstyle.Circular, 0.4};
			["Handle"] = {CFrame.new(-0.0223665237, -1.31816292, -0.349402875, 0.883353829, 0.223241031, 0.412127376, -0.401906312, -0.091636762, 0.9110834, 0.241157204, -0.970445931, 0.008774288), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(0.805099487, 0.108609438, -0.615839958, 0.7680372, 0.251792967, -0.588828564, -0.570731342, -0.147950321, -0.807698131, -0.290490121, 0.956405222, 0.0300747901), easingdir.Out, easingstyle.Sine, 0.35};
			["LeftArmWeld"] = {CFrame.new(-0.814729214, -0.427147865, -0.3139925, 0.747152567, 0.32089445, -0.582056284, -0.651809394, 0.525076926, -0.547209561, 0.13002795, 0.788238943, 0.601474702), easingdir.Out, easingstyle.Sine, 0.35};
		},
		[4] = { 
			["Mag"] = {CFrame.new( 2.02891159, -11.182085, -2.57484531, -0.979662716, 0.192950279, 0.0550401956, -0.200315997, -0.956282139, -0.213058844, 0.0115246177, -0.219751507, 0.975485206), easingdir.Out, easingstyle.Linear, 0.001};
			["Handle"] = {CFrame.new(-0.0223674774, -1.31816292, -0.349403143, 0.963617563, 0.266463041, -0.02094087, 0.0196973681, 0.00733889639, 0.999778688, 0.266557664, -0.963816702, 0.00182328373), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(1.15309906, 0.201326609, -0.499596596, 0.937240124, 0.328309953, -0.117446266, -0.120177679, -0.0120347729, -0.992679358, -0.32731995, 0.944493413, 0.0281760693), easingdir.Out, easingstyle.Sine, 0.35};
			["LeftArmWeld"] = {CFrame.new(-1.3934617, -0.0892276764, -0.258230209, 0.747152567, 0.513919175, -0.421485245, -0.651809394, 0.690605938, -0.313380808, 0.13002795, 0.508871496, 0.8509655), easingdir.Out, easingstyle.Sine, 0.35};
		},
		[5] = { 
			["Mag"] = {CFrame.new( 2.02891159, -11.182085, -2.57484531, -0.979662716, 0.192950279, 0.0550401956, -0.200315997, -0.956282139, -0.213058844, 0.0115246177, -0.219751507, 0.975485206), easingdir.Out, easingstyle.Linear, 0.001};
			["Handle"] = {CFrame.new(-0.0223674774, -1.31816196, -0.349402428, 0.959312856, 0.266463041, 0.0933592916, -0.0988777876, 0.00733892247, 0.995072246, 0.264464647, -0.963816762, 0.0333875567), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(1.12961555, 0.0752937794, -0.520564079, 0.937240124, 0.317067534, -0.145083576, -0.120177679, -0.0968550518, -0.988016307, -0.32731995, 0.943444431, -0.0526719913), easingdir.Out, easingstyle.Sine, 0.35};
			["LeftArmWeld"] = {CFrame.new(-1.22527266, -0.08816576, 0.752699852, 0.744767785, -0.517369151, -0.421485245, 0.415747911, 0.853783131, -0.313380808, 0.521990776, 0.0581642315, 0.8509655), easingdir.Out, easingstyle.Sine, 0.35};
		},
		[6] = { 
			["Mag"] = {magc * CFrame.new(0,0.87,0), easingdir.Out, easingstyle.Circular, 0.01};
			["Handle"] = {CFrame.new(-0.0223665237, -1.31816292, -0.349402875, 0.883353829, 0.223241031, 0.412127376, -0.401906312, -0.091636762, 0.9110834, 0.241157204, -0.970445931, 0.008774288), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(0.805099487, 0.108609438, -0.615839958, 0.7680372, 0.251792967, -0.588828564, -0.570731342, -0.147950321, -0.807698131, -0.290490121, 0.956405222, 0.0300747901), easingdir.Out, easingstyle.Sine, 0.35};
			["LeftArmWeld"] = {CFrame.new(-0.814729214, -0.427147865, -0.3139925, 0.747152567, 0.32089445, -0.582056284, -0.651809394, 0.525076926, -0.547209561, 0.13002795, 0.788238943, 0.601474702), easingdir.Out, easingstyle.Circular, 0.225};
		},
		[7] = { 
			["Mag"] = {magc * CFrame.new(0,-0.125,0), easingdir.Out, easingstyle.Circular, 0.225};
			["Handle"] = {CFrame.new(-0.0223665237, -1.31816292, -0.349402636, 0.970082343, 0.207759455, 0.125602007, -0.0765620172, -0.229156718, 0.970373392, 0.230386719, -0.95095861, -0.206394449), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(0.805099487, 0.108609438, -0.615839958, 0.7680372, 0.251792967, -0.588828564, -0.570731342, -0.147950321, -0.807698131, -0.290490121, 0.956405222, 0.0300747901), easingdir.Out, easingstyle.Circular, 0.225};
			["LeftArmWeld"] = {CFrame.new(-0.250196457, -0.10291338, -0.752233505, 0.788683951, -0.0193888806, -0.614493012, -0.488832295, 0.586387634, -0.645904183, 0.37285459, 0.80979836, 0.452996731), easingdir.Out, easingstyle.Sine, 0.35};
		},
		[8] = { 
			["Mag"] = {magc, easingdir.Out, easingstyle.Circular, 0.125};
			["Handle"] = {CFrame.new(-0.0129346848, -1.24528885, -0.364902496, 0.974198639, 0.222899079, 0.0353930593, -0.0479466915, 0.0511598922, 0.997538447, 0.220539764, -0.973497748, 0.0605271757), easingdir.Out, easingstyle.Sine, 0.4};
			["RightArmWeld"] = {CFrame.new(1.00426197, 0.471280813, -0.612170219, 0.845753908, 0.251792967, -0.470425904, -0.446733832, -0.147950321, -0.882348835, -0.291768909, 0.956405222, -0.0126451328), easingdir.Out, easingstyle.Sine, 0.35};
			["LeftArmWeld"] = {CFrame.new(-1.14152431, 0.267874718, -0.450926781, 0.857393205, 0, -0.514661908, -0.41166991, 0.600154161, -0.685815275, 0.308876514, 0.79988426, 0.51456815), easingdir.Out, easingstyle.Sine, 0.35};
		},
	}
}




local stopOnEquip = {"Handle", "LeftArmWeld", "RightArmWeld", "LookRootWeld", "HeadRootWeld"}

weld = function(part0, part1, c0, name, c1)
	local w = Instance.new("Weld")
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = c0
	w.Name = name
	w.Parent = part0
	currentwelds[name] = w
end

tweenpose = function(weld : Weld, c0 : CFrame, tinfo : TweenInfo?)
	local tween = rawTween(weld, tinfo, {C0 = c0}) :: Tween?
	tween:Play()
	table.insert(currenttweens, {weld.Name, tween});
	return (tween :: Tween)
end



pose = function(posestring : string?, keyframe : number)
	local animation = animator[posestring][keyframe];
	if animation then
		for weldname, keyframedata in pairs(animation) do 
			if currentwelds[weldname] then
				local c0 = keyframedata[1];
				local ed = keyframedata[2]
				local es = keyframedata[3]
				local tim = keyframedata[4]
				local weld = currentwelds[weldname]
				if weld.Name:find("Arm") then
					c0 = c0 + Vector3.new(0, -1, 0)
				end
				tweenpose(weld, c0, ti(tim,es,ed))
			end
		end
	end
end

--//

function resetPosing()
	for _, stopName in pairs(stopOnEquip) do 
		if currentwelds[stopName] then
			currentwelds[stopName]:Destroy()
			currentwelds[stopName] = nil;
		end
	end
	for poseindex, posethread in pairs(posethreads) do 
		task.cancel(posethread)
	end
  table.clear(posethreads)
	for tweenindex, tween in pairs(currenttweens) do 
	
		if table.find(stopOnEquip, tween[1]) then
			tween[2]:Cancel()
			table.remove(currenttweens, tweenindex)
		end
	end
end
local player

tool.AncestryChanged:Connect(function() 
  if tool then
	if tool.Parent:IsA("Model") then
player = game:GetService("Players"):GetPlayerFromCharacter(tool.Parent)
		local character = player.Character
		if not table.find(ignorelist, character) then
			table.insert(ignorelist, character)
		end
      if character:FindFirstChild("Humanoid") then
      character:FindFirstChild("Humanoid").AutoRotate = false
    end
    --// resetPosing()
		--//
		lookrootpart = Instance.new("Part")
		lookrootpart.Name = "animroot"
		lookrootpart.Size = Vector3.new(0.1,0.5,0.1)
		lookrootpart.CanCollide = false
		lookrootpart.CanTouch = false
		lookrootpart.Name = "lrp"
		lookrootpart.Parent = character.Head
		lookrootpart:BreakJoints()
		weld(character["Right Arm"], handle, CFrame.new(-0.0129346848, -1.24528909, -0.364902496, 0.999999881, 0, -5.96046448e-08, -8.94069458e-08, 0, 0.999999523, -0, -0.999999642, 0), "Handle")
		weld(lookrootpart, character["Right Arm"], CFrame.new(1.5, -1, 0), "RightArmWeld")
		weld(lookrootpart, character["Left Arm"], CFrame.new(-1.5, -1, 0), "LeftArmWeld") 
      weld(lookrootpart, character.Head, CFrame.new(0,1.5-(1),0), "HeadRootWeld")
		weld(character.Torso, lookrootpart, CFrame.new(0, 1 ,0), "LookRootWeld")
		handle.Transparency = 0
		handle.Mag.Transparency = 0
		table.insert(posethreads,  task.defer(function()
			equipSound.Pitch = 1 * RNG:NextNumber(rates.equip.Min, rates.equip.Max)
			drawSound.Pitch = 1 * RNG:NextNumber(rates.draw.Min, rates.draw.Max)
			pose("equip", 1)
			playSound(drawSound)
			task.wait(0.4 / animspeed)
			pose("equip", 2)
			playSound(equipSound)
			task.wait(0.12 / animspeed)
			pose("idle", 1)
		end))
	end
    end
    
end)

tool.Unequipped:Connect(function()
	--//
	if lookrootpart then
		lookrootpart:Destroy()
		lookrootpart = nil;
	end
	handle.Transparency = 1
	handle.Mag.Transparency = 1
    reloading = false
resetPosing()
  if player then
      if player.Character:FindFirstChild("Humanoid") then
      player.Character:FindFirstChild("Humanoid").AutoRotate = true
    end
    end
end)



remote.OnServerEvent:Connect(function(player, ...)
	local args = table.pack(...) 
	if args[1] == "aim" then
		if player.Character ~= tool.Parent then
			return
		end 
		if tool.Parent:IsA("Model") == false then
			return
		end 
      if player.Character:FindFirstChild("HumanoidRootPart") then
      else return end
		local mouseDirection = (player.Character.HumanoidRootPart.Position-args[2]).Unit
      if currentwelds["LookRootWeld"] then
		currentwelds["LookRootWeld"].C0 = currentwelds["LookRootWeld"].C0:Lerp(CFrame.new(0,1,0) * CFrame.Angles(-mouseDirection.y, 0, 0), 0.125)
      end
	end

	if args[1] == "lmb" then
		if player.Character ~= tool.Parent then
			return
		end 
		if tool.Parent:IsA("Model") == false then
			return
		end
		if currentbullets >=1 then

		else return end
		if reloading then return end
		CastParams.FilterDescendantsInstances = ignorelist
		if os.clock() - lastFire > GunSettings.FIRE_DELAY then
			if currentbullets >=1 then
				currentbullets = currentbullets - 1
			end
			lastFire = os.clock()
			local mouseDirection = (args[2] - handle.FirePosition.WorldPosition).Unit

			local directionalCF = CFrame.new(Vector3.new(), mouseDirection)
			local direction = (directionalCF * CFrame.fromOrientation(0, 0, 0) * CFrame.fromOrientation(math.rad(RNG:NextNumber(0, 0)), 0, 0)).LookVector
			local modifiedBulletSpeed = (direction * GunSettings.BULLET_SPEED)
			CastBehavior.CanPierceFunction = CanRayPierce
			local simBullet = Caster:Fire(handle.FirePosition.WorldPosition, direction, modifiedBulletSpeed, CastBehavior)
			table.insert(posethreads,  task.defer(function()
				echoSound.SoundId = "rbxassetid://"..(echos[math.random(1, #echos)])
				echoSound.Pitch = 1 * RNG:NextNumber(rates.fire.Min, rates.fire.Max)
				fireSound.Pitch = 1 * RNG:NextNumber(rates.fire.Min, rates.fire.Max)
				distSound.Pitch = 0.9 * RNG:NextNumber(rates.fire.Min, rates.fire.Max)
				distSound.Volume = RNG:NextNumber(0.9, 2.2)
				for i, muzzleEffect in pairs(handle.FirePosition:GetChildren()) do 
					if muzzleEffect:IsA("ParticleEmitter") then
						muzzleEffect:Emit(muzzleEffect:FindFirstChild("EmitCount").Value / math.random(1, 2))
					end
				end
				playSound(fireSound)
				playSound(distSound)
				playSound(echoSound)
				pose("shoot", 1)
				task.wait(0.05 / animspeed)
				pose("shoot", 2)
			end))
		end
	end
	if args[1] == "rld" then
		if player.Character ~= tool.Parent then
			return
		end 
		if tool.Parent:IsA("Model") == false then
			return
		end
		if currentbullets <=0 and reloading == false then
			table.insert(posethreads, task.defer(function()
				reloading = true
				pose("reload", 1)
				playSound(getSound("ClipOut"))
				task.wait(0.3 / animspeed)
				pose("reload", 2)
				task.wait(0.3 / animspeed)
				pose("reload", 3)
				task.wait(0.3 / animspeed)
				pose("reload", 4)
				task.delay(0.2, function()
					handle.Mag.Transparency = 1
				end)
				task.wait(0.3 / animspeed)
				pose("reload", 5)
				task.delay(0.22, function()
					playSound(getSound("ClipIn"))
				end)
				task.wait(0.32 / animspeed)
				pose("reload", 6)
				task.delay(0.15 / animspeed, function()
					handle.Mag.Transparency = 0
				end)
				task.wait(0.35 / animspeed)
				pose("reload", 7)
				task.wait(0.35 / animspeed)
				pose("reload", 8)
				task.wait(0.1 / animspeed)
				playSound(getSound("Back"))
				pose("idle", 1)

				currentbullets = bullets
				reloading = false
			end))
		end
	end
end)

workspace.DescendantAdded:Connect(function(WHAT)
	if WHAT.Name == "Handle" and WHAT:IsA("BasePart") then
		table.insert(ignorelist, WHAT)
	end
end)

for i,v in pairs(workspace:GetDescendants()) do
	if v.Name == "Handle" and v:IsA("BasePart") then
		table.insert(ignorelist, v)
	end
end

function FixFolder()
	CosmeticBulletsFolder = workspace:FindFirstChild("CosmeticBulletsFolder") or Instance.new("Folder", script)
	CosmeticBulletsFolder.Name = "CosmeticBulletsFolder"
	CosmeticBulletsFolder.Destroying:Connect(FixFolder)
end

CosmeticBulletsFolder.Destroying:Connect(FixFolder)
local function Reflect(surfaceNormal, bulletNormal)
	return bulletNormal - (2 * bulletNormal:Dot(surfaceNormal) * surfaceNormal)
end
--//

function CanRayPierce(cast, rayResult, segmentVelocity)

	-- Let's keep track of how many times we've hit something.
	local hits = cast.UserData.Hits
	if (hits == nil) then
		-- If the hit data isn't registered, set it to 1 (because this is our first hit)
		cast.UserData.Hits = 1
	else
		-- If the hit data is registered, add 1.
		cast.UserData.Hits += 1
	end

	-- And if the hit count is over 3, don't allow piercing and instead stop the ray.
	if (cast.UserData.Hits >= 1) then
		return false
	end

	-- Now if we make it here, we want our ray to continue.
	-- This is extra important! If a bullet bounces off of something, maybe we want it to do damage too!
	-- So let's implement that.
	local hitPart = rayResult.Instance
	OnRayHit(cast,rayResult, segmentVelocity)

	-- And then lastly, return true to tell FC to continue simulating.
	return true

	--[[
	-- This function shows off the piercing feature literally. Pass this function as the last argument (after bulletAcceleration) and it will run this every time the ray runs into an object.
	
	-- Do note that if you want this to work properly, you will need to edit the OnRayPierced event handler below so that it doesn't bounce.
	
	if material == Enum.Material.Plastic or material == Enum.Material.Ice or material == Enum.Material.Glass or material == Enum.Material.SmoothPlastic then
		-- Hit glass, plastic, or ice...
		if hitPart.Transparency >= 0.5 then
			-- And it's >= half transparent...
			return true -- Yes! We can pierce.
		end
	end
	return false
	--]]
end

function OnRayHit(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
	local normal = raycastResult.Normal
	if hitPart ~= nil and hitPart.Parent ~= nil then 
		local humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:TakeDamage(35)
		end
	end
	if hitPart then
		local bullethole = Instance.new("Part", CosmeticBulletsFolder)
		bullethole.Anchored = false
		bullethole.Size = Vector3.new(0.1,0.2,0.1)
		bullethole.Color = Color3.new(0)
		bullethole.Material = Enum.Material.Concrete
		bullethole.CFrame = CFrame.new(raycastResult.Position, raycastResult.Position + raycastResult.Normal) * CFrame.Angles(math.rad(90), 0, 0)
		bullethole.CFrame = bullethole.CFrame +- bullethole.CFrame.UpVector * bullethole.Size.Y / 4 
		local weld = Instance.new("WeldConstraint", bullethole)
		weld.Part0 = bullethole
		weld.Part1 = hitPart

		local fx = Instance.new("Sound", bullethole)
		fx.SoundId = "rbxassetid://"..(SubSonics[math.random(1,#SubSonics)])
		fx.Pitch = 1 * RNG:NextNumber(0.98, 1.05)
		fx.RollOffMaxDistance = 50
		fx.PlayOnRemove = true 
		fx:Destroy()
		local msh = Instance.new("SpecialMesh", bullethole)
		msh.MeshType = Enum.MeshType.Sphere
		rawTween(bullethole,ti(0.1,easingstyle.Exponential),{Size=Vector3.new(0.2,0.1,0.2)}):Play(); 
		game:GetService("Debris"):AddItem(bullethole, 12)
	end
end
local wizzs = {}

function OnRayUpdated(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
	if cosmeticBulletObject == nil then return end
	local bulletLength = cosmeticBulletObject.Size.Z / 2 
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
  if wizzs[cosmeticBulletObject]== nil then wizzs[cosmeticBulletObject] = os.clock()  local fx = Instance.new("Sound",cosmeticBulletObject)
    fx.SoundId = "rbxassetid://"..(snaps[math.random(1,#snaps)]) 
    fx.Volume=Random.new():NextNumber(0,2);
    fx.Pitch=1*Random.new():NextNumber(0.98,1.05) 
    fx:Play() end
end

function OnRayTerminated(cast)
	local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
	if cosmeticBullet ~= nil then
		if CastBehavior.CosmeticBulletProvider ~= nil then
			CastBehavior.CosmeticBulletProvider:ReturnPart(cosmeticBullet)
		else
			cosmeticBullet:Destroy()
		end
	end
end


function OnRayPierced(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	-- You can do some really unique stuff with pierce behavior - In reality, pierce is just the module's way of asking "Do I keep the bullet going, or do I stop it here?"
	-- You can make use of this unique behavior in a manner like this, for instance, which causes bullets to be bouncy.
	local position = raycastResult.Position
	local normal = raycastResult.Normal

	local newNormal = Reflect(normal, segmentVelocity.Unit)
	cast:SetVelocity(newNormal * segmentVelocity.Magnitude)

	-- It's super important that we set the cast's position to the ray hit position. Remember: When a pierce is successful, it increments the ray forward by one increment.
	-- If we don't do this, it'll actually start the bounce effect one segment *after* it continues through the object, which for thin walls, can cause the bullet to almost get stuck in the wall.
	cast:SetPosition(position)

	-- Generally speaking, if you plan to do any velocity modifications to the bullet at all, you should use the line above to reset the position to where it was when the pierce was registered.
end

Caster.RayHit:Connect(OnRayHit)
Caster.RayPierced:Connect(OnRayPierced)
Caster.LengthChanged:Connect(OnRayUpdated)
Caster.CastTerminating:Connect(OnRayTerminated)

table.insert(ignorelist, CosmeticBulletsFolder) 


return Caster