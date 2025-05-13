-- credits to @.bl6e (on discord) for original script
-- kinda a fork of it but alr
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/Main.lua"))()

function printnotify(str)
	Fluent:Notify({
		Title = "Auto Bond",
		Content = str,
		Duration = 10,
	})
end

function wwarn(str)
	Fluent:Notify({
		Title = "Auto Bond",
		Content = str,
		Duration = 10,
	})
	for i,v in pairs(game:GetService("CoreGui"):GetChildren()) do
		-- not a good way but yes
		if v.Name == "ScreenGui" then
			for i,k in pairs(v:GetDescendants()) do
				if k.Name == "TextLabel" and k.Text == str then
					k.TextColor3 = Color3.fromRGB(255,255,0)
				end
			end
		end
	end
end

pcall(function()
    workspace.StreamingEnabled = false
    if workspace:FindFirstChild("SimulationRadius") then
        workspace.SimulationRadius = 999999
    end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorkspaceService = game:GetService("Workspace")

local cyberseallPlayer = Players.LocalPlayer
local cyberseallChar = cyberseallPlayer.Character or cyberseallPlayer.CharacterAdded:Wait()
local cyberseallHrp = cyberseallChar:WaitForChild("HumanoidRootPart")
local cyberseallHumanoid = cyberseallChar:WaitForChild("Humanoid")

local cyberseallExecutor = "unknown"
pcall(function()
    if identifyexecutor then
        cyberseallExecutor = identifyexecutor():lower()
    end
end)
print("[Executor] " .. cyberseallExecutor)

local cyberseallSuccess, cyberseallQueueCandidate = pcall(function()
    return (syn and syn.queue_on_teleport)
        or queue_on_teleport
        or (fluxus and fluxus.queue_on_teleport)
end)
local cyberseallQueueOnTp = cyberseallSuccess and cyberseallQueueCandidate or function(...) end

local cyberseallRemotesRoot1 = ReplicatedStorage:WaitForChild("Remotes")
local cyberseallRemotePromiseFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("RemotePromise")
local cyberseallRemotesRoot2 = cyberseallRemotePromiseFolder:WaitForChild("Remotes")
local cyberseallEndDecisionRemote = cyberseallRemotesRoot1:WaitForChild("EndDecision")

local cyberseallHasPromise, cyberseallRemotePromiseMod = true
local ok, mod = pcall(function()
    return require(cyberseallRemotePromiseFolder)
end)
if ok then
    cyberseallRemotePromiseMod = mod
else
    cyberseallHasPromise = false
end

if cyberseallExecutor:find("swift") then
    cyberseallHasPromise = false
end

local cyberseallPossibleNames = { "C_ActivateObject", "S_C_ActivateObject" }
local cyberseallActivateName, cyberseallActivateRemote
for _, name in ipairs(cyberseallPossibleNames) do
    local candidate = cyberseallRemotesRoot2:FindFirstChild(name) or cyberseallRemotesRoot1:FindFirstChild(name)
    if candidate then
        cyberseallActivateName = name
        cyberseallActivateRemote = candidate
        break
    end
end
assert(cyberseallActivateRemote, "No remote named " .. table.concat(cyberseallPossibleNames, ", "))

local cyberseallActivate
if cyberseallHasPromise and cyberseallRemotesRoot2:FindFirstChild(cyberseallActivateName) then
    cyberseallActivate = cyberseallRemotePromiseMod.new(cyberseallActivateName)
else
    if cyberseallActivateRemote:IsA("RemoteFunction") then
        cyberseallActivate = {
            InvokeServer = function(_, ...) return cyberseallActivateRemote:InvokeServer(...) end
        }
    elseif cyberseallActivateRemote:IsA("RemoteEvent") then
        cyberseallActivate = {
            InvokeServer = function(_, ...) cyberseallActivateRemote:FireServer(...) end
        }
    else
        error(cyberseallActivateName .. " is not a valid remote")
    end
end

local cyberseallBondData = {}
local cyberseallSeenKeys = {}

local function cyberseallRecordBonds()
    local runtime = WorkspaceService:WaitForChild("RuntimeItems")
    for _, item in ipairs(runtime:GetChildren()) do
        if item.Name:find("Bond") then
            local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
            if part then
                local key = ("%.1f_%.1f_%.1f"):format(part.Position.X, part.Position.Y, part.Position.Z)
                if not cyberseallSeenKeys[key] then
                    cyberseallSeenKeys[key] = true
                    table.insert(cyberseallBondData, { item = item, pos = part.Position })
                end
            end
        end
    end
end

printnotify("→ Scanning for bonds...")
local cyberseallScanTarget = CFrame.new(-424.448975, 26.055481, -49040.6562)
for i = 1, 50 do
    cyberseallHrp.CFrame = cyberseallHrp.CFrame:Lerp(cyberseallScanTarget, i / 50)
    task.wait(0.25)
    cyberseallRecordBonds()
end
cyberseallHrp.CFrame = cyberseallScanTarget
task.wait(0.3)
cyberseallRecordBonds()

printnotify(("→ %d bonds detected. Preparing collection."):format(#cyberseallBondData))
if #cyberseallBondData == 0 then return wwarn("No bonds detected") end

local cyberseallChair = WorkspaceService:WaitForChild("RuntimeItems"):FindFirstChild("Chair")
local cyberseallSeat = cyberseallChair and cyberseallChair:FindFirstChild("Seat")
assert(cyberseallSeat, "Chair.Seat not found")

cyberseallSeat:Sit(cyberseallHumanoid)
task.wait(0.25)
local cyberseallSeatWorks = (cyberseallHumanoid.SeatPart == cyberseallSeat)

local function collectBond(bond)
    local pos = bond.pos + Vector3.new(0, 2, 0)
    if cyberseallSeatWorks then
        cyberseallSeat:PivotTo(CFrame.new(pos))
        task.wait(0.1)
        if cyberseallHumanoid.SeatPart ~= cyberseallSeat then
            cyberseallSeat:Sit(cyberseallHumanoid)
            task.wait(0.1)
        end
    else
        cyberseallHrp.CFrame = CFrame.new(pos)
        task.wait(0.1)
    end

    local success, err = pcall(function()
        cyberseallActivate:InvokeServer(bond.item)
    end)
    if not success then
        warn("Invoke failed:", err)
    end

    task.wait(0.4)

    if not bond.item.Parent then
        printnotify("✓ Bond collected")
        return true
    else
        wwarn("✗ Bond not collected")
        return false
    end
end

local failedBonds = {}

for i, bond in ipairs(cyberseallBondData) do
    printnotify(("→ Collecting bond %d/%d"):format(i, #cyberseallBondData))
    if not collectBond(bond) then
        table.insert(failedBonds, bond)
    end
end

if #failedBonds > 0 then
    printnotify(("→ Retrying %d failed bond(s)..."):format(#failedBonds))
    local finalFails = {}
    for _, bond in ipairs(failedBonds) do
        if not collectBond(bond) then
            table.insert(finalFails, bond)
        end
    end
    if #finalFails > 0 then
        wwarn(("✗ %d bond(s) still failed after retry."):format(#finalFails))
    else
        printnotify("✓ All bonds collected after retry.")
    end
end

cyberseallHumanoid:TakeDamage(999999)
cyberseallEndDecisionRemote:FireServer(false)
-- added auto play with team
local playbtn = cyberseallPlayer.PlayerGui.EndScreen.EndFrame.BottomFrame.PlayAgainButton
repeat wait() until playbtn cyberseallPlayer.PlayerGui.EndScreen.EndFrame.Visible
local Gs = game:GetService("GuiService")
local Vim = game:GetService("VirtualInputManager")
Gs.SelectedObject = playbtn
wait()
Vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
wait()
Vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
wait()
Gs.SelectedObject = nil

printnotify("→ Script Completed.. wait till server hop..")
cyberseallQueueOnTp(game:HttpGet("https://raw.githubusercontent.com/y-d/lua/refs/heads/main/autobond.lua"))
