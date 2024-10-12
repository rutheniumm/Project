NLS([[
  
  local tool = script.Parent;
local remote = tool:WaitForChild("remote")
local handle = tool:WaitForChild("model"):WaitForChild("Handle")
local uis = game:GetService("UserInputService")
local plr = game:GetService("Players").LocalPlayer;
local mouse = plr:GetMouse()

remote.OnClientEvent:Connect(function(...)
	local args = table.pack(...)
end)

local cas = game:GetService("ContextActionService")
local inputName = tool.Name.."input"
local inputName2 = tool.Name.."input2"

cas:UnbindAction(inputName)

local md = false

tool.Equipped:Connect(function()
	cas:BindActionAtPriority(inputName, function(_, inputState, inputObject) 
		if inputState == Enum.UserInputState.Begin then
			md = true
		end
		if inputState == Enum.UserInputState.End then
			md = false
		end
	end, true, 1, Enum.UserInputType.MouseButton1)
	cas:BindActionAtPriority(inputName2, function(_, inputState, inputObject) 
		if inputState == Enum.UserInputState.Begin then
			remote:FireServer("rld")
		end
	end, true, 1, Enum.KeyCode.R)
end)

--//

tool.Unequipped:Connect(function()
	cas:UnbindAction(inputName)
	cas:UnbindAction(inputName2)
end)
  
game:GetService("RunService").RenderStepped:Connect(function()
  if tool and tool.Parent == plr.Character then
  if plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Head") then
    local mouseDirection = (mouse.Hit.p-plr.Character.Head.Position).Unit * 1000
  		plr.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame:lerp(CFrame.new(plr.Character.HumanoidRootPart.Position, Vector3.new(mouseDirection.x,plr.Character.HumanoidRootPart.Position.y,mouseDirection.z)), 0.3)
end
end
end)

task.defer(function()
  
	while task.wait() do 
		if md then
			remote:FireServer("lmb", mouse.Hit.Position)
		end
  	if tool.Parent == plr.Character then
  remote:FireServer("aim",mouse.Hit.Position)

end
	end
end) 
  ]], script.Parent)