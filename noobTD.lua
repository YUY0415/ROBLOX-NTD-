task.wait(10)
-- [[ Noob TD 挂机脚本]] --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Coins = LocalPlayer.leaderstats.Coins
local WaveValue = ReplicatedStorage.Values.Wave
local GameRunning = ReplicatedStorage.Values.GameRunning

local ID_Table = {}

-- [[ 1. 动态 ID 获取逻辑：直接提取 Tower 字段 ]]
local function RefreshIDTable()
    local success, constants = pcall(function() 
        return require(ReplicatedStorage.Modules.Data.Constants) 
    end)
    
    if success and constants and constants.currentPlrData then
        table.clear(ID_Table)
        local towerData = constants.currentPlrData.Items.Towers
        
        -- 遍历数据表
        for _, v in pairs(towerData) do
            -- 判断 Locked 状态，并直接取 Tower 字段作为名字
            if type(v) == "table" and v.Locked == true then
                local towerName = v.Tower   -- 这里直接取塔的名字
                local realID = v.TowerID or v.ID
                
                if towerName and realID then
                    ID_Table[towerName] = realID
                    print("💎 匹配成功: " .. tostring(towerName) .. " -> " .. tostring(realID))
                end
            end
        end
    else
        warn("⚠️ 无法读取 Constants 数据")
    end
end

-- 启动同步
RefreshIDTable()

-- ==========================================
-- 【ActionPlan 配置区】
-- ==========================================
local ActionPlan = {
    -- 录制数据
}

local SuccessBook = {}

-- [[ 2. 核心引擎：严格顺序逻辑 ]]
local function scanAndFix()
    if not GameRunning.Value then return end
    local currentWave = WaveValue.Value
    
    for i = 1, #ActionPlan do
        local taskData = ActionPlan[i]
        if taskData[1] > currentWave then break end
        
        if not SuccessBook[i] then
            local action, name, price, extra = taskData[2], taskData[3], taskData[4], taskData[5]
            
            if Coins.Value >= price then
                local success = false
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
                        success = true
                    else
                        warn("❌ 未在锁定列表中找到塔: " .. tostring(name))
                        break -- 找不到 ID 必须停止，防止乱序
                    end
                elseif action == "Upgrade" then
                    pcall(function()
                        ReplicatedStorage.Remotes.Functions.UpgradeTower:InvokeServer(tostring(extra))
                    end)
                    success = true
                elseif action == "Sell" then
                    pcall(function()
                        ReplicatedStorage.Remotes.Functions.SellTower:InvokeServer(tostring(extra))
                    end)
                    success = true
                end
                
                if success then
                    SuccessBook[i] = true
                    print("✅ 完成步骤 " .. i)
                    task.wait(0.3)
                end
            else
                -- 钱不够，为了顺序，必须 break
                break 
            end
        end
    end
end

-- [[ 3. 自动化流程控制 ]]
task.spawn(function()
    print("⏳ 脚本启动中...")
    task.wait(10)
    pcall(function() ReplicatedStorage.Remotes.Events.Ready:FireServer() end)
    task.wait(5)
    pcall(function() ReplicatedStorage.Remotes.Events.Gamemode:FireServer("Easy") end)--换成你要的难度
    
    if not GameRunning.Value then GameRunning:GetPropertyChangedSignal("Value"):Wait() end
    task.wait(2) 
    pcall(function() ReplicatedStorage.Remotes.Events.InitChangeSpeed:FireServer(1) end)
    
    while task.wait(1) do
        if GameRunning.Value then scanAndFix() end
    end
end)

-- 结算重置
GameRunning.Changed:Connect(function(isRunning)
    if not isRunning then
        SuccessBook = {}
        RefreshIDTable()
        warn("🏁 游戏结束，进度已重置。")
        task.wait(15)
        pcall(function() ReplicatedStorage.Remotes.Events.Replay:FireServer() end)
    end
end)

-- 防掉线
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController():ClickButton2(Vector2.new(0,0))
end)

warn("🚀 --- 已修正名称读取逻辑，脚本运行中 ---")
