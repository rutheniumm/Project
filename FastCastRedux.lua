


local FastCast = {}
FastCast.DebugLogging = false
FastCast.VisualizeCasts = false
FastCast.__index = FastCast
FastCast.__type = "FastCast" -- For compatibility with TypeMarshaller

-- Extra stuff
FastCast.HighFidelityBehavior = {
	Default = 1,
	Always = 3
}

-----------------------------------------------------------
----------------------- STATIC DATA -----------------------
-----------------------------------------------------------
local ActiveCastStatic = loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/rutheniumm/Project/refs/heads/main/ActiveCast.lua"))()
local Signal = loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/rutheniumm/Project/refs/heads/main/FastCastSignal.lua"))()
local table = loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/rutheniumm/Project/refs/heads/main/Table.lua"))()

-- Format params: methodName, ctorName
local ERR_NOT_INSTANCE = "Cannot statically invoke method '%s' - It is an instance method. Call it on an instance of this class created via %s"

-- Format params: paramName, expectedType, actualType
local ERR_INVALID_TYPE = "Invalid type for parameter '%s' (Expected %s, got %s)"

-- The name of the folder containing the 3D GUI elements for visualizing casts.
local FC_VIS_OBJ_NAME = "FastCastVisualizationObjects"

-- Format params: N/A
local ERR_OBJECT_DISPOSED = "This Caster has been disposed. It can no longer be used."

-----------------------------------------------------------
--------------------- TYPE DEFINITION ---------------------
-----------------------------------------------------------

-- This will inject all types into this context.
local TypeDefs = loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/rutheniumm/Project/refs/heads/main/TypeDefinitions.lua"))()
type CanPierceFunction = TypeDefs.CanPierceFunction
type GenericTable = TypeDefs.GenericTable
type Caster = TypeDefs.Caster
type FastCastBehavior = TypeDefs.FastCastBehavior
type CastTrajectory = TypeDefs.CastTrajectory
type CastStateInfo = TypeDefs.CastStateInfo
type CastRayInfo = TypeDefs.CastRayInfo
type ActiveCast = TypeDefs.ActiveCast

-----------------------------------------------------------
----------------------- STATIC CODE -----------------------
-----------------------------------------------------------

-- Tell the ActiveCast factory module what FastCast actually *is*.
ActiveCastStatic.SetStaticFastCastReference(FastCast)

-----------------------------------------------------------
------------------------- EXPORTS -------------------------
-----------------------------------------------------------

-- Constructor.
function FastCast.new()
	return setmetatable({
		LengthChanged = Signal.new("LengthChanged"),
		RayHit = Signal.new("RayHit"),
		RayPierced = Signal.new("RayPierced"),
		CastTerminating = Signal.new("CastTerminating"),
		WorldRoot = workspace
	}, FastCast)
end

-- Create a new ray info object.
-- This is just a utility alias with some extra type checking.
function FastCast.newBehavior(): FastCastBehavior
	-- raycastParams, maxDistance, acceleration, canPierceFunction, cosmeticBulletTemplate, cosmeticBulletContainer, autoIgnoreBulletContainer
	return {
		RaycastParams = nil,
		Acceleration = Vector3.new(),
		MaxDistance = 1000,
		CanPierceFunction = nil,
		HighFidelityBehavior = FastCast.HighFidelityBehavior.Default,
		HighFidelitySegmentSize = 0.5,
		CosmeticBulletTemplate = nil,
		CosmeticBulletProvider = nil,
		CosmeticBulletContainer = nil,
		AutoIgnoreContainer = true
	}
end

local DEFAULT_DATA_PACKET = FastCast.newBehavior()
function FastCast:Fire(origin: Vector3, direction: Vector3, velocity: Vector3 | number, castDataPacket: FastCastBehavior?): ActiveCast
	if castDataPacket == nil then castDataPacket = DEFAULT_DATA_PACKET end
	
	local cast = ActiveCastStatic.new(self, origin, direction, velocity, castDataPacket)
	cast.RayInfo.WorldRoot = self.WorldRoot
	return cast
end

-- Export
return FastCast