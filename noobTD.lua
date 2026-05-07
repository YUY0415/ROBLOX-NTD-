-- [[ Noob TD 稳定版挂机脚本 - 手动 ID 填入 ]] --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Coins = LocalPlayer.leaderstats.Coins
local WaveValue = ReplicatedStorage.Values.Wave

-- ==========================================
-- 【手动填入区】把第一步抓到的 ID 填在这里
-- ==========================================
local ID_Table = {
    ["name"] = "把刚才抓到的ID填到这里",
    ["name"] = "ID填到这里",
}
-- ==========================================

local ActionPlan = {
--这里填录制的操作例如
--钱可能不正确自己修改
--{1, 'Place', '1x1x1x1', 400, Vector3.new(-5.19, 0.05, 7.34)},
--{3, 'Place', '1x1x1x1', 400, Vector3.new(-7.76, 0.05, 7.19)},
}

local currentStep = 1

local function runMacro(wave)
    while currentStep <= #ActionPlan and ActionPlan[currentStep][1] <= wave do
        local taskData = ActionPlan[currentStep]
        local action, name, price, extra = taskData[2], taskData[3], taskData[4], taskData[5]

        -- 钱不够就等
        if price > 0 and Coins.Value < price then
            repeat task.wait(0.5) until Coins.Value >= price
        end

        if action == "Place" then
            local targetID = ID_Table[name]
            if targetID then
                pcall(function()
                    ReplicatedStorage.Remotes.Functions.PlaceTower:InvokeServer({
                        ["towerToPlace"] = name,
                        ["towerID"] = targetID,
                        ["instance"] = workspace.Map.Map.Baseplate.Placeable.Part,
                        ["position"] = extra
                    })
                end)
            end
        elseif action == "Upgrade" then
            pcall(function()
                ReplicatedStorage.Remotes.Functions.UpgradeTower:InvokeServer(tostring(extra))
            end)
        elseif action == "Sell" then
            pcall(function()
                ReplicatedStorage.Remotes.Functions.SellTower:InvokeServer(tostring(extra))
            end)
        end

        currentStep = currentStep + 1
        task.wait(0.2)
    end
end

WaveValue.Changed:Connect(runMacro)

-- 自动跳波可删除
task.spawn(function()
    while task.wait(2) do
        ReplicatedStorage.Remotes.Events.SkipWave:FireServer()
    end
end)

-- 防掉线
LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new(0,0))
end)

runMacro(WaveValue.Value)
warn("--- 手动 ID 挂机脚本已就绪 ---")
